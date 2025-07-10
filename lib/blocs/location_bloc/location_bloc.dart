import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:slates_app_wear/data/models/roster/guard_movement_model.dart';
import 'package:slates_app_wear/data/models/sites/checkpoint_model.dart';
import 'package:slates_app_wear/data/models/sites/site_model.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/services/offline_storage_service.dart';
import '../../core/error/bloc_error_mixin.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/error_state_mixin.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> 
    with BlocErrorMixin<LocationEvent, LocationState> {
  final OfflineStorageService _offlineStorage;
  
  StreamSubscription<Position>? _positionSubscription;
  Timer? _movementTimer;
  
  // Tracking state
  bool _isTrackingActive = false;
  int? _currentGuardId;
  int? _currentRosterUserId;
  SiteModel? _currentSite;
  Position? _lastPosition;
  DateTime? _lastMovementRecord;
  List<GuardMovementModel> _recentMovements = [];
  
  // Settings
  int _updateIntervalSeconds = AppConstants.locationUpdateIntervalSeconds;

  LocationBloc({OfflineStorageService? offlineStorage})
      : _offlineStorage = offlineStorage ?? OfflineStorageService(),
        super(const LocationInitial()) {
    
    on<InitializeLocationTracking>(_onInitializeLocationTracking);
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<UpdateLocationSettings>(_onUpdateLocationSettings);
    on<CheckGeofenceStatus>(_onCheckGeofenceStatus);
    on<CheckCheckpointProximity>(_onCheckCheckpointProximity);
    on<RecordMovement>(_onRecordMovement);
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<CheckLocationServices>(_onCheckLocationServices);
    on<ClearLocationError>(_onClearLocationError);
  }

  @override
  LocationState createDefaultErrorState(BlocErrorInfo errorInfo) {
    return LocationError(errorInfo: errorInfo);
  }

  Future<void> _onInitializeLocationTracking(
    InitializeLocationTracking event,
    Emitter<LocationState> emit,
  ) async {
    try {
      // Check location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        handleErrorWithState(
          'Location permission denied',
          emit,
          (errorInfo) => LocationPermissionDenied(
            errorInfo: errorInfo.copyWith(
              message: 'Location permission is required for guard duties',
            ),
          ),
          context: 'Initialize Location Tracking',
        );
        return;
      }

      // Check if location services are enabled
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        handleErrorWithState(
          'Location services disabled',
          emit,
          (errorInfo) => LocationServiceDisabled(
            errorInfo: errorInfo.copyWith(
              message: 'Please enable location services to continue',
            ),
          ),
          context: 'Initialize Location Tracking',
        );
        return;
      }

      emit(const LocationTrackingInactive(
        reason: 'Location tracking initialized and ready',
      ));
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Initialize Location Tracking',
      );
    }
  }

  Future<void> _onStartLocationTracking(
    StartLocationTracking event,
    Emitter<LocationState> emit,
  ) async {
    try {
      if (_isTrackingActive) {
        await _stopTracking();
      }

      _currentGuardId = event.guardId;
      _currentRosterUserId = event.rosterUserId;
      _currentSite = event.site;
      _isTrackingActive = true;
      _recentMovements = [];

      // Configure location settings
      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConstants.minimumMovementDistance.toInt(),
      );

      // Start position stream
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          add(CheckGeofenceStatus(position: position));
          add(CheckCheckpointProximity(
            position: position,
            checkpoints: event.site.allCheckpoints,
          ));
          
          // Record movement if enough time has passed
          if (_shouldRecordMovement(position)) {
            add(RecordMovement(position: position));
          }
        },
        onError: (error) {
          handleError(
            error,
            emit,
            context: 'Location Stream',
            additionalData: {
              'guardId': event.guardId,
              'siteId': event.site.id,
            },
          );
        },
      );

      // Start periodic movement recording
      _startMovementTimer();

      // Get initial position
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      emit(LocationTrackingActive(
        currentPosition: initialPosition,
        isWithinGeofence: _isWithinGeofence(initialPosition, event.site),
        recentMovements: _recentMovements,
        lastUpdate: DateTime.now(),
        accuracy: initialPosition.accuracy,
        trackingStatus: 'Active',
      ));

    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Start Location Tracking',
        additionalData: {
          'guardId': event.guardId,
          'siteId': event.site.id,
        },
      );
    }
  }

  Future<void> _onStopLocationTracking(
    StopLocationTracking event,
    Emitter<LocationState> emit,
  ) async {
    try {
      await _stopTracking();
      emit(const LocationTrackingInactive(
        reason: 'Location tracking stopped',
      ));
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Stop Location Tracking',
      );
    }
  }

  Future<void> _stopTracking() async {
    _isTrackingActive = false;
    _positionSubscription?.cancel();
    _movementTimer?.cancel();
    _currentGuardId = null;
    _currentRosterUserId = null;
    _currentSite = null;
    _lastPosition = null;
    _lastMovementRecord = null;
  }

  void _startMovementTimer() {
    _movementTimer = Timer.periodic(
      Duration(seconds: _updateIntervalSeconds),
      (_) async {
        if (_isTrackingActive && _lastPosition != null) {
          add(RecordMovement(position: _lastPosition!));
        }
      },
    );
  }

  Future<void> _onUpdateLocationSettings(
    UpdateLocationSettings event,
    Emitter<LocationState> emit,
  ) async {
    try {
      _updateIntervalSeconds = event.updateIntervalSeconds;

      // Restart timer with new interval
      if (_isTrackingActive) {
        _movementTimer?.cancel();
        _startMovementTimer();
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Update Location Settings',
        additionalData: {'updateInterval': event.updateIntervalSeconds},
      );
    }
  }

  Future<void> _onCheckGeofenceStatus(
    CheckGeofenceStatus event,
    Emitter<LocationState> emit,
  ) async {
    try {
      if (!_isTrackingActive || _currentSite == null) return;

      final isWithinGeofence = _isWithinGeofence(event.position, _currentSite!);
      
      if (state is LocationTrackingActive) {
        final currentState = state as LocationTrackingActive;
        
        // Check if geofence status changed
        if (currentState.isWithinGeofence != isWithinGeofence) {
          emit(GeofenceStatusChanged(
            isWithinGeofence: isWithinGeofence,
            siteName: _currentSite!.name,
            timestamp: DateTime.now(),
          ));
        }

        emit(currentState.copyWith(
          currentPosition: event.position,
          isWithinGeofence: isWithinGeofence,
          lastUpdate: DateTime.now(),
          accuracy: event.position.accuracy,
        ));
      }

      _lastPosition = event.position;
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Check Geofence Status',
        additionalData: {
          'latitude': event.position.latitude,
          'longitude': event.position.longitude,
        },
      );
    }
  }

  Future<void> _onCheckCheckpointProximity(
    CheckCheckpointProximity event,
    Emitter<LocationState> emit,
  ) async {
    try {
      if (!_isTrackingActive || event.checkpoints.isEmpty) return;

      CheckPointModel? nearestCheckpoint;
      double? nearestDistance;

      // Find nearest checkpoint
      for (final checkpoint in event.checkpoints) {
        final distance = _calculateDistance(
          event.position.latitude,
          event.position.longitude,
          checkpoint.latitude,
          checkpoint.longitude,
        );

        if (nearestCheckpoint == null || distance < nearestDistance!) {
          nearestCheckpoint = checkpoint;
          nearestDistance = distance;
        }
      }

      if (nearestCheckpoint != null && nearestDistance != null) {
        final isWithinRange = nearestDistance <= AppConstants.geofenceRadiusMeters;

        // Emit proximity detection if within range
        if (isWithinRange) {
          emit(CheckpointProximityDetected(
            checkpoint: nearestCheckpoint,
            distance: nearestDistance,
            isWithinRange: isWithinRange,
            timestamp: DateTime.now(),
          ));
        }

        // Update tracking state
        if (state is LocationTrackingActive) {
          final currentState = state as LocationTrackingActive;
          emit(currentState.copyWith(
            nearestCheckpoint: nearestCheckpoint,
            distanceToCheckpoint: nearestDistance,
          ));
        }
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Check Checkpoint Proximity',
        additionalData: {
          'checkpointsCount': event.checkpoints.length,
          'latitude': event.position.latitude,
          'longitude': event.position.longitude,
        },
      );
    }
  }

  Future<void> _onRecordMovement(
    RecordMovement event,
    Emitter<LocationState> emit,
  ) async {
    if (!_isTrackingActive || _currentGuardId == null || _currentRosterUserId == null) {
      return;
    }

    try {
      final movement = GuardMovementModel(
        rosterUserId: _currentRosterUserId!,
        guardId: _currentGuardId!,
        latitude: event.position.latitude,
        longitude: event.position.longitude,
        accuracy: event.position.accuracy,
        altitude: event.position.altitude,
        heading: event.position.heading,
        speed: event.position.speed,
        timestamp: DateTime.now(),
        movementType: event.movementType ?? _determineMovementType(event.position),
        notes: event.notes,
      );

      // Store movement locally
      await _offlineStorage.storeGuardMovement(movement);

      // Update recent movements list
      _recentMovements.add(movement);
      if (_recentMovements.length > 100) {
        _recentMovements.removeAt(0);
      }

      _lastMovementRecord = DateTime.now();

      emit(MovementRecorded(
        movement: movement,
        message: 'Movement recorded successfully',
      ));

      // Update tracking state
      if (state is LocationTrackingActive) {
        final currentState = state as LocationTrackingActive;
        emit(currentState.copyWith(
          recentMovements: List.from(_recentMovements),
          lastUpdate: DateTime.now(),
        ));
      }

    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Record Movement',
        additionalData: {
          'guardId': _currentGuardId,
          'rosterUserId': _currentRosterUserId,
          'latitude': event.position.latitude,
          'longitude': event.position.longitude,
        },
      );
    }
  }

  Future<void> _onRequestLocationPermission(
    RequestLocationPermission event,
    Emitter<LocationState> emit,
  ) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        handleErrorWithState(
          'Location permission denied by user',
          emit,
          (errorInfo) => LocationPermissionDenied(
            errorInfo: errorInfo.copyWith(
              message: 'Location permission is required for guard duties. Please enable it in settings.',
            ),
          ),
          context: 'Request Location Permission',
        );
      } else {
        add(const CheckLocationServices());
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Request Location Permission',
      );
    }
  }

  Future<void> _onCheckLocationServices(
    CheckLocationServices event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!isEnabled) {
        handleErrorWithState(
          'Location services are disabled',
          emit,
          (errorInfo) => LocationServiceDisabled(
            errorInfo: errorInfo.copyWith(
              message: 'Location services are disabled. Please enable them in settings.',
            ),
          ),
          context: 'Check Location Services',
        );
      } else {
        emit(const LocationTrackingInactive(
          reason: 'Location services are ready',
        ));
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Check Location Services',
      );
    }
  }

  Future<void> _onClearLocationError(
    ClearLocationError event,
    Emitter<LocationState> emit,
  ) async {
    if (_isErrorState(state)) {
      emit(const LocationInitial());
    }
  }

  // ===== HELPER METHODS =====

  bool _isWithinGeofence(Position position, SiteModel site) {
    // Check if position is within any of the site's perimeters
    for (final perimeter in site.perimeters) {
      for (final checkpoint in perimeter.checkPoints) {
        final distance = _calculateDistance(
          position.latitude,
          position.longitude,
          checkpoint.latitude,
          checkpoint.longitude,
        );
        
        if (distance <= AppConstants.geofenceRadiusMeters) {
          return true;
        }
      }
    }
    return false;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  bool _shouldRecordMovement(Position position) {
    if (_lastMovementRecord == null) return true;
    
    final timeSinceLastRecord = DateTime.now().difference(_lastMovementRecord!);
    if (timeSinceLastRecord.inSeconds < AppConstants.movementUpdateInterval) {
      return false;
    }

    if (_lastPosition != null) {
      final distance = _calculateDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      return distance >= AppConstants.minimumMovementDistance;
    }

    return true;
  }

  String _determineMovementType(Position position) {
    if (position.speed > AppConstants.runningSpeedThreshold) {
      return AppConstants.transitMovement;
    } else if (position.speed > AppConstants.walkingSpeedThreshold) {
      return AppConstants.patrolMovement;
    }
    return AppConstants.idleMovement;
  }

  /// Check if current state is an error state
  bool _isErrorState(LocationState state) {
    return state is LocationError ||
           state is LocationPermissionDenied ||
           state is LocationServiceDisabled;
  }

  // ===== PUBLIC GETTERS =====

  /// Get current position
  Position? get currentPosition => _lastPosition;
  
  /// Check if tracking is active
  bool get isTrackingActive => _isTrackingActive;
  
  /// Get recent movements
  List<GuardMovementModel> get recentMovements => List.from(_recentMovements);

  /// Check if bloc has error
  bool get hasError => _isErrorState(state);

  /// Get current error info if in error state
  BlocErrorInfo? get currentError {
    return switch (state) {
      LocationError(:final errorInfo) => errorInfo,
      LocationPermissionDenied(:final errorInfo) => errorInfo,
      LocationServiceDisabled(:final errorInfo) => errorInfo,
      _ => null,
    };
  }

  /// Check if can retry current operation
  bool get canRetry {
    final error = currentError;
    return error?.canRetry ?? false;
  }

  /// Get location summary for UI
  Map<String, dynamic> get locationSummary {
    return {
      'isTrackingActive': _isTrackingActive,
      'hasCurrentPosition': _lastPosition != null,
      'recentMovementsCount': _recentMovements.length,
      'currentGuardId': _currentGuardId,
      'currentSite': _currentSite?.name,
      'lastUpdate': _lastMovementRecord,
    };
  }

  @override
  Future<void> close() {
    _stopTracking();
    return super.close();
  }
}