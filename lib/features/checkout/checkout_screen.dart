import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/wedding_project_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessingPayment = false;

  void _processStripePayment(BuildContext context) async {
    setState(() => _isProcessingPayment = true);

    // Simulate Stripe Sandbox authentication and token charge
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isProcessingPayment = false);

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Payment Successful!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your wedding services have been booked via Stripe Sandbox.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slate600,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pinkPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // pop dialog
                    Navigator.of(context).pop(); // return to dashboard
                  },
                  child: const Text(
                    "Back to Dashboard",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(weddingProjectProvider);
    final currencyFormatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    final venueFee = project.venueFee > 0 ? project.venueFee : 4500.00;
    final plannerFee = project.plannerFee > 0 ? project.plannerFee : 800.00;
    final invitationFee = project.invitationFee > 0 ? project.invitationFee : 650.00;
    final cateringFee = project.cateringFee > 0 ? project.cateringFee : 5500.00;

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.slate900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Wedding Project Checkout",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.slate900),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Date Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.pinkLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.pinkBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.pinkPrimary, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Wedding Event Schedule",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.pinkPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$dateStr (${project.weddingTime ?? 'TBD'})",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Selected Services Summary",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate900),
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
                    title: "1. Venue Reservation",
                    subtitle: project.selectedVenueName ?? "Grand Palace Ballroom",
                    price: currencyFormatter.format(venueFee),
                  ),
                  const Divider(height: 24, color: AppColors.slate100),
                  _buildServiceRow(
                    icon: Icons.architecture_rounded,
                    title: "2. 2D Layout Plan Setup",
                    subtitle: project.plannerLayoutSummary ?? "10 Round Tables & Stage",
                    price: currencyFormatter.format(plannerFee),
                  ),
                  const Divider(height: 24, color: AppColors.slate100),
                  _buildServiceRow(
                    icon: Icons.mark_email_unread_rounded,
                    title: "3. Invitation Cards",
                    subtitle: project.selectedInvitationName ?? "Luxury Rose Gold Suite (200 pcs)",
                    price: currencyFormatter.format(invitationFee),
                  ),
                  const Divider(height: 24, color: AppColors.slate100),
                  _buildServiceRow(
                    icon: Icons.cake_rounded,
                    title: "4. F&B Catering Package",
                    subtitle: project.selectedCateringPackage ?? "Royal Wedding Buffet Menu",
                    price: currencyFormatter.format(cateringFee),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stripe Sandbox Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppColors.slate600, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Secured by Stripe Payment Gateway (Sandbox Test Mode)",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Price Breakdown Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Column(
                children: [
                  _buildCostRow("Subtotal", currencyFormatter.format(subtotal)),
                  const SizedBox(height: 8),
                  _buildCostRow("SST / Service Tax (6%)", currencyFormatter.format(serviceTax)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: AppColors.slate100),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Fee",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate900),
                      ),
                      Text(
                        currencyFormatter.format(grandTotal),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.pinkPrimary),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isProcessingPayment ? null : () => _processStripePayment(context),
                child: _isProcessingPayment
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "Pay ${currencyFormatter.format(grandTotal)} via Stripe",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate800),
        ),
      ],
    );
  }

  Widget _buildCostRow(String title, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: AppColors.slate600, fontWeight: FontWeight.w500)),
        Text(amount, style: const TextStyle(fontSize: 14, color: AppColors.slate800, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
