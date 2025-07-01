import 'package:slates_app_wear/data/models/sites/checkpoint_model.dart';

class SitePerimeterModel {
  final int id;
  final int siteId;
  final int contractId;
  final String title;
  final int guardAllocation;
  final List<CheckPointModel> checkPoints;
  final DateTime dateCreated;
  final DateTime dateUpdated;

  SitePerimeterModel({
    required this.id,
    required this.siteId,
    required this.contractId,
    required this.title,
    required this.guardAllocation,
    required this.checkPoints,
    required this.dateCreated,
    required this.dateUpdated,
  });

  factory SitePerimeterModel.fromJson(Map<String, dynamic> json) {
    return SitePerimeterModel(
      id: json['id'] ?? 0,
      siteId: json['siteId'] ?? 0,
      contractId: json['contractId'] ?? 0,
      title: json['title'] ?? '',
      guardAllocation: json['guardAllocation'] ?? 0,
      checkPoints: (json['checkPoints'] as List<dynamic>?)
          ?.map((cp) => CheckPointModel.fromJson(cp))
          .toList() ?? [],
      dateCreated: DateTime.parse(json['dateCreated'] ?? DateTime.now().toIso8601String()),
      dateUpdated: DateTime.parse(json['dateUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'siteId': siteId,
      'contractId': contractId,
      'title': title,
      'guardAllocation': guardAllocation,
      'checkPoints': checkPoints.map((cp) => cp.toJson()).toList(),
      'dateCreated': dateCreated.toIso8601String(),
      'dateUpdated': dateUpdated.toIso8601String(),
    };
  }

  int get checkpointCount => checkPoints.length;

  SitePerimeterModel copyWith({
    int? id,
    int? siteId,
    int? contractId,
    String? title,
    int? guardAllocation,
    List<CheckPointModel>? checkPoints,
    DateTime? dateCreated,
    DateTime? dateUpdated,
  }) {
    return SitePerimeterModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      contractId: contractId ?? this.contractId,
      title: title ?? this.title,
      guardAllocation: guardAllocation ?? this.guardAllocation,
      checkPoints: checkPoints ?? this.checkPoints,
      dateCreated: dateCreated ?? this.dateCreated,
      dateUpdated: dateUpdated ?? this.dateUpdated,
    );
  }
}