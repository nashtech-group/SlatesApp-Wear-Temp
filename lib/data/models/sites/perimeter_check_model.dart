class PerimeterCheckModel {
  final int? id;
  final DateTime passTime;
  final int guardId;
  final int rosterUserId;
  final int sitePerimeterId;
  final int checkpointId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PerimeterCheckModel({
    this.id,
    required this.passTime,
    required this.guardId,
    required this.rosterUserId,
    required this.sitePerimeterId,
    required this.checkpointId,
    this.createdAt,
    this.updatedAt,
  });

  factory PerimeterCheckModel.fromJson(Map<String, dynamic> json) {
    return PerimeterCheckModel(
      id: json['id'],
      passTime: DateTime.parse(json['passTime'] ?? json['pass_time'] ?? DateTime.now().toIso8601String()),
      guardId: json['guardId'] ?? json['guard_id'] ?? 0,
      rosterUserId: json['rosterUserId'] ?? json['roster_user_id'] ?? 0,
      sitePerimeterId: json['sitePerimeterId'] ?? json['site_perimeter_id'] ?? 0,
      checkpointId: json['checkpointId'] ?? json['checkpoint_id'] ?? json['check_point_id'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'passTime': passTime.toIso8601String(),
      'guardId': guardId,
      'rosterUserId': rosterUserId,
      'sitePerimeterId': sitePerimeterId,
      'checkpointId': checkpointId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  String get formattedPassTime => passTime.toString();

  PerimeterCheckModel copyWith({
    int? id,
    DateTime? passTime,
    int? guardId,
    int? rosterUserId,
    int? sitePerimeterId,
    int? checkpointId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PerimeterCheckModel(
      id: id ?? this.id,
      passTime: passTime ?? this.passTime,
      guardId: guardId ?? this.guardId,
      rosterUserId: rosterUserId ?? this.rosterUserId,
      sitePerimeterId: sitePerimeterId ?? this.sitePerimeterId,
      checkpointId: checkpointId ?? this.checkpointId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}