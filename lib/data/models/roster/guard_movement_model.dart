class GuardMovementModel {
  final int? id;
  final int rosterUserId;
  final int guardId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? heading;
  final double? speed;
  final DateTime timestamp;
  final int? batteryLevel;
  final String? deviceId;
  final String? movementType;
  final double? checkpointProximity;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GuardMovementModel({
    this.id,
    required this.rosterUserId,
    required this.guardId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.heading,
    this.speed,
    required this.timestamp,
    this.batteryLevel,
    this.deviceId,
    this.movementType,
    this.checkpointProximity,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory GuardMovementModel.fromJson(Map<String, dynamic> json) {
    return GuardMovementModel(
      id: json['id'],
      rosterUserId: json['rosterUserId'] ?? json['roster_user_id'] ?? 0,
      guardId: json['guardId'] ?? json['guard_id'] ?? 0,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      accuracy: json['accuracy'] != null ? double.tryParse(json['accuracy'].toString()) : null,
      altitude: json['altitude'] != null ? double.tryParse(json['altitude'].toString()) : null,
      heading: json['heading'] != null ? double.tryParse(json['heading'].toString()) : null,
      speed: json['speed'] != null ? double.tryParse(json['speed'].toString()) : null,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      batteryLevel: json['batteryLevel'] ?? json['battery_level'],
      deviceId: json['deviceId'] ?? json['device_id'],
      movementType: json['movementType'] ?? json['movement_type'],
      checkpointProximity: json['checkpointProximity'] != null 
          ? double.tryParse(json['checkpointProximity'].toString())
          : json['checkpoint_proximity'] != null 
              ? double.tryParse(json['checkpoint_proximity'].toString())
              : null,
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'rosterUserId': rosterUserId,
      'guardId': guardId,
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (altitude != null) 'altitude': altitude,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      'timestamp': timestamp.toIso8601String(),
      if (batteryLevel != null) 'batteryLevel': batteryLevel,
      if (deviceId != null) 'deviceId': deviceId,
      if (movementType != null) 'movementType': movementType,
      if (checkpointProximity != null) 'checkpointProximity': checkpointProximity,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  String get coordinates => '$latitude, $longitude';
  String get formattedTimestamp => timestamp.toString();

  GuardMovementModel copyWith({
    int? id,
    int? rosterUserId,
    int? guardId,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? heading,
    double? speed,
    DateTime? timestamp,
    int? batteryLevel,
    String? deviceId,
    String? movementType,
    double? checkpointProximity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GuardMovementModel(
      id: id ?? this.id,
      rosterUserId: rosterUserId ?? this.rosterUserId,
      guardId: guardId ?? this.guardId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      deviceId: deviceId ?? this.deviceId,
      movementType: movementType ?? this.movementType,
      checkpointProximity: checkpointProximity ?? this.checkpointProximity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}