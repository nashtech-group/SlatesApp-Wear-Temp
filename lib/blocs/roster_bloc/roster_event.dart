part of 'roster_bloc.dart';

abstract class RosterEvent extends Equatable {
  const RosterEvent();

  @override
  List<Object?> get props => [];
}
class LoadRosterData extends RosterEvent {
  final int guardId;
  final String? fromDate;
  final bool forceRefresh;

  const LoadRosterData({
    required this.guardId,
    this.fromDate,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [guardId, fromDate, forceRefresh];
}

class LoadRosterDataPaginated extends RosterEvent {
  final int guardId;
  final String? fromDate;
  final int page;
  final int perPage;

  const LoadRosterDataPaginated({
    required this.guardId,
    this.fromDate,
    this.page = 1,
    this.perPage = 15,
  });

  @override
  List<Object?> get props => [guardId, fromDate, page, perPage];
}

class SubmitComprehensiveGuardDuty extends RosterEvent {
  final List<RosterUserUpdateModel>? rosterUpdates;
  final List<GuardMovementModel>? movements;
  final List<PerimeterCheckModel>? perimeterChecks;

  const SubmitComprehensiveGuardDuty({
    this.rosterUpdates,
    this.movements,
    this.perimeterChecks,
  });

  @override
  List<Object?> get props => [rosterUpdates, movements, perimeterChecks];
}

class SubmitRosterUserUpdates extends RosterEvent {
  final List<RosterUserUpdateModel> updates;

  const SubmitRosterUserUpdates({required this.updates});

  @override
  List<Object?> get props => [updates];
}

class SubmitGuardMovements extends RosterEvent {
  final List<GuardMovementModel> movements;

  const SubmitGuardMovements({required this.movements});

  @override
  List<Object?> get props => [movements];
}

class SubmitPerimeterChecks extends RosterEvent {
  final List<PerimeterCheckModel> perimeterChecks;

  const SubmitPerimeterChecks({required this.perimeterChecks});

  @override
  List<Object?> get props => [perimeterChecks];
}

class SyncPendingSubmissions extends RosterEvent {
  const SyncPendingSubmissions();
}

class GetSyncStatus extends RosterEvent {
  const GetSyncStatus();
}

class ClearRosterCache extends RosterEvent {
  const ClearRosterCache();
}

class GetTodaysRosterStatus extends RosterEvent {
  final int guardId;

  const GetTodaysRosterStatus({required this.guardId});

  @override
  List<Object?> get props => [guardId];
}

class GetUpcomingDuties extends RosterEvent {
  final int guardId;

  const GetUpcomingDuties({required this.guardId});

  @override
  List<Object?> get props => [guardId];
}

class GetCurrentActiveDuty extends RosterEvent {
  final int guardId;

  const GetCurrentActiveDuty({required this.guardId});

  @override
  List<Object?> get props => [guardId];
}

class RefreshRosterData extends RosterEvent {
  final int guardId;

  const RefreshRosterData({required this.guardId});

  @override
  List<Object?> get props => [guardId];
}