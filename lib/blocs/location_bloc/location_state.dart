part of 'location_bloc.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationPermissionDenied extends LocationState {
  final String message;

  const LocationPermissionDenied({required this.message});

  @override
  List<Object?> get props => [message];
}

class LocationServiceDisabled extends LocationState {
  final String message;

  const LocationServiceDisabled({required this.message});

  @override
  List<Object?> get props => [message];
}

class LocationTrackingActive extends LocationState {
  final Position currentPosition;
  final bool isWithinGeofence;
  final CheckPointModel? nearestCheckpoint;
  final double? distanceToCheckpoint;
  final List<GuardMovementModel> recentMovements;
  final DateTime lastUpdate;
  final double accuracy;
  final String trackingStatus;

  const LocationTrackingActive({
    required this.currentPosition,
    required this.isWithinGeofence,
    this.nearestCheckpoint,
    this.distanceToCheckpoint,
    required this.recentMovements,
    required this.lastUpdate,
    required this.accuracy,
    required this.trackingStatus,
  });

  @override
  List<Object?> get props => [
        currentPosition,
        isWithinGeofence,
        nearestCheckpoint,
        distanceToCheckpoint,
        recentMovements,
        lastUpdate,
        accuracy,
        trackingStatus,
      ];

  LocationTrackingActive copyWith({
    Position? currentPosition,
    bool? isWithinGeofence,
    CheckPointModel? nearestCheckpoint,
    double? distanceToCheckpoint,
    List<GuardMovementModel>? recentMovements,
    DateTime? lastUpdate,
    double? accuracy,
    String? trackingStatus,
  }) {
    return LocationTrackingActive(
      currentPosition: currentPosition ?? this.currentPosition,
      isWithinGeofence: isWithinGeofence ?? this.isWithinGeofence,
      nearestCheckpoint: nearestCheckpoint ?? this.nearestCheckpoint,
      distanceToCheckpoint: distanceToCheckpoint ?? this.distanceToCheckpoint,
      recentMovements: recentMovements ?? this.recentMovements,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      accuracy: accuracy ?? this.accuracy,
      trackingStatus: trackingStatus ?? this.trackingStatus,
    );
  }
}

class LocationTrackingInactive extends LocationState {
  final String reason;

  const LocationTrackingInactive({required this.reason});

  @override
  List<Object?> get props => [reason];
}

class LocationError extends LocationState {
  final String message;
  final bool canRetry;

  const LocationError({
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, canRetry];
}

class GeofenceStatusChanged extends LocationState {
  final bool isWithinGeofence;
  final String siteName;
  final DateTime timestamp;

  const GeofenceStatusChanged({
    required this.isWithinGeofence,
    required this.siteName,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [isWithinGeofence, siteName, timestamp];
}

class CheckpointProximityDetected extends LocationState {
  final CheckPointModel checkpoint;
  final double distance;
  final bool isWithinRange;
  final DateTime timestamp;

  const CheckpointProximityDetected({
    required this.checkpoint,
    required this.distance,
    required this.isWithinRange,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [checkpoint, distance, isWithinRange, timestamp];
}

class MovementRecorded extends LocationState {
  final GuardMovementModel movement;
  final String message;

  const MovementRecorded({
    required this.movement,
    required this.message,
  });

  @override
  List<Object?> get props => [movement, message];
}