part of 'location_bloc.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeLocationTracking extends LocationEvent {
  const InitializeLocationTracking();
}

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

class StopLocationTracking extends LocationEvent {
  const StopLocationTracking();
}

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

class CheckGeofenceStatus extends LocationEvent {
  final Position position;

  const CheckGeofenceStatus({required this.position});

  @override
  List<Object?> get props => [position];
}

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

class RequestLocationPermission extends LocationEvent {
  const RequestLocationPermission();
}

class CheckLocationServices extends LocationEvent {
  const CheckLocationServices();
}