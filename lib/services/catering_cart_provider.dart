import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/catering_order_model.dart';

/// Preset catering items catalog
const List<CateringItem> kAllCateringMenuItems = [
  // ── Chinese Cuisine ──
  CateringItem(
    id: "cn_1",
    name: "Traditional Dim Sum Platter",
    category: "Chinese Cuisine",
    description: "Handcrafted Har Gow (shrimp dumplings), Siu Mai, and BBQ buns.",
    unitPrice: 28.00,
    unit: "pax",
    imageUrl: "https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=800&q=80",
  ),
  CateringItem(
    id: "cn_2",
    name: "Crispy Peking Roasted Duck",
    category: "Chinese Cuisine",
    description: "Carved roasted duck served with steamed lotus wraps, scallions & hoisin glaze.",
    unitPrice: 120.00,
    unit: "whole",
    imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80",
  ),
  CateringItem(
    id: "cn_3",
    name: "Braised E-Fu Longevity Noodles",
    category: "Chinese Cuisine",
    description: "Wok-tossed longevity noodles with wild shiitake mushrooms and chives.",
    unitPrice: 18.00,
    unit: "portion",
    imageUrl: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80",
  ),
  CateringItem(
    id: "cn_4",
    name: "Steamed Dragon Tiger Grouper",
    category: "Chinese Cuisine",
    description: "Fresh ocean grouper steamed in superior soy sauce and ginger threads.",
    unitPrice: 95.00,
    unit: "fish",
    imageUrl: "https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=800&q=80",
  ),
  CateringItem(
    id: "cn_5",
    name: "Double-Boiled Imperial Bird's Nest",
    category: "Chinese Cuisine",
    description: "Premium nourishing warm sweet dessert soup with red dates and wolfberries.",
    unitPrice: 45.00,
    unit: "bowl",
    imageUrl: "https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=800&q=80",
  ),

  // ── Western Food ──
  CateringItem(
    id: "ws_1",
    name: "Gourmet Wagyu Beef Burger",
    category: "Western Food",
    description: "Grilled Australian Wagyu patty, aged cheddar, caramelised onion & brioche bun.",
    unitPrice: 38.00,
    unit: "burger",
    imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80",
  ),
  CateringItem(
    id: "ws_2",
    name: "Truffle Parmesan Hand-Cut Fries",
    category: "Western Food",
    description: "Crispy golden potato fries infused with black truffle oil and grated grana padano.",
    unitPrice: 16.00,
    unit: "bucket",
    imageUrl: "https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=800&q=80",
  ),
  CateringItem(
    id: "ws_3",
    name: "Chargrilled Angus Ribeye Steak",
    category: "Western Food",
    description: "250g Prime Black Angus ribeye with roasted garlic mash and green peppercorn jus.",
    unitPrice: 88.00,
    unit: "portion",
    imageUrl: "https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=800&q=80",
  ),
  CateringItem(
    id: "ws_4",
    name: "Pan-Seared Atlantic Salmon Fillet",
    category: "Western Food",
    description: "Crispy-skinned salmon fillet with asparagus spears and lemon butter cream sauce.",
    unitPrice: 58.00,
    unit: "portion",
    imageUrl: "https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=800&q=80",
  ),
  CateringItem(
    id: "ws_5",
    name: "Belgian Molten Chocolate Lava Cake",
    category: "Western Food",
    description: "Rich 70% dark chocolate fondant served warm with vanilla bean gelato.",
    unitPrice: 22.00,
    unit: "piece",
    imageUrl: "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=800&q=80",
  ),
];

/// StateNotifier to manage item quantities in the catering cart
class CateringCartNotifier extends StateNotifier<Map<String, int>> {
  CateringCartNotifier() : super({});

  void setQuantity(String itemId, int quantity) {
    final sanitizedQty = quantity < 0 ? 0 : quantity;
    if (sanitizedQty == 0) {
      final updated = Map<String, int>.from(state);
      updated.remove(itemId);
      state = updated;
    } else {
      state = {
        ...state,
        itemId: sanitizedQty,
      };
    }
  }

  void increment(String itemId) {
    final current = state[itemId] ?? 0;
    setQuantity(itemId, current + 1);
  }

  void decrement(String itemId) {
    final current = state[itemId] ?? 0;
    if (current > 0) {
      setQuantity(itemId, current - 1);
    }
  }

  void removeItem(String itemId) {
    if (state.containsKey(itemId)) {
      final updated = Map<String, int>.from(state);
      updated.remove(itemId);
      state = updated;
    }
  }

  void loadExistingOrder(List<Map<String, dynamic>> items) {
    final Map<String, int> loadedMap = {};
    for (final item in items) {
      final id = item['id'] as String? ?? '';
      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
      if (id.isNotEmpty && qty > 0) {
        loadedMap[id] = qty;
      }
    }
    state = loadedMap;
  }

  void clearCart() {
    state = {};
  }

  int getQuantity(String itemId) {
    return state[itemId] ?? 0;
  }

  double calculateTotal() {
    double total = 0.0;
    for (final entry in state.entries) {
      final item = kAllCateringMenuItems.firstWhere(
        (i) => i.id == entry.key,
        orElse: () => const CateringItem(
          id: '',
          name: '',
          category: '',
          description: '',
          unitPrice: 0.0,
          imageUrl: '',
        ),
      );
      total += item.unitPrice * entry.value;
    }
    return total;
  }

  int get totalItemsCount {
    int total = 0;
    for (final count in state.values) {
      total += count;
    }
    return total;
  }

  List<Map<String, dynamic>> getOrderedItemsList() {
    final List<Map<String, dynamic>> list = [];
    for (final entry in state.entries) {
      if (entry.value <= 0) continue;
      final item = kAllCateringMenuItems.firstWhere((i) => i.id == entry.key);
      list.add({
        'id': item.id,
        'name': item.name,
        'category': item.category,
        'unitPrice': item.unitPrice,
        'quantity': entry.value,
        'unit': item.unit,
        'subtotal': item.unitPrice * entry.value,
      });
    }
    return list;
  }
}

final cateringCartProvider =
    StateNotifierProvider<CateringCartNotifier, Map<String, int>>((ref) {
  return CateringCartNotifier();
});
