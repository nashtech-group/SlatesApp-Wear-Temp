import 'package:slates_app_wear/data/models/site/site_perimeter_model.dart';
import 'package:slates_app_wear/data/models/sites/checkpoint_model.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';

class SiteModel {
  final int id;
  final int clientId;
  final String name;
  final String physicalAddress;
  final String city;
  final String country;
  final int status;
  final UserModel createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SitePerimeterModel> perimeters;

  SiteModel({
    required this.id,
    required this.clientId,
    required this.name,
    required this.physicalAddress,
    required this.city,
    required this.country,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.perimeters,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'] ?? 0,
      clientId: json['clientId'] ?? 0,
      name: json['name'] ?? '',
      physicalAddress: json['physicalAddress'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      status: json['status'] ?? 0,
      createdBy: UserModel.fromJson(json['createdBy'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      perimeters: (json['perimeters'] as List<dynamic>?)
          ?.map((p) => SitePerimeterModel.fromJson(p))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'name': name,
      'physicalAddress': physicalAddress,
      'city': city,
      'country': country,
      'status': status,
      'createdBy': createdBy.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'perimeters': perimeters.map((p) => p.toJson()).toList(),
    };
  }

  bool get isActive => status == 1;
  
  // Get all checkpoints across all perimeters
  List<CheckPointModel> get allCheckpoints {
    return perimeters.expand((p) => p.checkPoints).toList();
  }

  // Get total checkpoint count
  int get totalCheckpoints => allCheckpoints.length;

  SiteModel copyWith({
    int? id,
    int? clientId,
    String? name,
    String? physicalAddress,
    String? city,
    String? country,
    int? status,
    UserModel? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SitePerimeterModel>? perimeters,
  }) {
    return SiteModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      physicalAddress: physicalAddress ?? this.physicalAddress,
      city: city ?? this.city,
      country: country ?? this.country,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      perimeters: perimeters ?? this.perimeters,
    );
  }
}