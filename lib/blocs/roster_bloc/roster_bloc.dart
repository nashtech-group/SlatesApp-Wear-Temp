import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:slates_app_wear/data/models/sync/sync_result.dart';
import 'package:slates_app_wear/data/models/roster/roster_response_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_response_model.dart';
import 'package:slates_app_wear/data/models/roster/guard_movement_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_update_model.dart';
import 'package:slates_app_wear/data/models/sites/perimeter_check_model.dart';
import 'package:slates_app_wear/data/models/sites/site_model.dart';
import 'package:slates_app_wear/data/repositories/roster_repository/roster_repository.dart';
import '../../core/error/bloc_error_mixin.dart';
import '../../core/error/error_handler.dart';

part 'roster_event.dart';
part 'roster_state.dart';

class RosterBloc extends Bloc<RosterEvent, RosterState>
    with BlocErrorMixin<RosterEvent, RosterState> {
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

  @override
  RosterState createDefaultErrorState(BlocErrorInfo errorInfo) {
    return RosterError(errorInfo: errorInfo);
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
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Load Roster Data',
        additionalData: {
          'guardId': event.guardId,
          'fromDate': event.fromDate,
        },
      );
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
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Load Paginated Roster Data',
        additionalData: {
          'guardId': event.guardId,
          'fromDate': event.fromDate,
          'page': event.page,
          'perPage': event.perPage,
        },
      );
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
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Submit Guard Duty',
        additionalData: {
          'rosterUpdatesCount': event.rosterUpdates?.length,
          'movementsCount': event.movements?.length,
          'perimeterChecksCount': event.perimeterChecks?.length,
        },
      );
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
        handleError(
          'Some submissions failed to sync',
          emit,
          context: 'Sync Pending Submissions',
          customErrorState: (errorInfo) => RosterError(
            errorInfo: errorInfo.copyWith(
              message:
                  'Some submissions failed to sync. Will retry automatically.',
              canRetry: true,
            ),
          ),
        );
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Sync Pending Submissions',
      );
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
          errorInfo: BlocErrorInfo(
            type: ErrorType.server,
            message: result.message,
            canRetry: true,
          ),
        ));
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Force Sync All',
      );
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
          errorInfo: BlocErrorInfo(
            type: ErrorType.unknown,
            message: result.message,
            canRetry: false,
          ),
        ));
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Clear Sync History',
      );
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
          errorInfo: BlocErrorInfo(
            type: ErrorType.server,
            message: result.message,
            canRetry: true,
          ),
        ));
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Retry Failed Submissions',
      );
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
          errorInfo: BlocErrorInfo(
            type: ErrorType.unknown,
            message: result.message,
            canRetry: true,
          ),
        ));
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Clean Old Sync Data',
      );
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
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Get Sync Status',
      );
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
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Get Sync Report',
      );
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
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Get Storage Usage',
      );
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
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Clear Roster Cache',
      );
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
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Get Today\'s Roster Status',
        additionalData: {'guardId': event.guardId},
      );
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
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Get Upcoming Duties',
        additionalData: {'guardId': event.guardId},
      );
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
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Get Current Active Duty',
        additionalData: {'guardId': event.guardId},
      );
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
    } catch (error) {
      // For refresh, we might want to keep the previous state and just log the error
      if (state is RosterLoaded) {
        final errorInfo = processError(
          error,
          context: 'Refresh Roster Data',
          additionalData: {'guardId': event.guardId},
        );
        log('Refresh failed: ${errorInfo.message}');
        // Optionally emit a specific refresh error state here if needed
      } else {
        handleError(
          error,
          emit,
          context: 'Refresh Roster Data',
          additionalData: {'guardId': event.guardId},
        );
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
