class CustomerModel {
  final int id;
  final String name;
  final String logo;
  final String country;
  final String physicalAddress;
  final String contactPhone;
  final String industry;
  final int? createdBy;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.logo,
    required this.country,
    required this.physicalAddress,
    required this.contactPhone,
    required this.industry,
    this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logo: json['logo'] ?? '',
      country: json['country'] ?? '',
      physicalAddress: json['physicalAddress'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      industry: json['industry'] ?? '',
      createdBy: json['createdBy'],
      status: json['status'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'country': country,
      'physicalAddress': physicalAddress,
      'contactPhone': contactPhone,
      'industry': industry,
      'createdBy': createdBy,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 1;
  String get displayName => name.isNotEmpty ? name : 'Unknown Company';
}