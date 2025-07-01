class ContractGuardRequirementModel {
  final int id;
  final int contractId;
  final int siteId;
  final int guardTypeId;
  final int guardNumber;
  final int sitePerimeterId;

  ContractGuardRequirementModel({
    required this.id,
    required this.contractId,
    required this.siteId,
    required this.guardTypeId,
    required this.guardNumber,
    required this.sitePerimeterId,
  });

  factory ContractGuardRequirementModel.fromJson(Map<String, dynamic> json) {
    return ContractGuardRequirementModel(
      id: json['id'] ?? 0,
      contractId: json['contractId'] ?? 0,
      siteId: json['siteId'] ?? 0,
      guardTypeId: json['guardTypeId'] ?? 0,
      guardNumber: json['guardNumber'] ?? 0,
      sitePerimeterId: json['sitePerimeterId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contractId': contractId,
      'siteId': siteId,
      'guardTypeId': guardTypeId,
      'guardNumber': guardNumber,
      'sitePerimeterId': sitePerimeterId,
    };
  }

  ContractGuardRequirementModel copyWith({
    int? id,
    int? contractId,
    int? siteId,
    int? guardTypeId,
    int? guardNumber,
    int? sitePerimeterId,
  }) {
    return ContractGuardRequirementModel(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      siteId: siteId ?? this.siteId,
      guardTypeId: guardTypeId ?? this.guardTypeId,
      guardNumber: guardNumber ?? this.guardNumber,
      sitePerimeterId: sitePerimeterId ?? this.sitePerimeterId,
    );
  }
}