import 'dart:convert';

class WeddingProject {
  final String id;
  final DateTime? weddingDate;
  final String? weddingTime;
  final String? selectedVenueName;
  final String? selectedVenueId;
  final String? selectedVenueAddress;
  final double venueFee;
  final bool isVenueCompleted;

  final String? plannerLayoutSummary;
  final double plannerFee;
  final bool isPlannerCompleted;

  final String? selectedInvitationName;
  final double invitationFee;
  final bool isInvitationCompleted;

  final String? selectedCateringPackage;
  final double cateringFee;
  final bool isCateringCompleted;

  final String paymentStatus; // 'pending' or 'paid'
  final String? transactionId;
  final double amountPaid;
  final DateTime? paymentDate;
  final double pendingRefundAmount;
  final String paymentNotice;

  const WeddingProject({
    required this.id,
    this.weddingDate,
    this.weddingTime,
    this.selectedVenueName,
    this.selectedVenueId,
    this.selectedVenueAddress,
    this.venueFee = 0.0,
    this.isVenueCompleted = false,
    this.plannerLayoutSummary,
    this.plannerFee = 0.0,
    this.isPlannerCompleted = false,
    this.selectedInvitationName,
    this.invitationFee = 0.0,
    this.isInvitationCompleted = false,
    this.selectedCateringPackage,
    this.cateringFee = 0.0,
    this.isCateringCompleted = false,
    this.paymentStatus = 'pending',
    this.transactionId,
    this.amountPaid = 0.0,
    this.paymentDate,
    this.pendingRefundAmount = 0.0,
    this.paymentNotice = '',
  });

  bool get isInitialized => weddingDate != null && weddingTime != null;
  bool get isPaid => paymentStatus.toLowerCase() == 'paid';

  int get completedStepsCount {
    int count = 0;
    if (isVenueCompleted) count++;
    if (isPlannerCompleted) count++;
    if (isInvitationCompleted) count++;
    if (isCateringCompleted) count++;
    return count;
  }

  double get progressPercentage => (completedStepsCount / 4.0).clamp(0.0, 1.0);

  bool get isFullyCompleted => completedStepsCount == 4;

  double get totalFee => venueFee + plannerFee + invitationFee + cateringFee;
  double get totalPayable => totalFee * 1.06;
  double get balanceDue =>
      (totalPayable - amountPaid).clamp(0.0, double.infinity);

  WeddingProject copyWith({
    String? id,
    DateTime? weddingDate,
    String? weddingTime,
    String? selectedVenueName,
    String? selectedVenueId,
    String? selectedVenueAddress,
    double? venueFee,
    bool? isVenueCompleted,
    String? plannerLayoutSummary,
    double? plannerFee,
    bool? isPlannerCompleted,
    String? selectedInvitationName,
    double? invitationFee,
    bool? isInvitationCompleted,
    String? selectedCateringPackage,
    double? cateringFee,
    bool? isCateringCompleted,
    String? paymentStatus,
    String? transactionId,
    double? amountPaid,
    DateTime? paymentDate,
    double? pendingRefundAmount,
    String? paymentNotice,
  }) {
    return WeddingProject(
      id: id ?? this.id,
      weddingDate: weddingDate ?? this.weddingDate,
      weddingTime: weddingTime ?? this.weddingTime,
      selectedVenueName: selectedVenueName ?? this.selectedVenueName,
      selectedVenueId: selectedVenueId ?? this.selectedVenueId,
      selectedVenueAddress: selectedVenueAddress ?? this.selectedVenueAddress,
      venueFee: venueFee ?? this.venueFee,
      isVenueCompleted: isVenueCompleted ?? this.isVenueCompleted,
      plannerLayoutSummary: plannerLayoutSummary ?? this.plannerLayoutSummary,
      plannerFee: plannerFee ?? this.plannerFee,
      isPlannerCompleted: isPlannerCompleted ?? this.isPlannerCompleted,
      selectedInvitationName: selectedInvitationName ?? this.selectedInvitationName,
      invitationFee: invitationFee ?? this.invitationFee,
      isInvitationCompleted: isInvitationCompleted ?? this.isInvitationCompleted,
      selectedCateringPackage: selectedCateringPackage ?? this.selectedCateringPackage,
      cateringFee: cateringFee ?? this.cateringFee,
      isCateringCompleted: isCateringCompleted ?? this.isCateringCompleted,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionId: transactionId ?? this.transactionId,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      pendingRefundAmount: pendingRefundAmount ?? this.pendingRefundAmount,
      paymentNotice: paymentNotice ?? this.paymentNotice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weddingDate': weddingDate?.toIso8601String(),
      'weddingTime': weddingTime,
      'selectedVenueName': selectedVenueName,
      'selectedVenueId': selectedVenueId,
      'selectedVenueAddress': selectedVenueAddress,
      'venueFee': venueFee,
      'isVenueCompleted': isVenueCompleted,
      'plannerLayoutSummary': plannerLayoutSummary,
      'plannerFee': plannerFee,
      'isPlannerCompleted': isPlannerCompleted,
      'selectedInvitationName': selectedInvitationName,
      'invitationFee': invitationFee,
      'isInvitationCompleted': isInvitationCompleted,
      'selectedCateringPackage': selectedCateringPackage,
      'cateringFee': cateringFee,
      'isCateringCompleted': isCateringCompleted,
      'paymentStatus': paymentStatus,
      'transactionId': transactionId,
      'amountPaid': amountPaid,
      'paymentDate': paymentDate?.toIso8601String(),
      'pendingRefundAmount': pendingRefundAmount,
      'paymentNotice': paymentNotice,
    };
  }

  factory WeddingProject.fromMap(Map<String, dynamic> map) {
    DateTime? parsedPaymentDate;
    final rawPaymentDate = map['paymentDate'];
    if (rawPaymentDate is String) {
      parsedPaymentDate = DateTime.tryParse(rawPaymentDate);
    }

    return WeddingProject(
      id: map['id'] ?? 'default_project',
      weddingDate: map['weddingDate'] != null ? DateTime.tryParse(map['weddingDate']) : null,
      weddingTime: map['weddingTime'],
      selectedVenueName: map['selectedVenueName'],
      selectedVenueId: map['selectedVenueId'],
      selectedVenueAddress: map['selectedVenueAddress'],
      venueFee: (map['venueFee'] as num?)?.toDouble() ?? 0.0,
      isVenueCompleted: map['isVenueCompleted'] ?? false,
      plannerLayoutSummary: map['plannerLayoutSummary'],
      plannerFee: (map['plannerFee'] as num?)?.toDouble() ?? 0.0,
      isPlannerCompleted: map['isPlannerCompleted'] ?? false,
      selectedInvitationName: map['selectedInvitationName'],
      invitationFee: (map['invitationFee'] as num?)?.toDouble() ?? 0.0,
      isInvitationCompleted: map['isInvitationCompleted'] ?? false,
      selectedCateringPackage: map['selectedCateringPackage'],
      cateringFee: (map['cateringFee'] as num?)?.toDouble() ?? 0.0,
      isCateringCompleted: map['isCateringCompleted'] ?? false,
      paymentStatus: map['paymentStatus'] ?? 'pending',
      transactionId: map['transactionId'],
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentDate: parsedPaymentDate,
      pendingRefundAmount: (map['pendingRefundAmount'] as num?)?.toDouble() ?? 0.0,
      paymentNotice: map['paymentNotice'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory WeddingProject.fromJson(String source) => WeddingProject.fromMap(json.decode(source));
}
