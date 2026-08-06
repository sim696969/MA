import 'package:flutter/material.dart';
import '../../widgets/wedify_card.dart';
import '../../widgets/wedify_button.dart';
import 'catering_selector_screen.dart';

class CheckoutScreen extends StatelessWidget {
  final CateringMenu menu;

  const CheckoutScreen({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order Summary", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            WedifyCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(menu.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text("10 Tables x RM ${menu.price.toStringAsFixed(2)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text("RM ${(menu.price * 10).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text("Delivery Address", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            WedifyCard(
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Grand Hyatt Kuala Lumpur", style: TextStyle(fontWeight: FontWeight.w500)),
                        Text("12, Jalan Pinang, Kuala Lumpur, 50450", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text("Edit")),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text("Payment Method", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            WedifyCard(
              child: Column(
                children: [
                  _buildPaymentOption(context, "ToyyibPay (FPX / Cards)", Icons.account_balance, true),
                  const Divider(),
                  _buildPaymentOption(context, "Credit / Debit Card", Icons.credit_card, false),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Amount", style: TextStyle(fontSize: 16)),
                Text("RM ${(menu.price * 10).toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: WedifyButton(
                text: "PAY NOW (SANDBOX)",
                onPressed: () => _processPayment(context),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                "// TODO: Insert ToyyibPay API keys here\n// TOYYIBPAY_SECRET_KEY, TOYYIBPAY_CATEGORY_CODE",
                style: TextStyle(color: Colors.grey, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context, String title, IconData icon, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
          Radio(value: selected, groupValue: true, onChanged: (v) {}),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Dismiss loading
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text("Payment Successful!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 8),
              const Text("Your catering order has been confirmed.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: WedifyButton(
                  text: "BACK TO HOME",
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
