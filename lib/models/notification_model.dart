import 'package:cloud_firestore/cloud_firestore.dart';

/// A project-scoped alert shown in the Wedify notification center.
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final bool isExpired;
  final String targetRoute;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.isExpired = false,
    required this.targetRoute,
  });

  NotificationModel copyWith({bool? isRead, bool? isExpired}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      isExpired: isExpired ?? this.isExpired,
      targetRoute: targetRoute,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
        'isExpired': isExpired,
        'targetRoute': targetRoute,
      };

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];
    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : rawCreatedAt is String
            ? DateTime.tryParse(rawCreatedAt) ?? DateTime.now()
            : DateTime.now();
    return NotificationModel(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt: createdAt,
      isRead: map['isRead'] as bool? ?? false,
      isExpired: map['isExpired'] as bool? ?? false,
      targetRoute: map['targetRoute'] as String? ?? 'dashboard',
    );
  }
}
