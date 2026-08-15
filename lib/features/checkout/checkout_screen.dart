import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/wedding_project_provider.dart';

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

  // ── 1. Create PaymentIntent via direct HTTP POST to Stripe API ─────────────
  /// [amountMyr] is the MYR total (e.g. 11930.00).
  /// Stripe requires the smallest currency unit (sen), so we × 100.
  Future<String> _createPaymentIntent(double amountMyr) async {
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
          err['error']?['message'] ?? 'Failed to create PaymentIntent');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['client_secret'] as String;
  }

  // ── 2. Full payment flow: intent → sheet init → present ───────────────────
  Future<void> _processStripePayment(double grandTotal) async {
    setState(() => _isProcessingPayment = true);

    try {
      // A – Create PaymentIntent
      final clientSecret = await _createPaymentIntent(grandTotal);

      // B – Init Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Wedify',
          style: ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              background: Colors.white,
              primary: Colors.black,
              componentBackground: const Color(0xFFF8F8F8),
            ),
            shapes: PaymentSheetShape(
              borderRadius: 12,
              borderWidth: 1.5,
            ),
          ),
        ),
      );

      // C – Present to user
      await Stripe.instance.presentPaymentSheet();

      if (mounted) _showSuccessDialog();
    } on StripeException catch (e) {
      if (mounted) {
        _showErrorSnackbar(
            e.error.localizedMessage ?? 'Payment was canceled.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('An error occurred: ${e.toString()}');
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 40),
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
                  fontSize: 13, color: Colors.black54, height: 1.5),
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
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Back to Dashboard',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.white),
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
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final project = ref.watch(weddingProjectProvider);
    final fmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    final venueFee = project.venueFee > 0 ? project.venueFee : 4500.00;
    final plannerFee = project.plannerFee > 0 ? project.plannerFee : 800.00;
    final invitationFee =
        project.invitationFee > 0 ? project.invitationFee : 650.00;
    final cateringFee =
        project.cateringFee > 0 ? project.cateringFee : 5500.00;

    final subtotal = venueFee + plannerFee + invitationFee + cateringFee;
    final serviceTax = subtotal * 0.06;
    final grandTotal = subtotal + serviceTax;

    final dateStr = project.weddingDate != null
        ? DateFormat('EEEE, dd MMMM yyyy').format(project.weddingDate!)
        : 'Not set';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.slate900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Wedding Project Checkout',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wedding Date Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.pinkLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.pinkBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppColors.pinkPrimary, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wedding Event Schedule',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.pinkPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dateStr (${project.weddingTime ?? 'TBD'})',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Selected Services Summary',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900),
            ),
            const SizedBox(height: 12),

            // Services Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                  const Divider(height: 24, color: AppColors.slate100),
                  _buildServiceRow(
                    icon: Icons.architecture_rounded,
                    title: '2. 2D Layout Plan Setup',
                    subtitle:
                        project.plannerLayoutSummary ?? '10 Round Tables & Stage',
                    price: fmt.format(plannerFee),
                  ),
                  const Divider(height: 24, color: AppColors.slate100),
                  _buildServiceRow(
                    icon: Icons.mark_email_unread_rounded,
                    title: '3. Invitation Cards',
                    subtitle: project.selectedInvitationName ??
                        'Luxury Rose Gold Suite (200 pcs)',
                    price: fmt.format(invitationFee),
                  ),
                  const Divider(height: 24, color: AppColors.slate100),
                  _buildServiceRow(
                    icon: Icons.cake_rounded,
                    title: '4. F&B Catering Package',
                    subtitle: project.selectedCateringPackage ??
                        'Royal Wedding Buffet Menu',
                    price: fmt.format(cateringFee),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stripe Security Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded,
                      color: AppColors.slate600, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Secured by Stripe Payment Gateway',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Price Breakdown
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Column(
                children: [
                  _buildCostRow('Subtotal', fmt.format(subtotal)),
                  const SizedBox(height: 8),
                  _buildCostRow(
                      'SST / Service Tax (6%)', fmt.format(serviceTax)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: AppColors.slate100),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Fee',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900),
                      ),
                      Text(
                        fmt.format(grandTotal),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.pinkPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pinkPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isProcessingPayment
                    ? null
                    : () => _processStripePayment(grandTotal),
                child: _isProcessingPayment
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Processing...',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Pay ${fmt.format(grandTotal)} via Stripe',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // Test card hint
            Center(
              child: Text(
                '🔒 Test mode — use card 4242 4242 4242 4242',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.slate500,
                    fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
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
            color: AppColors.pinkLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.pinkPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.slate500)),
            ],
          ),
        ),
        Text(price,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.slate800)),
      ],
    );
  }

  Widget _buildCostRow(String title, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.slate600,
                fontWeight: FontWeight.w500)),
        Text(amount,
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.slate800,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
