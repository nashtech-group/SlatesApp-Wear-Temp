part of 'checkpoint_bloc.dart';

abstract class CheckpointEvent extends Equatable {
  const CheckpointEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCheckpoints extends CheckpointEvent {
  final SiteModel site;
  final GuardPositionModel guardPosition;
  final int guardId;
  final int rosterUserId;

  const InitializeCheckpoints({
    required this.site,
    required this.guardPosition,
    required this.guardId,
    required this.rosterUserId,
  });

  @override
  List<Object?> get props => [site, guardPosition, guardId, rosterUserId];
}

class CheckProximityToCheckpoints extends CheckpointEvent {
  final Position currentPosition;

  const CheckProximityToCheckpoints({required this.currentPosition});

  @override
  List<Object?> get props => [currentPosition];
}

class CompleteCheckpoint extends CheckpointEvent {
  final CheckPointModel checkpoint;
  final Position position;
  final DateTime? passTime;

  const CompleteCheckpoint({
    required this.checkpoint,
    required this.position,
    this.passTime,
  });

  @override
  List<Object?> get props => [checkpoint, position, passTime];
}

class GetNextCheckpoint extends CheckpointEvent {
  final Position currentPosition;

  const GetNextCheckpoint({required this.currentPosition});

  @override
  List<Object?> get props => [currentPosition];
}

class ResetCheckpoints extends CheckpointEvent {
  const ResetCheckpoints();
}

class UpdateDutyType extends CheckpointEvent {
  final String dutyType; // 'patrol' or 'static'

  const UpdateDutyType({required this.dutyType});

  @override
  List<Object?> get props => [dutyType];
}

class CheckStaticPosition extends CheckpointEvent {
  final Position currentPosition;
  final CheckPointModel designatedCheckpoint;

  const CheckStaticPosition({
    required this.currentPosition,
    required this.designatedCheckpoint,
  });

  @override
  List<Object?> get props => [currentPosition, designatedCheckpoint];
}

class GetCheckpointProgress extends CheckpointEvent {
  const GetCheckpointProgress();
}