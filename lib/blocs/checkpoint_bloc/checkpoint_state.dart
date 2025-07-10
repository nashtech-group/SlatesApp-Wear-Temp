 part of 'checkpoint_bloc.dart';

abstract class CheckpointState extends Equatable {
  const CheckpointState();

  @override
  List<Object?> get props => [];
}

class CheckpointInitial extends CheckpointState {}

class CheckpointLoading extends CheckpointState {
  final String message;

  const CheckpointLoading({required this.message});

  @override
  List<Object?> get props => [message];
}

class CheckpointsInitialized extends CheckpointState {
  final List<CheckPointModel> checkpoints;
  final String dutyType;
  final CheckPointModel? designatedCheckpoint; // For static duty
  final CheckPointModel? nextCheckpoint; // For patrol duty
  final Map<int, bool> completionStatus;
  final int totalCheckpoints;
  final int completedCheckpoints;

  const CheckpointsInitialized({
    required this.checkpoints,
    required this.dutyType,
    this.designatedCheckpoint,
    this.nextCheckpoint,
    required this.completionStatus,
    required this.totalCheckpoints,
    required this.completedCheckpoints,
  });

  @override
  List<Object?> get props => [
        checkpoints,
        dutyType,
        designatedCheckpoint,
        nextCheckpoint,
        completionStatus,
        totalCheckpoints,
        completedCheckpoints,
      ];

  CheckpointsInitialized copyWith({
    List<CheckPointModel>? checkpoints,
    String? dutyType,
    CheckPointModel? designatedCheckpoint,
    CheckPointModel? nextCheckpoint,
    Map<int, bool>? completionStatus,
    int? totalCheckpoints,
    int? completedCheckpoints,
  }) {
    return CheckpointsInitialized(
      checkpoints: checkpoints ?? this.checkpoints,
      dutyType: dutyType ?? this.dutyType,
      designatedCheckpoint: designatedCheckpoint ?? this.designatedCheckpoint,
      nextCheckpoint: nextCheckpoint ?? this.nextCheckpoint,
      completionStatus: completionStatus ?? this.completionStatus,
      totalCheckpoints: totalCheckpoints ?? this.totalCheckpoints,
      completedCheckpoints: completedCheckpoints ?? this.completedCheckpoints,
    );
  }

  double get progressPercentage => 
      totalCheckpoints > 0 ? (completedCheckpoints / totalCheckpoints) * 100 : 0;

  bool get isStaticDuty => dutyType == 'static';
  bool get isPatrolDuty => dutyType == 'patrol';
  bool get hasCheckpoints => checkpoints.isNotEmpty;
  bool get isCompleted => completedCheckpoints == totalCheckpoints && totalCheckpoints > 0;
  
  List<CheckPointModel> get completedCheckpointsList => 
      checkpoints.where((cp) => completionStatus[cp.id] == true).toList();
  
  List<CheckPointModel> get remainingCheckpoints => 
      checkpoints.where((cp) => completionStatus[cp.id] != true).toList();
}

class CheckpointProximityDetected extends CheckpointState {
  final CheckPointModel checkpoint;
  final double distance;
  final bool isWithinCompletionRange;

  const CheckpointProximityDetected({
    required this.checkpoint,
    required this.distance,
    required this.isWithinCompletionRange,
  });

  @override
  List<Object?> get props => [checkpoint, distance, isWithinCompletionRange];

  String get formattedDistance => '${distance.toStringAsFixed(1)}m';
  bool get canComplete => isWithinCompletionRange;
}

class CheckpointCompleted extends CheckpointState {
  final CheckPointModel checkpoint;
  final PerimeterCheckModel perimeterCheck;
  final CheckPointModel? nextCheckpoint;
  final double progressPercentage;
  final bool isAllCompleted;

  const CheckpointCompleted({
    required this.checkpoint,
    required this.perimeterCheck,
    this.nextCheckpoint,
    required this.progressPercentage,
    required this.isAllCompleted,
  });

  @override
  List<Object?> get props => [
        checkpoint,
        perimeterCheck,
        nextCheckpoint,
        progressPercentage,
        isAllCompleted,
      ];

  String get formattedProgress => '${progressPercentage.toStringAsFixed(1)}%';
  bool get hasNextCheckpoint => nextCheckpoint != null;
}

class StaticPositionStatus extends CheckpointState {
  final CheckPointModel designatedCheckpoint;
  final double distanceFromPosition;
  final bool isInPosition;
  final bool requiresReturn;
  final DateTime lastCheck;

  const StaticPositionStatus({
    required this.designatedCheckpoint,
    required this.distanceFromPosition,
    required this.isInPosition,
    required this.requiresReturn,
    required this.lastCheck,
  });

  @override
  List<Object?> get props => [
        designatedCheckpoint,
        distanceFromPosition,
        isInPosition,
        requiresReturn,
        lastCheck,
      ];

  String get formattedDistance => '${distanceFromPosition.toStringAsFixed(1)}m';
  String get positionStatus => isInPosition ? 'In Position' : 'Out of Position';
  String get formattedLastCheck => 
      '${lastCheck.hour.toString().padLeft(2, '0')}:${lastCheck.minute.toString().padLeft(2, '0')}';
}

class NextCheckpointCalculated extends CheckpointState {
  final CheckPointModel nextCheckpoint;
  final double distance;
  final double bearing;

  const NextCheckpointCalculated({
    required this.nextCheckpoint,
    required this.distance,
    required this.bearing,
  });

  @override
  List<Object?> get props => [nextCheckpoint, distance, bearing];

  String get formattedDistance => '${distance.toStringAsFixed(1)}m';
  String get formattedBearing => '${bearing.toStringAsFixed(0)}°';
  String get compassDirection => _getCompassDirection(bearing);

  String _getCompassDirection(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }
}

class CheckpointProgress extends CheckpointState {
  final int completedCheckpoints;
  final int totalCheckpoints;
  final double progressPercentage;
  final List<CheckPointModel> completedCheckpointsList;
  final List<CheckPointModel> remainingCheckpoints;

  const CheckpointProgress({
    required this.completedCheckpoints,
    required this.totalCheckpoints,
    required this.progressPercentage,
    required this.completedCheckpointsList,
    required this.remainingCheckpoints,
  });

  @override
  List<Object?> get props => [
        completedCheckpoints,
        totalCheckpoints,
        progressPercentage,
        completedCheckpointsList,
        remainingCheckpoints,
      ];

  String get formattedProgress => '${progressPercentage.toStringAsFixed(1)}%';
  String get progressText => '$completedCheckpoints of $totalCheckpoints completed';
  bool get isCompleted => completedCheckpoints == totalCheckpoints && totalCheckpoints > 0;
  bool get hasRemaining => remainingCheckpoints.isNotEmpty;
}

class CheckpointError extends CheckpointState with ErrorStateMixin {
  @override
  final BlocErrorInfo errorInfo;

  const CheckpointError({required this.errorInfo});

  @override
  List<Object?> get props => [errorInfo];

  /// Create copy with updated error info
  CheckpointError copyWith({BlocErrorInfo? errorInfo}) {
    return CheckpointError(errorInfo: errorInfo ?? this.errorInfo);
  }
}