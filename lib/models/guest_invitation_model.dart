import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an invited guest and their configured invitation details.
class GuestInvitationModel {
  final String id;
  final String guestName;
  final String guestAddress;
  final String templateId;
  final String templateName;
  final Map<String, dynamic> customTemplateData;
  final String status; // 'draft', 'sent'
  final DateTime createdAt;

  const GuestInvitationModel({
    required this.id,
    required this.guestName,
    required this.guestAddress,
    required this.templateId,
    this.templateName = 'Modern Minimalist',
    this.customTemplateData = const {},
    this.status = 'draft',
    required this.createdAt,
  });

  GuestInvitationModel copyWith({
    String? id,
    String? guestName,
    String? guestAddress,
    String? templateId,
    String? templateName,
    Map<String, dynamic>? customTemplateData,
    String? status,
    DateTime? createdAt,
  }) {
    return GuestInvitationModel(
      id: id ?? this.id,
      guestName: guestName ?? this.guestName,
      guestAddress: guestAddress ?? this.guestAddress,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      customTemplateData: customTemplateData ?? this.customTemplateData,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guestName': guestName,
      'guestAddress': guestAddress,
      'templateId': templateId,
      'templateName': templateName,
      'customTemplateData': customTemplateData,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GuestInvitationModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parsedDate;
    final rawDate = map['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return GuestInvitationModel(
      id: map['id'] ?? docId ?? '',
      guestName: map['guestName'] ?? '',
      guestAddress: map['guestAddress'] ?? '',
      templateId: map['templateId'] ?? 'minimalist',
      templateName: map['templateName'] ?? 'Modern Minimalist',
      customTemplateData: map['customTemplateData'] != null
          ? Map<String, dynamic>.from(map['customTemplateData'])
          : {},
      status: map['status'] ?? 'draft',
      createdAt: parsedDate,
    );
  }
}
