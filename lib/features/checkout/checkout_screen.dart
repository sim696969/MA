import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../models/wedding_project_model.dart';
import '../../services/wedding_project_provider.dart';
import '../../widgets/top_right_toast.dart';

// NOTE: In a production app the secret key must never live in client code.
// For this sandbox/test assignment it is embedded directly.
const _stripeSecretKey =
    'sk_test_51SXBnqAGOuxJcOdiKftzdJcKwC7DqFEMWi2KJEUdovdmr3KSX0rAZUnom481hJGtidghfSR18kZ4E24jHB8Tnuuy00AChAKPnI';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessingPayment = false;
  CardEditController? _cardEditController;
  bool _isCardComplete = false;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _cardEditController = CardEditController();
    }
  }

  @override
  void dispose() {
    _cardEditController?.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvcController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  bool _validateWebCardDetails() {
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final expiry = _expiryDateController.text.trim();
    final cvc = _cvcController.text.trim();
    final postal = _postalCodeController.text.trim();

    if (cardNumber.length < 13 || cardNumber.length > 19) return false;
    if (!RegExp(r'^\d{2}\/\d{2}$').hasMatch(expiry)) return false;
    if (cvc.length < 3 || cvc.length > 4) return false;
    if (postal.isEmpty) return false;

    final parts = expiry.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    if (month < 1 || month > 12) return false;

    return true;
  }

  String _formatCardNumber(String input) {
    input = input.replaceAll(' ', '');
    if (input.length > 16) input = input.substring(0, 16);
    String formatted = '';
    for (int i = 0; i < input.length; i++) {
      if (i % 4 == 0 && i > 0) formatted += ' ';
      formatted += input[i];
    }
    return formatted;
  }

  String _formatExpiryDate(String input) {
    input = input.replaceAll('/', '');
    if (input.length > 4) input = input.substring(0, 4);
    if (input.length >= 3) {
      return '${input.substring(0, 2)}/${input.substring(2)}';
    }
    return input;
  }

  // ── 1. Create PaymentIntent via direct HTTP POST to Stripe API ─────────────
  /// [amountMyr] is the MYR total (e.g. 11930.00).
  /// Stripe requires the smallest currency unit (sen), so we × 100.
  Future<Map<String, String>> _createPaymentIntent(double amountMyr) async {
    final amountSen = (amountMyr * 100).round().toString();

    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amountSen,
        'currency': 'myr',
        'payment_method_types[]': 'card',
        'description': 'Wedify – Wedding Project Booking',
      },
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        err['error']?['message'] ?? 'Failed to create PaymentIntent',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'client_secret': data['client_secret'] as String,
      'id':
          data['id'] as String? ??
          'pi_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // ── 2. Process payment using manual CardField entry ─────────────────────────
  Future<void> _processStripePayment(
    double amountToCharge, {
    required bool isBalancePayment,
  }) async {
    if (kIsWeb) {
      if (!_validateWebCardDetails()) {
        _showErrorSnackbar('Please fill in complete and valid card details.');
        return;
      }
    } else {
      if (!_isCardComplete) {
        _showErrorSnackbar('Please fill in complete and valid card details.');
        return;
      }
    }

    setState(() => _isProcessingPayment = true);

    try {
      // A – Create PaymentIntent
      final intentData = await _createPaymentIntent(amountToCharge);
      final clientSecret = intentData['client_secret']!;
      final transactionId = intentData['id']!;

      // B – Confirm Payment via manual CardField on Mobile
      if (!kIsWeb) {
        await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
          data: const PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(),
          ),
        );
      } else {
        // Web flow simulation
        await Future.delayed(const Duration(milliseconds: 1200));
      }

      // C – Immediately update Firebase Firestore to paymentStatus: 'paid'
      await ref
          .read(weddingProjectProvider.notifier)
          .markAsPaid(
            transactionId: transactionId,
            amountPaid: (isBalancePayment
                ? ref.read(weddingProjectProvider).amountPaid + amountToCharge
                : amountToCharge),
            paymentDate: DateTime.now(),
          );

      // D – Clear all sensitive card input data immediately after successful payment
      if (mounted) {
        _clearAllCardInputs();
        _showSuccessDialog();
      }
    } on StripeException catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          e.error.localizedMessage ??
              'Payment processing was canceled or failed.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Payment error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  // ── 3. Success Dialog (B&W) ────────────────────────────────────────────────
  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 32,
          horizontal: 24,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Payment Successful!',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your wedding project has been confirmed and booked via Stripe.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Container(height: 1.5, color: Colors.black),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'View Order Summary',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Error Snackbar ──────────────────────────────────────────────────────
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.white24),
        ),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasCardInput() {
    return _cardNumberController.text.isNotEmpty ||
        _expiryDateController.text.isNotEmpty ||
        _cvcController.text.isNotEmpty ||
        _postalCodeController.text.isNotEmpty ||
        _isCardComplete;
  }

  void _clearAllCardInputs() {
    _cardNumberController.clear();
    _expiryDateController.clear();
    _cvcController.clear();
    _postalCodeController.clear();
    _cardEditController?.clear();
    setState(() {
      _isCardComplete = false;
    });
  }

  Future<void> _handleBackNavigation() async {
    final isPaid = ref.read(weddingProjectProvider).isPaid;
    if (isPaid) {
      _clearAllCardInputs();
      Navigator.pop(context);
      return;
    }

    if (_hasCardInput()) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Leave Checkout?',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: Text(
            'You have entered card details that will not be saved. Are you sure you want to leave the checkout page?',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black87,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              style: TextButton.styleFrom(foregroundColor: Colors.black54),
              child: Text(
                'Stay',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Leave',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldLeave == true && mounted) {
        _clearAllCardInputs();
        Navigator.pop(context);
      }
    } else {
      _clearAllCardInputs();
      Navigator.pop(context);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final project = ref.watch(weddingProjectProvider);
    final fmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    final venueFee = project.venueFee > 0 ? project.venueFee : 4500.00;
    final plannerFee = project.plannerFee > 0 ? project.plannerFee : 800.00;
    final invitationFee = project.invitationFee > 0
        ? project.invitationFee
        : 650.00;
    final cateringFee = project.cateringFee > 0 ? project.cateringFee : 5500.00;

    final subtotal = venueFee + plannerFee + invitationFee + cateringFee;
    final serviceTax = subtotal * 0.06;
    final grandTotal = subtotal + serviceTax;
    final isBalancePayment = project.amountPaid > 0 && project.balanceDue > 0;
    final amountToCharge = isBalancePayment ? project.balanceDue : grandTotal;

    final dateStr = project.weddingDate != null
        ? DateFormat('EEEE, dd MMMM yyyy').format(project.weddingDate!)
        : 'Not set';

    final isPaid = project.isPaid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: _handleBackNavigation,
        ),
        title: Text(
          isPaid ? 'Booking Confirmation' : 'Wedding Project Checkout',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: Colors.black, height: 1.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── A. If Paid: Permanent Order Confirmation Summary ────────────
            if (isPaid) ...[
              _buildConfirmedOrderSummary(project, fmt, grandTotal, dateStr),
              const SizedBox(height: 24),
            ],

            // ── B. If Not Paid: Schedule, Services, Cost Breakdown & Card Form ──
            if (!isPaid) ...[
              if (isBalancePayment) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE7E7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5989B)),
                  ),
                  child: const Text(
                    'Payment Incomplete: You updated your booking! Please complete the remaining balance payment to confirm your changes.',
                    style: TextStyle(
                      color: Color(0xFF161B22),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Wedding Date Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WEDDING EVENT SCHEDULE',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$dateStr (${project.weddingTime ?? 'TBD'})',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Selected Services Summary',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Services Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Column(
                  children: [
                    _buildServiceRow(
                      icon: Icons.apartment_rounded,
                      title: '1. Venue Reservation',
                      subtitle:
                          project.selectedVenueName ?? 'Grand Palace Ballroom',
                      price: fmt.format(venueFee),
                    ),
                    const Divider(height: 24, color: Colors.black12),
                    _buildServiceRow(
                      icon: Icons.architecture_rounded,
                      title: '2. 2D Layout Plan Setup',
                      subtitle:
                          project.plannerLayoutSummary ??
                          '10 Round Tables & Stage',
                      price: fmt.format(plannerFee),
                    ),
                    const Divider(height: 24, color: Colors.black12),
                    _buildServiceRow(
                      icon: Icons.mark_email_unread_rounded,
                      title: '3. Invitation Cards',
                      subtitle:
                          project.selectedInvitationName ??
                          'Luxury Rose Gold Suite (200 pcs)',
                      price: fmt.format(invitationFee),
                    ),
                    const Divider(height: 24, color: Colors.black12),
                    _buildServiceRow(
                      icon: Icons.cake_rounded,
                      title: '4. F&B Catering Package',
                      subtitle:
                          project.selectedCateringPackage ??
                          'Royal Wedding Buffet Menu',
                      price: fmt.format(cateringFee),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Price Breakdown
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Column(
                  children: [
                    _buildCostRow('Subtotal', fmt.format(subtotal)),
                    const SizedBox(height: 8),
                    _buildCostRow(
                      'SST / Service Tax (6%)',
                      fmt.format(serviceTax),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Colors.black, thickness: 1.2),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          fmt.format(grandTotal),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Custom Manual Card Entry Container ────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.credit_card_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Payment Information',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Secure payment via Stripe. Your payment information is encrypted and never stored on our servers.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (kIsWeb)
                      _buildWebCardForm()
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: CardField(
                          controller: _cardEditController,
                          enablePostalCode: true,
                          cursorColor: Colors.black,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                            hintText: 'Card Number',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            labelStyle: GoogleFonts.inter(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          onCardChanged: (card) {
                            setState(() {
                              _isCardComplete = card?.complete ?? false;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              if (isBalancePayment) ...[
                _buildCostRow('Previously Paid', fmt.format(project.amountPaid)),
                const SizedBox(height: 6),
                _buildCostRow('New Total', fmt.format(grandTotal)),
                const SizedBox(height: 6),
                _buildCostRow('Balance Due', fmt.format(amountToCharge)),
                const SizedBox(height: 20),
              ],

              // Pay Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isProcessingPayment
                      ? null
                      : () => _processStripePayment(
                          amountToCharge,
                          isBalancePayment: isBalancePayment,
                        ),
                  child: _isProcessingPayment
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Processing Payment...',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isBalancePayment
                                    ? 'Pay Balance (${fmt.format(amountToCharge)})'
                                    : 'Pay ${fmt.format(grandTotal)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  // ── Confirmed Order Summary Widget (Rendered when isPaid == true) ───────────
  Widget _buildConfirmedOrderSummary(
    WeddingProject project,
    NumberFormat fmt,
    double grandTotal,
    String dateStr,
  ) {
    final paymentDateFormatted = project.paymentDate != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(project.paymentDate!)
        : DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAYMENT COMPLETED',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Your wedding services are confirmed & booked.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.black, thickness: 1.5),
          const SizedBox(height: 16),

          // Transaction & Payment Details
          _buildReceiptRow(
            'Transaction ID',
            project.transactionId ??
                'pi_confirmed_${DateTime.now().millisecondsSinceEpoch}',
          ),
          const SizedBox(height: 8),
          _buildReceiptRow('Payment Date', paymentDateFormatted),
          const SizedBox(height: 8),
          _buildReceiptRow(
            'Amount Paid',
            fmt.format(
              project.amountPaid > 0 ? project.amountPaid : grandTotal,
            ),
          ),
          const SizedBox(height: 8),
          _buildReceiptRow('Payment Method', 'Credit / Debit Card (Stripe)'),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12, thickness: 1),
          const SizedBox(height: 16),

          // Wedding Schedule & Location
          Text(
            'EVENT DETAILS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          _buildReceiptRow('Wedding Date', dateStr),
          const SizedBox(height: 6),
          _buildReceiptRow('Event Time', project.weddingTime ?? 'TBD'),
          const SizedBox(height: 6),
          _buildReceiptRow(
            'Venue / Place',
            project.selectedVenueName ?? 'Grand Palace Ballroom',
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12, thickness: 1),
          const SizedBox(height: 16),

          // Booked Services & Catering
          Text(
            'BOOKED SERVICES',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          _buildReceiptRow(
            'Venue',
            project.selectedVenueName ?? 'Grand Palace Ballroom',
          ),
          const SizedBox(height: 6),
          _buildReceiptRow(
            '2D Layout',
            project.plannerLayoutSummary ?? 'Custom Seating & Stage Layout',
          ),
          const SizedBox(height: 6),
          _buildReceiptRow(
            'Invitations',
            project.selectedInvitationName ?? 'Digital & Printed Suite',
          ),
          const SizedBox(height: 6),
          _buildReceiptRow(
            'F&B Catering',
            project.selectedCateringPackage ?? 'Itemized Banquet Menu',
          ),
          const SizedBox(height: 24),

          // Back to Dashboard Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                _clearAllCardInputs();
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: Colors.black,
              ),
              label: Text(
                'Back to Dashboard',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            maxLength: 19,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: 'Card Number',
              labelStyle: GoogleFonts.inter(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              hintText: '1234 5678 9012 3456',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade500, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade500, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
              counterText: '',
              prefixIcon: Icon(
                Icons.credit_card,
                size: 20,
                color: Colors.grey.shade700,
              ),
            ),
            onChanged: (value) {
              final formatted = _formatCardNumber(value);
              if (formatted != value) {
                _cardNumberController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryDateController,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'MM/YY',
                    labelStyle: GoogleFonts.inter(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: '12/28',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade500,
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade500,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                    counterText: '',
                  ),
                  onChanged: (value) {
                    final formatted = _formatExpiryDate(value);
                    if (formatted != value) {
                      _expiryDateController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _cvcController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'CVC',
                    labelStyle: GoogleFonts.inter(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: '123',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade500,
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade500,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _postalCodeController,
            keyboardType: TextInputType.text,
            maxLength: 10,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: 'Postal Code',
              labelStyle: GoogleFonts.inter(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              hintText: '50000',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade500, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade500, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
              counterText: '',
              prefixIcon: Icon(
                Icons.location_on_outlined,
                size: 20,
                color: Colors.grey.shade700,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _buildServiceRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 1.2),
          ),
          child: Icon(icon, color: Colors.black, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String title, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amount,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
