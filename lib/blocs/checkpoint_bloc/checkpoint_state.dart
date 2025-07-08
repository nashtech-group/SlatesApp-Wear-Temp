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
}

class CheckpointError extends CheckpointState {
  final BlocErrorInfo errorInfo;

  const CheckpointError({required this.errorInfo});

  @override
  List<Object?> get props => [errorInfo];

  // Convenience getters for backward compatibility
  String get message => errorInfo.message;
  bool get canRetry => errorInfo.canRetry;
  bool get isNetworkError => errorInfo.isNetworkError;
  ErrorType get errorType => errorInfo.type;
}
