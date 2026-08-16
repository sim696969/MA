import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/catering_order_model.dart';
import '../../models/wedding_project_model.dart';
import '../../services/catering_cart_provider.dart';
import '../../services/database_service.dart';
import '../../services/wedding_project_provider.dart';
import '../../widgets/top_right_toast.dart';

class CateringCheckoutScreen extends ConsumerStatefulWidget {
  const CateringCheckoutScreen({super.key});

  @override
  ConsumerState<CateringCheckoutScreen> createState() =>
      _CateringCheckoutScreenState();
}

class _CateringCheckoutScreenState
    extends ConsumerState<CateringCheckoutScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _showPaymentModificationNotice(
    PaymentModificationResult result,
  ) async {
    if (result.type == PaymentModificationType.refundDue) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black),
          ),
          title: const Text('Booking Updated - Refund Notice'),
          content: Text(
            'Your updated total is lower than your previously paid amount. Your payment status remains COMPLETE. Our team will contact you via email regarding your refund process for the price difference of RM ${result.amount.toStringAsFixed(2)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (result.type == PaymentModificationType.balanceDue) {
      context.showTopRightWarning(
        'Payment incomplete. RM ${result.amount.toStringAsFixed(2)} is due.',
      );
    } else if (result.type == PaymentModificationType.unchanged) {
      context.showTopRightSuccess('Booking details updated successfully.');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndPlaceOrder() async {
    final cartNotifier = ref.read(cateringCartProvider.notifier);
    final orderedItems = cartNotifier.getOrderedItemsList();
    final totalAmount = cartNotifier.calculateTotal();

    if (orderedItems.isEmpty) {
      context.showTopRightWarning(
        "Your cart is empty — add some items before checking out.",
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final projectId = ref
        .read(weddingProjectProvider.notifier)
        .firestoreProjectDocId;
    final orderId = "order_${DateTime.now().millisecondsSinceEpoch}";

    // Determine primary category description
    final categories = orderedItems
        .map((e) => e['category'] as String)
        .toSet()
        .toList();
    final categorySummary = categories.join(' & ');

    final newOrder = CateringOrderModel(
      orderId: orderId,
      category: categorySummary,
      items: orderedItems,
      additionalNotes: _notesController.text.trim(),
      totalAmount: totalAmount,
      createdAt: DateTime.now(),
    );

    try {
      // 1. Save order to Firestore
      await _dbService.saveCateringOrder(projectId: projectId, order: newOrder);

      // 2. Update Wedding Project catering completion status & fee
      final summary = "${orderedItems.length} items ($categorySummary)";
      final paymentResult = await ref
          .read(weddingProjectProvider.notifier)
          .updateCatering(
            cateringPackage: summary,
            fee: totalAmount,
            isCompleted: true,
          );

      if (mounted) await _showPaymentModificationNotice(paymentResult);

      // 3. Clear cart
      cartNotifier.clearCart();

      if (mounted) {
        // Show Success Confirmation Modal
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "ORDER CONFIRMED",
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your catering menu order has been successfully saved to Firestore!",
                  style: GoogleFonts.inter(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ORDER ID: $orderId",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Total Amount: RM ${totalAmount.toStringAsFixed(2)}",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  final project = ref.read(weddingProjectProvider);
                  final result = <String, dynamic>{
                    'cateringPackage':
                        project.selectedCateringPackage ?? "Selected Package",
                    'fee': project.cateringFee > 0
                        ? project.cateringFee
                        : totalAmount,
                  };
                  Navigator.of(
                    context,
                  ).pop(result); // Pop CateringCheckoutScreen with result
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "RETURN TO DASHBOARD",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showTopRightError("Error placing catering order: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartNotifier = ref.watch(cateringCartProvider.notifier);
    final orderedItems = cartNotifier.getOrderedItemsList();
    final totalAmount = cartNotifier.calculateTotal();
    final project = ref.watch(weddingProjectProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: Colors.black, height: 1.5),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "CATERING CHECKOUT",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Order Summary
              _buildSectionHeader("ORDER SUMMARY", Icons.receipt_long_outlined),
              const SizedBox(height: 12),
              _buildOrderSummaryCard(orderedItems),
              const SizedBox(height: 24),

              // Section 2: Event / Venue Details
              _buildSectionHeader(
                "EVENT LOCATION & SCHEDULE",
                Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              _buildEventDetailsCard(project),
              const SizedBox(height: 24),

              // Section 3: Additional Notes / Special Notices
              _buildSectionHeader(
                "ADDITIONAL INFORMATION / SPECIAL NOTICES",
                Icons.edit_note,
              ),
              const SizedBox(height: 12),
              _buildSpecialNoticesInput(),
              const SizedBox(height: 24),

              // Section 4: Total & Payment Breakdown
              _buildPaymentBreakdownCard(totalAmount),
              const SizedBox(height: 24),

              // Section 5: Confirm & Place Order Button
              _buildConfirmOrderButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No items selected in cart.",
                  style: GoogleFonts.inter(color: Colors.black54),
                ),
              ),
            )
          : Column(
              children: [
                ...items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quantity Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${item['quantity']}x",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Item Name & Category
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                "${item['category']} • RM ${(item['unitPrice'] as double).toStringAsFixed(2)} / ${item['unit']}",
                                style: GoogleFonts.inter(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Subtotal
                        Text(
                          "RM ${(item['subtotal'] as double).toStringAsFixed(2)}",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(color: Colors.black26, thickness: 1),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ITEMS SUBTOTAL",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      "RM ${ref.read(cateringCartProvider.notifier).calculateTotal().toStringAsFixed(2)}",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildEventDetailsCard(WeddingProject project) {
    final venueName = project.selectedVenueName?.isNotEmpty == true
        ? project.selectedVenueName!
        : "Grand Hyatt Kuala Lumpur, Grand Ballroom";
    final dateStr = project.weddingDate != null
        ? "${project.weddingDate!.day}/${project.weddingDate!.month}/${project.weddingDate!.year}"
        : "12 December 2026";
    final timeStr = project.weddingTime ?? "5:00 PM";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.business_outlined,
                size: 16,
                color: Colors.black,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  venueName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 16,
                color: Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                "$dateStr • Banquet Setup at $timeStr",
                style: GoogleFonts.inter(color: Colors.black87, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialNoticesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText:
                "Enter dietary requirements, allergy warnings (e.g., 'No peanuts / shellfish'), serving timeline, or delivery notes...",
            hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 2.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBreakdownCard(double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Service & Chef Setup Fee",
                style: GoogleFonts.inter(color: Colors.black87, fontSize: 13),
              ),
              Text(
                "INCLUDED",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SST / Service Tax",
                style: GoogleFonts.inter(color: Colors.black87, fontSize: 13),
              ),
              Text(
                "WAIVED",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black, thickness: 1.5),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TOTAL ESTIMATED COST",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.8,
                  color: Colors.black,
                ),
              ),
              Text(
                "RM ${totalAmount.toStringAsFixed(2)}",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmOrderButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _confirmAndPlaceOrder,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(
                Icons.cloud_done_outlined,
                color: Colors.white,
                size: 20,
              ),
        label: Text(
          _isSubmitting ? "SAVING ORDER..." : "CONFIRM & PLACE ORDER",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
