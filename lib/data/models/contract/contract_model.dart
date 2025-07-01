class ContractModel {
  final int id;
  final int customerId;
  final int clientId;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContractModel({
    required this.id,
    required this.customerId,
    required this.clientId,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] ?? 0,
      customerId: json['customerId'] ?? 0,
      clientId: json['clientId'] ?? 0,
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'clientId': clientId,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 1;
  bool get isExpired => DateTime.now().isAfter(endDate);

  ContractModel copyWith({
    int? id,
    int? customerId,
    int? clientId,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContractModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      clientId: clientId ?? this.clientId,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}