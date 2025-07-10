part of 'roster_bloc.dart';

abstract class RosterEvent extends Equatable {
  const RosterEvent();

  @override
  List<Object?> get props => [];
}

/// Load roster data for a specific guard
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

/// Load roster data with pagination
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

/// Submit comprehensive guard duty data
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

/// Sync pending submissions
class SyncPendingSubmissions extends RosterEvent {
  const SyncPendingSubmissions();
}

/// Force sync all data
class ForceSyncAll extends RosterEvent {
  const ForceSyncAll();
}

/// Clear sync history
class ClearSyncHistory extends RosterEvent {
  const ClearSyncHistory();
}

/// Retry failed submissions
class RetryFailedSubmissions extends RosterEvent {
  const RetryFailedSubmissions();
}

/// Clean old sync data
class CleanOldSyncData extends RosterEvent {
  const CleanOldSyncData();
}

/// Get current sync status
class GetSyncStatus extends RosterEvent {
  const GetSyncStatus();
}

/// Get comprehensive sync report
class GetSyncReport extends RosterEvent {
  const GetSyncReport();
}

/// Get storage usage information
class GetStorageUsage extends RosterEvent {
  const GetStorageUsage();
}

/// Clear roster cache
class ClearRosterCache extends RosterEvent {
  const ClearRosterCache();
}

/// Get today's roster status for a guard
class GetTodaysRosterStatus extends RosterEvent {
  final int guardId;

  const GetTodaysRosterStatus({required this.guardId});

  @override
  List<Object?> get props => [guardId];
}

/// Get upcoming duties for a guard
class GetUpcomingDuties extends RosterEvent {
  final int guardId;

  const GetUpcomingDuties({required this.guardId});

  @override
  List<Object?> get props => [guardId];
}

/// Get current active duty for a guard
class GetCurrentActiveDuty extends RosterEvent {
  final int guardId;

  const GetCurrentActiveDuty({required this.guardId});

  @override
  List<Object?> get props => [guardId];
}

/// Refresh roster data without showing loading state
class RefreshRosterData extends RosterEvent {
  final int guardId;

  const RefreshRosterData({required this.guardId});

  @override
  List<Object?> get props => [guardId];
}

/// Clear current roster error state (following AuthBloc pattern)
class ClearRosterError extends RosterEvent {
  const ClearRosterError();
}