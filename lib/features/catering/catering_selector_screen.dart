import 'package:flutter/material.dart';
import '../../widgets/wedify_card.dart';
import '../../widgets/wedify_button.dart';
import 'checkout_screen.dart';

class CateringSelectorScreen extends StatefulWidget {
  const CateringSelectorScreen({super.key});

  @override
  State<CateringSelectorScreen> createState() => _CateringSelectorScreenState();
}

class _CateringSelectorScreenState extends State<CateringSelectorScreen> {
  final List<CateringMenu> _menus = [
    CateringMenu(
      name: "Traditional Chinese Banquet",
      description: "8-Course Premium Menu including Roasted Duck and Steamed Fish.",
      price: 1888.00,
      imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80",
    ),
    CateringMenu(
      name: "Modern Western Fusion",
      description: "Gourmet 4-Course Menu with Ribeye Steak and Sea Bass.",
      price: 2288.00,
      imageUrl: "https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=800&q=80",
    ),
  ];

  CateringMenu? _selectedMenu;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("F&B Catering")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _menus.length,
              itemBuilder: (context, index) {
                final menu = _menus[index];
                final isSelected = _selectedMenu == menu;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: WedifyCard(
                    padding: EdgeInsets.zero,
                    onTap: () => setState(() => _selectedMenu = menu),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                image: DecorationImage(image: NetworkImage(menu.imageUrl), fit: BoxFit.cover),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 4),
                                  Text(menu.description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  const SizedBox(height: 12),
                                  Text("RM ${menu.price.toStringAsFixed(2)} / table", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              radius: 12,
                              child: const Icon(Icons.check, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: WedifyButton(
                text: "PROCEED TO CHECKOUT",
                onPressed: _selectedMenu == null ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CheckoutScreen(menu: _selectedMenu!)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CateringMenu {
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  CateringMenu({required this.name, required this.description, required this.price, required this.imageUrl});
}
