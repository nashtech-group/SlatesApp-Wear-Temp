part of 'location_bloc.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize location tracking system
class InitializeLocationTracking extends LocationEvent {
  const InitializeLocationTracking();
}

/// Start location tracking for a specific guard and site
class StartLocationTracking extends LocationEvent {
  final int guardId;
  final int rosterUserId;
  final SiteModel site;
  final bool isDutyActive;

  const StartLocationTracking({
    required this.guardId,
    required this.rosterUserId,
    required this.site,
    required this.isDutyActive,
  });

  @override
  List<Object?> get props => [guardId, rosterUserId, site, isDutyActive];
}

/// Stop location tracking
class StopLocationTracking extends LocationEvent {
  const StopLocationTracking();
}

/// Update location tracking settings
class UpdateLocationSettings extends LocationEvent {
  final int updateIntervalSeconds;
  final double accuracyThreshold;

  const UpdateLocationSettings({
    required this.updateIntervalSeconds,
    required this.accuracyThreshold,
  });

  @override
  List<Object?> get props => [updateIntervalSeconds, accuracyThreshold];
}

/// Check geofence status for current position
class CheckGeofenceStatus extends LocationEvent {
  final Position position;

  const CheckGeofenceStatus({required this.position});

  @override
  List<Object?> get props => [position];
}

/// Check proximity to checkpoints
class CheckCheckpointProximity extends LocationEvent {
  final Position position;
  final List<CheckPointModel> checkpoints;

  const CheckCheckpointProximity({
    required this.position,
    required this.checkpoints,
  });

  @override
  List<Object?> get props => [position, checkpoints];
}

/// Record a movement entry
class RecordMovement extends LocationEvent {
  final Position position;
  final String? movementType;
  final String? notes;

  const RecordMovement({
    required this.position,
    this.movementType,
    this.notes,
  });

  @override
  List<Object?> get props => [position, movementType, notes];
}

/// Request location permission from user
class RequestLocationPermission extends LocationEvent {
  const RequestLocationPermission();
}

/// Check if location services are enabled
class CheckLocationServices extends LocationEvent {
  const CheckLocationServices();
}

/// Clear current location error state (following DRY pattern from reference files)
class ClearLocationError extends LocationEvent {
  const ClearLocationError();
}