import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:slates_app_wear/data/models/guard/guard_position_model.dart';
import 'package:slates_app_wear/data/models/sites/checkpoint_model.dart';
import 'package:slates_app_wear/data/models/sites/perimeter_check_model.dart';
import 'package:slates_app_wear/data/models/sites/site_model.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/services/offline_storage_service.dart';

part 'checkpoint_event.dart';
part 'checkpoint_state.dart';

class CheckpointBloc extends Bloc<CheckpointEvent, CheckpointState> {
  final OfflineStorageService _offlineStorage;

  // Current state
  List<CheckPointModel> _checkpoints = [];
  Map<int, bool> _completionStatus = {};
  Map<int, DateTime> _completionTimes = {};
  String _dutyType = 'patrol';
  CheckPointModel? _designatedCheckpoint;
  int? _guardId;
  int? _rosterUserId;

  CheckpointBloc({OfflineStorageService? offlineStorage})
      : _offlineStorage = offlineStorage ?? OfflineStorageService(),
        super(CheckpointInitial()) {
    
    on<InitializeCheckpoints>(_onInitializeCheckpoints);
    on<CheckProximityToCheckpoints>(_onCheckProximityToCheckpoints);
    on<CompleteCheckpoint>(_onCompleteCheckpoint);
    on<GetNextCheckpoint>(_onGetNextCheckpoint);
    on<ResetCheckpoints>(_onResetCheckpoints);
    on<UpdateDutyType>(_onUpdateDutyType);
    on<CheckStaticPosition>(_onCheckStaticPosition);
    on<GetCheckpointProgress>(_onGetCheckpointProgress);
  }

  Future<void> _onInitializeCheckpoints(
    InitializeCheckpoints event,
    Emitter<CheckpointState> emit,
  ) async {
    try {
      emit(const CheckpointLoading(message: 'Initializing checkpoints...'));

      _checkpoints = event.site.allCheckpoints;
      _guardId = event.guardId;
      _rosterUserId = event.rosterUserId;
      
      // Determine duty type
      _dutyType = event.guardPosition.isStaticGuard ? 'static' : 'patrol';
      
      // Initialize completion status
      _completionStatus = {};
      _completionTimes = {};
      for (final checkpoint in _checkpoints) {
        _completionStatus[checkpoint.id] = false;
      }

      CheckPointModel? nextCheckpoint;
      CheckPointModel? designatedCheckpoint;

      if (_dutyType == 'static') {
        // For static duty, find the designated checkpoint
        designatedCheckpoint = _checkpoints.isNotEmpty ? _checkpoints.first : null;
        _designatedCheckpoint = designatedCheckpoint;
      } else {
        // For patrol duty, find the nearest checkpoint as starting point
        // This would require current position, so we'll set it later
        nextCheckpoint = _checkpoints.isNotEmpty ? _checkpoints.first : null;
      }

      emit(CheckpointsInitialized(
        checkpoints: _checkpoints,
        dutyType: _dutyType,
        designatedCheckpoint: designatedCheckpoint,
        nextCheckpoint: nextCheckpoint,
        completionStatus: Map.from(_completionStatus),
        totalCheckpoints: _checkpoints.length,
        completedCheckpoints: 0,
      ));

    } catch (e) {
      emit(CheckpointError(
        message: 'Failed to initialize checkpoints: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCheckProximityToCheckpoints(
    CheckProximityToCheckpoints event,
    Emitter<CheckpointState> emit,
  ) async {
    if (_checkpoints.isEmpty) return;

    try {
      CheckPointModel? nearestCheckpoint;
      double? nearestDistance;

      // Find nearest checkpoint
      for (final checkpoint in _checkpoints) {
        final distance = Geolocator.distanceBetween(
          event.currentPosition.latitude,
          event.currentPosition.longitude,
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

        if (isWithinRange) {
          emit(CheckpointProximityDetected(
            checkpoint: nearestCheckpoint,
            distance: nearestDistance,
            isWithinCompletionRange: isWithinRange,
          ));
        }
      }
    } catch (e) {
      emit(CheckpointError(
        message: 'Failed to check checkpoint proximity: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCompleteCheckpoint(
    CompleteCheckpoint event,
    Emitter<CheckpointState> emit,
  ) async {
    if (_guardId == null || _rosterUserId == null) {
      emit(const CheckpointError(
        message: 'Guard or roster user not initialized',
      ));
      return;
    }

    try {
      // Check if checkpoint is within completion range
      final distance = Geolocator.distanceBetween(
        event.position.latitude,
        event.position.longitude,
        event.checkpoint.latitude,
        event.checkpoint.longitude,
      );

      if (distance > AppConstants.geofenceRadiusMeters) {
        emit(CheckpointError(
          message: 'Too far from checkpoint to complete (${distance.toStringAsFixed(1)}m away)',
        ));
        return;
      }

      // Create perimeter check record
      final perimeterCheck = PerimeterCheckModel(
        passTime: event.passTime ?? DateTime.now(),
        guardId: _guardId!,
        rosterUserId: _rosterUserId!,
        sitePerimeterId: event.checkpoint.sitePerimeterId,
        checkpointId: event.checkpoint.id,
      );

      // Store perimeter check locally
      await _offlineStorage.storePerimeterCheck(perimeterCheck);

      // Update completion status
      _completionStatus[event.checkpoint.id] = true;
      _completionTimes[event.checkpoint.id] = DateTime.now();

      final completedCount = _completionStatus.values.where((completed) => completed).length;
      final progressPercentage = (_checkpoints.length > 0) 
          ? (completedCount / _checkpoints.length) * 100 
          : 0;
      final isAllCompleted = completedCount == _checkpoints.length;

      CheckPointModel? nextCheckpoint;
      if (_dutyType == 'patrol' && !isAllCompleted) {
        nextCheckpoint = _findNextCheckpoint(event.position);
      }

      emit(CheckpointCompleted(
        checkpoint: event.checkpoint,
        perimeterCheck: perimeterCheck,
        nextCheckpoint: nextCheckpoint,
        progressPercentage: progressPercentage,
        isAllCompleted: isAllCompleted,
      ));

      // Update the initialized state
      if (state is CheckpointsInitialized) {
        final currentState = state as CheckpointsInitialized;
        emit(currentState.copyWith(
          completionStatus: Map.from(_completionStatus),
          completedCheckpoints: completedCount,
          nextCheckpoint: nextCheckpoint,
        ));
      }

    } catch (e) {
      emit(CheckpointError(
        message: 'Failed to complete checkpoint: ${e.toString()}',
      ));
    }
  }

  Future<void> _onGetNextCheckpoint(
    GetNextCheckpoint event,
    Emitter<CheckpointState> emit,
  ) async {
    if (_dutyType != 'patrol' || _checkpoints.isEmpty) return;

    try {
      final nextCheckpoint = _findNextCheckpoint(event.currentPosition);
      
      if (nextCheckpoint != null) {
        final distance = Geolocator.distanceBetween(
          event.currentPosition.latitude,
          event.currentPosition.longitude,
          nextCheckpoint.latitude,
          nextCheckpoint.longitude,
        );

        final bearing = Geolocator.bearingBetween(
          event.currentPosition.latitude,
          event.currentPosition.longitude,
          nextCheckpoint.latitude,
          nextCheckpoint.longitude,
        );

        emit(NextCheckpointCalculated(
          nextCheckpoint: nextCheckpoint,
          distance: distance,
          bearing: bearing,
        ));
      }
    } catch (e) {
      emit(CheckpointError(
        message: 'Failed to calculate next checkpoint: ${e.toString()}',
      ));
    }
  }

  Future<void> _onResetCheckpoints(
    ResetCheckpoints event,
    Emitter<CheckpointState> emit,
  ) async {
    _completionStatus.clear();
    _completionTimes.clear();
    
    for (final checkpoint in _checkpoints) {
      _completionStatus[checkpoint.id] = false;
    }

    if (state is CheckpointsInitialized) {
      final currentState = state as CheckpointsInitialized;
      emit(currentState.copyWith(
        completionStatus: Map.from(_completionStatus),
        completedCheckpoints: 0,
        nextCheckpoint: _checkpoints.isNotEmpty ? _checkpoints.first : null,
      ));
    }
  }

  Future<void> _onUpdateDutyType(
    UpdateDutyType event,
    Emitter<CheckpointState> emit,
  ) async {
    _dutyType = event.dutyType;

    if (state is CheckpointsInitialized) {
      final currentState = state as CheckpointsInitialized;
      
      CheckPointModel? designatedCheckpoint;
      CheckPointModel? nextCheckpoint;

      if (_dutyType == 'static') {
        designatedCheckpoint = _checkpoints.isNotEmpty ? _checkpoints.first : null;
        _designatedCheckpoint = designatedCheckpoint;
      } else {
        nextCheckpoint = _findNextUncompletedCheckpoint();
      }

      emit(currentState.copyWith(
        dutyType: _dutyType,
        designatedCheckpoint: designatedCheckpoint,
        nextCheckpoint: nextCheckpoint,
      ));
    }
  }

  Future<void> _onCheckStaticPosition(
    CheckStaticPosition event,
    Emitter<CheckpointState> emit,
  ) async {
    try {
      final distance = Geolocator.distanceBetween(
        event.currentPosition.latitude,
        event.currentPosition.longitude,
        event.designatedCheckpoint.latitude,
        event.designatedCheckpoint.longitude,
      );

      final isInPosition = distance <= AppConstants.geofenceRadiusMeters;
      final requiresReturn = distance > AppConstants.geofenceRadiusMeters;

      emit(StaticPositionStatus(
        designatedCheckpoint: event.designatedCheckpoint,
        distanceFromPosition: distance,
        isInPosition: isInPosition,
        requiresReturn: requiresReturn,
        lastCheck: DateTime.now(),
      ));

    } catch (e) {
      emit(CheckpointError(
        message: 'Failed to check static position: ${e.toString()}',
      ));
    }
  }

  Future<void> _onGetCheckpointProgress(
    GetCheckpointProgress event,
    Emitter<CheckpointState> emit,
  ) async {
    final completedCount = _completionStatus.values.where((completed) => completed).length;
    final progressPercentage = (_checkpoints.length > 0) 
        ? (completedCount / _checkpoints.length) * 100 
        : 0;

    final completedCheckpoints = _checkpoints.where(
      (checkpoint) => _completionStatus[checkpoint.id] == true,
    ).toList();

    final remainingCheckpoints = _checkpoints.where(
      (checkpoint) => _completionStatus[checkpoint.id] != true,
    ).toList();

    emit(CheckpointProgress(
      completedCheckpoints: completedCount,
      totalCheckpoints: _checkpoints.length,
      progressPercentage: progressPercentage,
      completedCheckpointsList: completedCheckpoints,
      remainingCheckpoints: remainingCheckpoints,
    ));
  }

  // Helper Methods

  CheckPointModel? _findNextCheckpoint(Position currentPosition) {
    // Find nearest uncompleted checkpoint
    CheckPointModel? nearestCheckpoint;
    double? nearestDistance;

    for (final checkpoint in _checkpoints) {
      if (_completionStatus[checkpoint.id] == true) continue;

      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        checkpoint.latitude,
        checkpoint.longitude,
      );

      if (nearestCheckpoint == null || distance < nearestDistance!) {
        nearestCheckpoint = checkpoint;
        nearestDistance = distance;
      }
    }

    return nearestCheckpoint;
  }

  CheckPointModel? _findNextUncompletedCheckpoint() {
    for (final checkpoint in _checkpoints) {
      if (_completionStatus[checkpoint.id] != true) {
        return checkpoint;
      }
    }
    return null;
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }

  // Public getters for external access
  List<CheckPointModel> get checkpoints => List.from(_checkpoints);
  Map<int, bool> get completionStatus => Map.from(_completionStatus);
  Map<int, DateTime> get completionTimes => Map.from(_completionTimes);
  String get dutyType => _dutyType;
  CheckPointModel? get designatedCheckpoint => _designatedCheckpoint;
  
  int get completedCheckpointsCount => 
      _completionStatus.values.where((completed) => completed).length;
  
  double get progressPercentage => (_checkpoints.length > 0) 
      ? (completedCheckpointsCount / _checkpoints.length) * 100 
      : 0;
  
  bool get isAllCheckpointsCompleted => 
      completedCheckpointsCount == _checkpoints.length;

  @override
  Future<void> close() {
    return super.close();
  }
}