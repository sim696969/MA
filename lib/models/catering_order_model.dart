import 'package:cloud_firestore/cloud_firestore.dart';

/// Individual catering food item available for order.
class CateringItem {
  final String id;
  final String name;
  final String category; // 'Chinese Cuisine' or 'Western Food'
  final String description;
  final double unitPrice;
  final String unit; // e.g. 'portion', 'pax', 'serving', 'plate'
  final String imageUrl;

  const CateringItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.unitPrice,
    this.unit = 'portion',
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'unitPrice': unitPrice,
      'unit': unit,
      'imageUrl': imageUrl,
    };
  }

  factory CateringItem.fromMap(Map<String, dynamic> map) {
    return CateringItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'portion',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}

/// Model representing a confirmed catering order stored in Firestore.
class CateringOrderModel {
  final String orderId;
  final String category;
  final List<Map<String, dynamic>> items;
  final String additionalNotes;
  final double totalAmount;
  final DateTime createdAt;

  const CateringOrderModel({
    required this.orderId,
    required this.category,
    required this.items,
    required this.additionalNotes,
    required this.totalAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'category': category,
      'items': items,
      'additionalNotes': additionalNotes,
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CateringOrderModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parsedDate;
    final rawDate = map['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return CateringOrderModel(
      orderId: map['orderId'] ?? docId ?? '',
      category: map['category'] ?? 'Mixed Cuisine',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => Map<String, dynamic>.from(item as Map))
              .toList() ??
          [],
      additionalNotes: map['additionalNotes'] ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: parsedDate,
    );
  }
}
