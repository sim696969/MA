import 'dart:convert';

class WeddingProject {
  final String id;
  final DateTime? weddingDate;
  final String? weddingTime;
  final String? selectedVenueName;
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

  const WeddingProject({
    required this.id,
    this.weddingDate,
    this.weddingTime,
    this.selectedVenueName,
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
  });

  bool get isInitialized => weddingDate != null && weddingTime != null;

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

  WeddingProject copyWith({
    String? id,
    DateTime? weddingDate,
    String? weddingTime,
    String? selectedVenueName,
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
  }) {
    return WeddingProject(
      id: id ?? this.id,
      weddingDate: weddingDate ?? this.weddingDate,
      weddingTime: weddingTime ?? this.weddingTime,
      selectedVenueName: selectedVenueName ?? this.selectedVenueName,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weddingDate': weddingDate?.toIso8601String(),
      'weddingTime': weddingTime,
      'selectedVenueName': selectedVenueName,
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
    };
  }

  factory WeddingProject.fromMap(Map<String, dynamic> map) {
    return WeddingProject(
      id: map['id'] ?? 'default_project',
      weddingDate: map['weddingDate'] != null ? DateTime.tryParse(map['weddingDate']) : null,
      weddingTime: map['weddingTime'],
      selectedVenueName: map['selectedVenueName'],
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
    );
  }

  String toJson() => json.encode(toMap());

  factory WeddingProject.fromJson(String source) => WeddingProject.fromMap(json.decode(source));
}
