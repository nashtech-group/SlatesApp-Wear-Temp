import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:slates_app_wear/core/error/error_state_mixin.dart';
import 'package:slates_app_wear/data/models/guard/guard_position_model.dart';
import 'package:slates_app_wear/data/models/sites/checkpoint_model.dart';
import 'package:slates_app_wear/data/models/sites/perimeter_check_model.dart';
import 'package:slates_app_wear/data/models/sites/site_model.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/services/offline_storage_service.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/error_state_factory.dart';

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

  /// Centralized error handling for checkpoint operations
  CheckpointState _handleCheckpointError(
    dynamic error, {
    required String context,
    Map<String, dynamic>? additionalData,
  }) {
    final errorInfo = ErrorHandler.handleError(
      error,
      context: 'CheckpointBloc.$context',
      additionalData: additionalData,
    );

    return CheckpointError(errorInfo: errorInfo);
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

    } catch (error) {
      emit(_handleCheckpointError(
        error,
        context: 'initializeCheckpoints',
        additionalData: {
          'siteId': event.site.id,
          'guardId': event.guardId,
          'dutyType': event.guardPosition.isStaticGuard ? 'static' : 'patrol',
        },
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
    } catch (error) {
      emit(_handleCheckpointError(
        error,
        context: 'checkProximityToCheckpoints',
        additionalData: {
          'latitude': event.currentPosition.latitude,
          'longitude': event.currentPosition.longitude,
          'checkpointsCount': _checkpoints.length,
        },
      ));
    }
  }

  Future<void> _onCompleteCheckpoint(
    CompleteCheckpoint event,
    Emitter<CheckpointState> emit,
  ) async {
    if (_guardId == null || _rosterUserId == null) {
      emit(_handleCheckpointError(
        'Guard or roster user not initialized',
        context: 'completeCheckpoint',
        additionalData: {
          'guardIdNull': _guardId == null,
          'rosterUserIdNull': _rosterUserId == null,
        },
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
        final errorInfo = ErrorHandler.handleError(
          'Too far from checkpoint',
          context: 'CheckpointBloc.completeCheckpoint',
          additionalData: {
            'distance': distance,
            'requiredDistance': AppConstants.geofenceRadiusMeters,
          },
        );

        emit(CheckpointError(
          errorInfo: errorInfo.copyWith(
            message: 'Too far from checkpoint to complete (${distance.toStringAsFixed(1)}m away)',
            canRetry: false,
          ),
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
      final progressPercentage = (_checkpoints.isNotEmpty) 
          ? (completedCount / _checkpoints.length) * 100 
          : 0.0;
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

    } catch (error) {
      emit(_handleCheckpointError(
        error,
        context: 'completeCheckpoint',
        additionalData: {
          'checkpointId': event.checkpoint.id,
          'guardId': _guardId,
          'rosterUserId': _rosterUserId,
        },
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
    } catch (error) {
      emit(_handleCheckpointError(
        error,
        context: 'getNextCheckpoint',
        additionalData: {
          'latitude': event.currentPosition.latitude,
          'longitude': event.currentPosition.longitude,
          'dutyType': _dutyType,
        },
      ));
    }
  }

  Future<void> _onResetCheckpoints(
    ResetCheckpoints event,
    Emitter<CheckpointState> emit,
  ) async {
    try {
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
    } catch (error) {
      emit(_handleCheckpointError(
        error,
        context: 'resetCheckpoints',
        additionalData: {'checkpointsCount': _checkpoints.length},
      ));
    }
  }

  Future<void> _onUpdateDutyType(
    UpdateDutyType event,
    Emitter<CheckpointState> emit,
  ) async {
    try {
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
    } catch (error) {
      emit(_handleCheckpointError(
        error,
        context: 'updateDutyType',
        additionalData: {'dutyType': event.dutyType},
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

    } catch (error) {
      emit(_handleCheckpointError(
        error,
        context: 'checkStaticPosition',
        additionalData: {
          'checkpointId': event.designatedCheckpoint.id,
          'latitude': event.currentPosition.latitude,
          'longitude': event.currentPosition.longitude,
        },
      ));
    }
  }

  Future<void> _onGetCheckpointProgress(
    GetCheckpointProgress event,
    Emitter<CheckpointState> emit,
  ) async {
    try {
      final completedCount = _completionStatus.values.where((completed) => completed).length;
      final progressPercentage = (_checkpoints.isNotEmpty) 
          ? (completedCount / _checkpoints.length) * 100 
          : 0.0;

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
    } catch (error) {
      emit(_handleCheckpointError(
        error,
        context: 'getCheckpointProgress',
        additionalData: {'checkpointsCount': _checkpoints.length},
      ));
    }
  }

  // ===== HELPER METHODS =====

  CheckPointModel? _findNextCheckpoint(Position currentPosition) {
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

  // ===== PUBLIC GETTERS =====

  List<CheckPointModel> get checkpoints => List.from(_checkpoints);
  Map<int, bool> get completionStatus => Map.from(_completionStatus);
  Map<int, DateTime> get completionTimes => Map.from(_completionTimes);
  String get dutyType => _dutyType;
  CheckPointModel? get designatedCheckpoint => _designatedCheckpoint;
  
  int get completedCheckpointsCount => 
      _completionStatus.values.where((completed) => completed).length;
  
  double get progressPercentage => (_checkpoints.isNotEmpty) 
      ? (completedCheckpointsCount / _checkpoints.length) * 100 
      : 0;
  
  bool get isAllCheckpointsCompleted => 
      completedCheckpointsCount == _checkpoints.length;

  /// Get current checkpoint status for UI
  Map<String, dynamic> get checkpointSummary {
    return {
      'totalCheckpoints': _checkpoints.length,
      'completedCheckpoints': completedCheckpointsCount,
      'remainingCheckpoints': _checkpoints.length - completedCheckpointsCount,
      'progressPercentage': progressPercentage,
      'dutyType': _dutyType,
      'isAllCompleted': isAllCheckpointsCompleted,
      'hasDesignatedCheckpoint': _designatedCheckpoint != null,
    };
  }
}