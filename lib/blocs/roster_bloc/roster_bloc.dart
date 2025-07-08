import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:slates_app_wear/data/models/api_error_model.dart';
import 'package:slates_app_wear/data/models/sync/sync_result.dart';
import 'package:slates_app_wear/data/models/roster/roster_response_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_response_model.dart';
import 'package:slates_app_wear/data/models/roster/guard_movement_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_update_model.dart';
import 'package:slates_app_wear/data/models/sites/perimeter_check_model.dart';
import 'package:slates_app_wear/data/models/sites/site_model.dart';
import 'package:slates_app_wear/data/repositories/roster_repository/roster_repository.dart';

part 'roster_event.dart';
part 'roster_state.dart';

class RosterBloc extends Bloc<RosterEvent, RosterState> {
  final RosterRepository _rosterRepository;
  Timer? _refreshTimer;

  RosterBloc({required RosterRepository rosterRepository})
      : _rosterRepository = rosterRepository,
        super(RosterInitial()) {
    // Initialize repository
    _rosterRepository.initialize();

    // Event handlers
    on<LoadRosterData>(_onLoadRosterData);
    on<LoadRosterDataPaginated>(_onLoadRosterDataPaginated);
    on<SubmitComprehensiveGuardDuty>(_onSubmitComprehensiveGuardDuty);
    on<SyncPendingSubmissions>(_onSyncPendingSubmissions);
    on<ForceSyncAll>(_onForceSyncAll);
    on<ClearSyncHistory>(_onClearSyncHistory);
    on<RetryFailedSubmissions>(_onRetryFailedSubmissions);
    on<CleanOldSyncData>(_onCleanOldSyncData);
    on<GetSyncStatus>(_onGetSyncStatus);
    on<GetSyncReport>(_onGetSyncReport);
    on<GetStorageUsage>(_onGetStorageUsage);
    on<ClearRosterCache>(_onClearRosterCache);
    on<GetTodaysRosterStatus>(_onGetTodaysRosterStatus);
    on<GetUpcomingDuties>(_onGetUpcomingDuties);
    on<GetCurrentActiveDuty>(_onGetCurrentActiveDuty);
    on<RefreshRosterData>(_onRefreshRosterData);

    // Set up periodic refresh
    _setupPeriodicRefresh();
  }

  void _setupPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      if (state is RosterLoaded) {
        final currentState = state as RosterLoaded;
        if (currentState.currentActiveDuty != null) {
          add(RefreshRosterData(
              guardId: currentState.currentActiveDuty!.guardId));
        }
      }
    });
  }

  Future<void> _onLoadRosterData(
    LoadRosterData event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Loading roster data...'));

      final rosterResponse = await _rosterRepository.getRosterData(
        guardId: event.guardId,
        fromDate: event.fromDate,
      );

      final sites = _rosterRepository.extractSitesFromRoster(rosterResponse);
      final currentActiveDuty =
          _rosterRepository.getCurrentActiveDuty(rosterResponse);
      final upcomingDuties =
          _rosterRepository.getUpcomingDuties(rosterResponse);

      emit(RosterLoaded(
        rosterResponse: rosterResponse,
        sites: sites,
        currentActiveDuty: currentActiveDuty,
        upcomingDuties: upcomingDuties,
        lastUpdated: DateTime.now(),
      ));
    } on ApiErrorModel catch (e) {
      emit(RosterError(
        message: e.message,
        error: e,
        isNetworkError:
            e.message.contains('connection') || e.message.contains('network'),
      ));
    } catch (e) {
      emit(RosterError(
        message: 'Failed to load roster data: ${e.toString()}',
        isNetworkError: e.toString().contains('connection'),
      ));
    }
  }

  Future<void> _onLoadRosterDataPaginated(
    LoadRosterDataPaginated event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Loading roster data...'));

      final rosterResponse = await _rosterRepository.getRosterDataPaginated(
        guardId: event.guardId,
        fromDate: event.fromDate,
        page: event.page,
        perPage: event.perPage,
      );

      final sites = _rosterRepository.extractSitesFromRoster(rosterResponse);
      final currentActiveDuty =
          _rosterRepository.getCurrentActiveDuty(rosterResponse);
      final upcomingDuties =
          _rosterRepository.getUpcomingDuties(rosterResponse);

      emit(RosterLoaded(
        rosterResponse: rosterResponse,
        sites: sites,
        currentActiveDuty: currentActiveDuty,
        upcomingDuties: upcomingDuties,
        lastUpdated: DateTime.now(),
      ));
    } on ApiErrorModel catch (e) {
      emit(RosterError(
        message: e.message,
        error: e,
        isNetworkError:
            e.message.contains('connection') || e.message.contains('network'),
      ));
    } catch (e) {
      emit(RosterError(
        message: 'Failed to load roster data: ${e.toString()}',
        isNetworkError: e.toString().contains('connection'),
      ));
    }
  }

  Future<void> _onSubmitComprehensiveGuardDuty(
    SubmitComprehensiveGuardDuty event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Submitting guard duty data...'));

      final response = await _rosterRepository.submitComprehensiveGuardDuty(
        rosterUpdates: event.rosterUpdates,
        movements: event.movements,
        perimeterChecks: event.perimeterChecks,
      );

      emit(RosterSubmissionSuccess(
        response: response,
        message: response.message,
      ));
    } on ApiErrorModel catch (e) {
      emit(RosterError(
        message: e.message,
        error: e,
        isNetworkError:
            e.message.contains('connection') || e.message.contains('network'),
      ));
    } catch (e) {
      emit(RosterError(
        message: 'Failed to submit guard duty data: ${e.toString()}',
        isNetworkError: e.toString().contains('connection'),
      ));
    }
  }

  Future<void> _onSyncPendingSubmissions(
    SyncPendingSubmissions event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Syncing pending submissions...'));

      final success = await _rosterRepository.syncPendingSubmissions();
      final syncStatus = await _rosterRepository.getSyncStatus();

      if (success) {
        emit(RosterSyncSuccess(
          message: 'All pending submissions synced successfully',
          syncStatus: syncStatus,
        ));
      } else {
        emit(const RosterError(
          message: 'Some submissions failed to sync. Will retry automatically.',
          canRetry: true,
        ));
      }
    } catch (e) {
      emit(RosterError(
        message: 'Failed to sync pending submissions: ${e.toString()}',
        isNetworkError: e.toString().contains('connection'),
      ));
    }
  }

  Future<void> _onForceSyncAll(
    ForceSyncAll event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Force syncing all data...'));

      final result = await _rosterRepository.forceSyncAll();

      if (result.success) {
        final syncStatus = await _rosterRepository.getSyncStatus();
        emit(RosterSyncDetailedSuccess(
          syncResult: result,
          message: 'Force sync completed successfully',
          syncStatus: syncStatus,
        ));
      } else {
        emit(RosterSyncDetailedError(
          syncResult: result,
          message: result.message,
          canRetry: true,
        ));
      }
    } catch (e) {
      emit(RosterError(
        message: 'Failed to force sync: ${e.toString()}',
        isNetworkError: e.toString().contains('connection'),
      ));
    }
  }

  Future<void> _onClearSyncHistory(
    ClearSyncHistory event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Clearing sync history...'));

      final result = await _rosterRepository.clearSyncHistory();

      if (result.success) {
        emit(RosterSyncDetailedSuccess(
          syncResult: result,
          message: 'Sync history cleared successfully',
          syncStatus: await _rosterRepository.getSyncStatus(),
        ));
      } else {
        emit(RosterSyncDetailedError(
          syncResult: result,
          message: result.message,
          canRetry: false,
        ));
      }
    } catch (e) {
      emit(RosterError(
        message: 'Failed to clear sync history: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRetryFailedSubmissions(
    RetryFailedSubmissions event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Retrying failed submissions...'));

      final result = await _rosterRepository.retryFailedSubmissions();

      if (result.success) {
        final syncStatus = await _rosterRepository.getSyncStatus();
        emit(RosterSyncDetailedSuccess(
          syncResult: result,
          message: 'Failed submissions retried successfully',
          syncStatus: syncStatus,
        ));
      } else {
        emit(RosterSyncDetailedError(
          syncResult: result,
          message: result.message,
          canRetry: true,
        ));
      }
    } catch (e) {
      emit(RosterError(
        message: 'Failed to retry submissions: ${e.toString()}',
        isNetworkError: e.toString().contains('connection'),
      ));
    }
  }

  Future<void> _onCleanOldSyncData(
    CleanOldSyncData event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Cleaning old sync data...'));

      final result = await _rosterRepository.cleanOldSyncData();

      if (result.success) {
        emit(RosterSyncDetailedSuccess(
          syncResult: result,
          message: 'Old sync data cleaned successfully',
          syncStatus: await _rosterRepository.getSyncStatus(),
        ));
      } else {
        emit(RosterSyncDetailedError(
          syncResult: result,
          message: result.message,
          canRetry: true,
        ));
      }
    } catch (e) {
      emit(RosterError(
        message: 'Failed to clean old sync data: ${e.toString()}',
      ));
    }
  }

  Future<void> _onGetSyncStatus(
    GetSyncStatus event,
    Emitter<RosterState> emit,
  ) async {
    try {
      final syncStatus = await _rosterRepository.getSyncStatus();

      emit(RosterSyncSuccess(
        message: 'Sync status retrieved',
        syncStatus: syncStatus,
      ));
    } catch (e) {
      emit(RosterError(
        message: 'Failed to get sync status: ${e.toString()}',
      ));
    }
  }

  Future<void> _onGetSyncReport(
    GetSyncReport event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Generating sync report...'));

      final report = await _rosterRepository.getSyncReport();

      emit(RosterSyncReportLoaded(
        report: report,
        message: 'Sync report generated successfully',
      ));
    } catch (e) {
      emit(RosterError(
        message: 'Failed to generate sync report: ${e.toString()}',
      ));
    }
  }

  Future<void> _onGetStorageUsage(
    GetStorageUsage event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Calculating storage usage...'));

      final usage = await _rosterRepository.getStorageUsage();

      emit(RosterStorageUsageLoaded(
        usage: usage,
        message: 'Storage usage calculated successfully',
      ));
    } catch (e) {
      emit(RosterError(
        message: 'Failed to get storage usage: ${e.toString()}',
      ));
    }
  }

  Future<void> _onClearRosterCache(
    ClearRosterCache event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Clearing roster cache...'));

      await _rosterRepository.clearRosterCache();

      emit(const RosterCacheCleared(
        message: 'Roster cache cleared successfully',
      ));
    } catch (e) {
      emit(RosterError(
        message: 'Failed to clear roster cache: ${e.toString()}',
      ));
    }
  }

  Future<void> _onGetTodaysRosterStatus(
    GetTodaysRosterStatus event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Loading today\'s roster status...'));

      final rosterResponse = await _rosterRepository.getTodaysRosterStatus(
        guardId: event.guardId,
      );

      final sites = _rosterRepository.extractSitesFromRoster(rosterResponse);
      final currentActiveDuty =
          _rosterRepository.getCurrentActiveDuty(rosterResponse);
      final upcomingDuties =
          _rosterRepository.getUpcomingDuties(rosterResponse);

      emit(RosterLoaded(
        rosterResponse: rosterResponse,
        sites: sites,
        currentActiveDuty: currentActiveDuty,
        upcomingDuties: upcomingDuties,
        lastUpdated: DateTime.now(),
      ));
    } on ApiErrorModel catch (e) {
      emit(RosterError(
        message: e.message,
        error: e,
        isNetworkError:
            e.message.contains('connection') || e.message.contains('network'),
      ));
    } catch (e) {
      emit(RosterError(
        message: 'Failed to load today\'s roster status: ${e.toString()}',
        isNetworkError: e.toString().contains('connection'),
      ));
    }
  }

  Future<void> _onGetUpcomingDuties(
    GetUpcomingDuties event,
    Emitter<RosterState> emit,
  ) async {
    try {
      emit(const RosterLoading(message: 'Loading upcoming duties...'));

      final rosterResponse = await _rosterRepository.getUpcomingRosterDuties(
        guardId: event.guardId,
      );

      final sites = _rosterRepository.extractSitesFromRoster(rosterResponse);
      final currentActiveDuty =
          _rosterRepository.getCurrentActiveDuty(rosterResponse);
      final upcomingDuties =
          _rosterRepository.getUpcomingDuties(rosterResponse);

      emit(RosterLoaded(
        rosterResponse: rosterResponse,
        sites: sites,
        currentActiveDuty: currentActiveDuty,
        upcomingDuties: upcomingDuties,
        lastUpdated: DateTime.now(),
      ));
    } on ApiErrorModel catch (e) {
      emit(RosterError(
        message: e.message,
        error: e,
        isNetworkError:
            e.message.contains('connection') || e.message.contains('network'),
      ));
    } catch (e) {
      emit(RosterError(
        message: 'Failed to load upcoming duties: ${e.toString()}',
        isNetworkError: e.toString().contains('connection'),
      ));
    }
  }

  Future<void> _onGetCurrentActiveDuty(
    GetCurrentActiveDuty event,
    Emitter<RosterState> emit,
  ) async {
    try {
      final rosterResponse = await _rosterRepository.getTodaysRosterStatus(
        guardId: event.guardId,
      );

      final currentActiveDuty =
          _rosterRepository.getCurrentActiveDuty(rosterResponse);

      if (state is RosterLoaded) {
        final currentState = state as RosterLoaded;
        emit(currentState.copyWith(
          currentActiveDuty: currentActiveDuty,
          lastUpdated: DateTime.now(),
        ));
      } else {
        final sites = _rosterRepository.extractSitesFromRoster(rosterResponse);
        final upcomingDuties =
            _rosterRepository.getUpcomingDuties(rosterResponse);

        emit(RosterLoaded(
          rosterResponse: rosterResponse,
          sites: sites,
          currentActiveDuty: currentActiveDuty,
          upcomingDuties: upcomingDuties,
          lastUpdated: DateTime.now(),
        ));
      }
    } on ApiErrorModel catch (e) {
      emit(RosterError(
        message: e.message,
        error: e,
        isNetworkError:
            e.message.contains('connection') || e.message.contains('network'),
      ));
    } catch (e) {
      emit(RosterError(
        message: 'Failed to get current active duty: ${e.toString()}',
        isNetworkError: e.toString().contains('connection'),
      ));
    }
  }

  Future<void> _onRefreshRosterData(
    RefreshRosterData event,
    Emitter<RosterState> emit,
  ) async {
    try {
      // Don't show loading state for refresh to avoid UI flicker
      final rosterResponse = await _rosterRepository.getRosterData(
        guardId: event.guardId,
      );

      final sites = _rosterRepository.extractSitesFromRoster(rosterResponse);
      final currentActiveDuty =
          _rosterRepository.getCurrentActiveDuty(rosterResponse);
      final upcomingDuties =
          _rosterRepository.getUpcomingDuties(rosterResponse);

      emit(RosterLoaded(
        rosterResponse: rosterResponse,
        sites: sites,
        currentActiveDuty: currentActiveDuty,
        upcomingDuties: upcomingDuties,
        lastUpdated: DateTime.now(),
      ));
    } on ApiErrorModel catch (e) {
      // For refresh, we might want to keep the previous state and just show a snackbar
      if (state is RosterLoaded) {
        log('Refresh failed: ${e.message}');
        // You could emit a specific refresh error state here if needed
      } else {
        emit(RosterError(
          message: e.message,
          error: e,
          isNetworkError:
              e.message.contains('connection') || e.message.contains('network'),
        ));
      }
    } catch (e) {
      if (state is RosterLoaded) {
        log('Refresh failed: ${e.toString()}');
      } else {
        emit(RosterError(
          message: 'Failed to refresh roster data: ${e.toString()}',
          isNetworkError: e.toString().contains('connection'),
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _rosterRepository.dispose();
    return super.close();
  }
}
