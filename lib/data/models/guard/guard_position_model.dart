class GuardPositionModel {
  final int id;
  final String title;
  final String patrolFrequency;
  final String maxHoursPerShift;
  final String securityGuard;
  final String gender;
  final int sitePerimeterId;
  final int contractGuardRequirementId;
  final List<dynamic> timeRequirements;

  GuardPositionModel({
    required this.id,
    required this.title,
    required this.patrolFrequency,
    required this.maxHoursPerShift,
    required this.securityGuard,
    required this.gender,
    required this.sitePerimeterId,
    required this.contractGuardRequirementId,
    required this.timeRequirements,
  });

  factory GuardPositionModel.fromJson(Map<String, dynamic> json) {
    return GuardPositionModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      patrolFrequency: json['patrolFrequency'] ?? '00:00:00',
      maxHoursPerShift: json['maxHoursPerShift'] ?? '00:00:00',
      securityGuard: json['securityGuard'] ?? '',
      gender: json['gender'] ?? 'Any',
      sitePerimeterId: json['sitePerimeterId'] ?? 0,
      contractGuardRequirementId: json['contractGuardRequirementId'] ?? 0,
      timeRequirements: json['timeRequirements'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'patrolFrequency': patrolFrequency,
      'maxHoursPerShift': maxHoursPerShift,
      'securityGuard': securityGuard,
      'gender': gender,
      'sitePerimeterId': sitePerimeterId,
      'contractGuardRequirementId': contractGuardRequirementId,
      'timeRequirements': timeRequirements,
    };
  }

  bool get isRovingGuard => securityGuard.toLowerCase() == 'roving';
  bool get isStaticGuard => securityGuard.toLowerCase() == 'static';

  GuardPositionModel copyWith({
    int? id,
    String? title,
    String? patrolFrequency,
    String? maxHoursPerShift,
    String? securityGuard,
    String? gender,
    int? sitePerimeterId,
    int? contractGuardRequirementId,
    List<dynamic>? timeRequirements,
  }) {
    return GuardPositionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      patrolFrequency: patrolFrequency ?? this.patrolFrequency,
      maxHoursPerShift: maxHoursPerShift ?? this.maxHoursPerShift,
      securityGuard: securityGuard ?? this.securityGuard,
      gender: gender ?? this.gender,
      sitePerimeterId: sitePerimeterId ?? this.sitePerimeterId,
      contractGuardRequirementId: contractGuardRequirementId ?? this.contractGuardRequirementId,
      timeRequirements: timeRequirements ?? this.timeRequirements,
    );
  }
}
