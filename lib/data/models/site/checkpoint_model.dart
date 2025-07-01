class CheckPointModel {
  final int id;
  final String title;
  final int sitePerimeterId;
  final double longitude;
  final double latitude;
  final double altitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  CheckPointModel({
    required this.id,
    required this.title,
    required this.sitePerimeterId,
    required this.longitude,
    required this.latitude,
    required this.altitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CheckPointModel.fromJson(Map<String, dynamic> json) {
    return CheckPointModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      sitePerimeterId: json['sitePerimeterId'] ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      altitude: double.tryParse(json['altitude']?.toString() ?? '0.0') ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sitePerimeterId': sitePerimeterId,
      'longitude': longitude.toString(),
      'latitude': latitude.toString(),
      'altitude': altitude.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get coordinates => '$latitude, $longitude';

  CheckPointModel copyWith({
    int? id,
    String? title,
    int? sitePerimeterId,
    double? longitude,
    double? latitude,
    double? altitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CheckPointModel(
      id: id ?? this.id,
      title: title ?? this.title,
      sitePerimeterId: sitePerimeterId ?? this.sitePerimeterId,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      altitude: altitude ?? this.altitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}