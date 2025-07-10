part of 'location_bloc.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
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

  /// Convenience getters for UI
  bool get hasNearestCheckpoint => nearestCheckpoint != null;
  bool get hasRecentMovements => recentMovements.isNotEmpty;
  String get geofenceStatus => isWithinGeofence ? 'Inside' : 'Outside';
  String get accuracyText => '${accuracy.toStringAsFixed(1)}m';
  
  /// Get formatted last update time
  String get formattedLastUpdate {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Get formatted distance to checkpoint
  String get formattedDistanceToCheckpoint {
    if (distanceToCheckpoint == null) return 'Unknown';
    return '${distanceToCheckpoint!.toStringAsFixed(1)}m';
  }
}

class LocationTrackingInactive extends LocationState {
  final String reason;

  const LocationTrackingInactive({required this.reason});

  @override
  List<Object?> get props => [reason];
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

  /// Get user-friendly status message
  String get statusMessage => 
      isWithinGeofence 
          ? 'Entered geofence at $siteName' 
          : 'Exited geofence at $siteName';

  /// Get formatted timestamp
  String get formattedTimestamp {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
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

  /// Get formatted distance
  String get formattedDistance => '${distance.toStringAsFixed(1)}m';

  /// Get proximity message
  String get proximityMessage => 
      'Near checkpoint: ${checkpoint.title} ($formattedDistance)';

  /// Get formatted timestamp
  String get formattedTimestamp {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
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

  /// Get formatted movement type
  String? get formattedMovementType {
    switch (movement.movementType) {
      case 'patrol':
        return 'Patrol';
      case 'checkpoint':
        return 'Checkpoint';
      case 'break':
        return 'Break';
      case 'emergency':
        return 'Emergency';
      case 'idle':
        return 'Idle';
      case 'transit':
        return 'Transit';
      default:
        return movement.movementType?.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Get formatted coordinates
  String get formattedCoordinates => 
      '${movement.latitude.toStringAsFixed(6)}, ${movement.longitude.toStringAsFixed(6)}';
}

class LocationError extends LocationState with ErrorStateMixin {
  @override
  final BlocErrorInfo errorInfo;

  const LocationError({required this.errorInfo});

  @override
  List<Object?> get props => [errorInfo];

  @override
  String get errorTitle => 'Location Error';

  @override
  String get errorIcon => 'location_off';

  /// Create copy with updated error info
  LocationError copyWith({BlocErrorInfo? errorInfo}) {
    return LocationError(errorInfo: errorInfo ?? this.errorInfo);
  }
}

/// Location permission denied error state with ErrorStateMixin
class LocationPermissionDenied extends LocationState with ErrorStateMixin {
  @override
  final BlocErrorInfo errorInfo;

  const LocationPermissionDenied({required this.errorInfo});

  @override
  List<Object?> get props => [errorInfo];

  @override
  String get errorTitle => 'Permission Required';

  @override
  String get errorIcon => 'location_disabled';

  /// Create copy with updated error info
  LocationPermissionDenied copyWith({BlocErrorInfo? errorInfo}) {
    return LocationPermissionDenied(errorInfo: errorInfo ?? this.errorInfo);
  }
}

/// Location service disabled error state with ErrorStateMixin
class LocationServiceDisabled extends LocationState with ErrorStateMixin {
  @override
  final BlocErrorInfo errorInfo;

  const LocationServiceDisabled({required this.errorInfo});

  @override
  List<Object?> get props => [errorInfo];

  @override
  String get errorTitle => 'Location Service Disabled';

  @override
  String get errorIcon => 'gps_off';

  /// Create copy with updated error info
  LocationServiceDisabled copyWith({BlocErrorInfo? errorInfo}) {
    return LocationServiceDisabled(errorInfo: errorInfo ?? this.errorInfo);
  }
}