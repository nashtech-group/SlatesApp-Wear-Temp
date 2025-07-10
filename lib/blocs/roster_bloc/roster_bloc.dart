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
import '../../core/error/error_state_mixin.dart';

part 'roster_event.dart';
part 'roster_state.dart';

class RosterBloc extends Bloc<RosterEvent, RosterState>
    with BlocErrorMixin<RosterEvent, RosterState> {
  final RosterRepository _rosterRepository;
  Timer? _refreshTimer;

  // Current state tracking
  int? _currentGuardId;
  RosterResponseModel? _lastRosterResponse;
  List<SiteModel> _cachedSites = [];

  RosterBloc({required RosterRepository rosterRepository})
      : _rosterRepository = rosterRepository,
        super(const RosterInitial()) {
    
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
    on<ClearRosterError>(_onClearRosterError);

    // Set up periodic refresh
    _setupPeriodicRefresh();
  }

  @override
  RosterState createDefaultErrorState(BlocErrorInfo errorInfo) {
    return RosterError(errorInfo: errorInfo);
  }

  /// Set up periodic refresh for active duties
  void _setupPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      if (state is RosterLoaded && _currentGuardId != null) {
        final currentState = state as RosterLoaded;
        if (currentState.currentActiveDuty != null) {
          add(RefreshRosterData(guardId: _currentGuardId!));
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
      _currentGuardId = event.guardId;

      final rosterResponse = await _rosterRepository.getRosterData(
        guardId: event.guardId,
        fromDate: event.fromDate,
      );

      await _processRosterResponse(rosterResponse, emit);

    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Load Roster Data',
        additionalData: {
          'guardId': event.guardId,
          'fromDate': event.fromDate,
          'forceRefresh': event.forceRefresh,
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
      _currentGuardId = event.guardId;

      final rosterResponse = await _rosterRepository.getRosterDataPaginated(
        guardId: event.guardId,
        fromDate: event.fromDate,
        page: event.page,
        perPage: event.perPage,
      );

      await _processRosterResponse(rosterResponse, emit);

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

      // Validate submission data
      if (!_hasValidSubmissionData(event)) {
        throw Exception('No valid data provided for submission');
      }

      final response = await _rosterRepository.submitComprehensiveGuardDuty(
        rosterUpdates: event.rosterUpdates,
        movements: event.movements,
        perimeterChecks: event.perimeterChecks,
      );

      emit(RosterSubmissionSuccess(
        response: response,
        message: response.message,
        submissionSummary: _createSubmissionSummary(event),
      ));

    } catch (error) {
      handleErrorWithState(
        error,
        emit,
        (errorInfo) {
          // For submission errors, provide more context
          if (errorInfo.isNetworkError) {
            return RosterSubmissionError(
              errorInfo: errorInfo.copyWith(
                message: 'Submission saved locally. Will sync when online.',
              ),
              submissionCached: true,
            );
          }
          return RosterSubmissionError(
            errorInfo: errorInfo,
            submissionCached: false,
          );
        },
        context: 'Submit Guard Duty',
        additionalData: {
          'rosterUpdatesCount': event.rosterUpdates?.length ?? 0,
          'movementsCount': event.movements?.length ?? 0,
          'perimeterChecksCount': event.perimeterChecks?.length ?? 0,
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
        handleErrorWithState(
          'Some submissions failed to sync',
          emit,
          (errorInfo) => RosterSyncPartialError(
            errorInfo: errorInfo.copyWith(
              message: 'Some submissions failed to sync. Will retry automatically.',
              canRetry: true,
            ),
            syncStatus: syncStatus,
          ),
          context: 'Sync Pending Submissions',
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
        handleErrorWithState(
          result.message,
          emit,
          (errorInfo) => RosterSyncDetailedError(
            syncResult: result,
            errorInfo: errorInfo.copyWith(canRetry: false),
          ),
          context: 'Clear Sync History',
        );
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
        handleErrorWithState(
          result.message,
          emit,
          (errorInfo) => RosterSyncDetailedError(
            syncResult: result,
            errorInfo: errorInfo.copyWith(canRetry: true),
          ),
          context: 'Clean Old Sync Data',
        );
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
      _clearLocalCache();

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
      _currentGuardId = event.guardId;

      final rosterResponse = await _rosterRepository.getTodaysRosterStatus(
        guardId: event.guardId,
      );

      await _processRosterResponse(rosterResponse, emit);

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
      _currentGuardId = event.guardId;

      final rosterResponse = await _rosterRepository.getUpcomingRosterDuties(
        guardId: event.guardId,
      );

      await _processRosterResponse(rosterResponse, emit);

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
      _currentGuardId = event.guardId;

      final rosterResponse = await _rosterRepository.getTodaysRosterStatus(
        guardId: event.guardId,
      );

      final currentActiveDuty = _rosterRepository.getCurrentActiveDuty(rosterResponse);

      if (state is RosterLoaded) {
        final currentState = state as RosterLoaded;
        emit(currentState.copyWith(
          currentActiveDuty: currentActiveDuty,
          lastUpdated: DateTime.now(),
        ));
      } else {
        await _processRosterResponse(rosterResponse, emit);
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
      _currentGuardId = event.guardId;

      final rosterResponse = await _rosterRepository.getRosterData(
        guardId: event.guardId,
      );

      await _processRosterResponse(rosterResponse, emit, isRefresh: true);

    } catch (error) {
      // For refresh, we might want to keep the previous state and just log the error
      if (state is RosterLoaded) {
        final errorInfo = processError(
          error,
          context: 'Refresh Roster Data',
          additionalData: {'guardId': event.guardId},
        );
        log('Refresh failed: ${errorInfo.message}');
        
        // Emit a refresh error state that maintains the previous data
        final currentState = state as RosterLoaded;
        emit(RosterRefreshError(
          errorInfo: errorInfo,
          previousState: currentState,
        ));
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

  Future<void> _onClearRosterError(
    ClearRosterError event,
    Emitter<RosterState> emit,
  ) async {
    if (state is RosterRefreshError) {
      final errorState = state as RosterRefreshError;
      emit(errorState.previousState);
    } else if (_isErrorState(state)) {
      // Return to initial state or last known good state
      if (_lastRosterResponse != null && _currentGuardId != null) {
        await _processRosterResponse(_lastRosterResponse!, emit);
      } else {
        emit(const RosterInitial());
      }
    }
  }

  // ===== HELPER METHODS =====

  /// Process roster response and emit appropriate state
  Future<void> _processRosterResponse(
    RosterResponseModel rosterResponse,
    Emitter<RosterState> emit, {
    bool isRefresh = false,
  }) async {
    _lastRosterResponse = rosterResponse;
    _cachedSites = _rosterRepository.extractSitesFromRoster(rosterResponse);
    
    final currentActiveDuty = _rosterRepository.getCurrentActiveDuty(rosterResponse);
    final upcomingDuties = _rosterRepository.getUpcomingDuties(rosterResponse);

    emit(RosterLoaded(
      rosterResponse: rosterResponse,
      sites: _cachedSites,
      currentActiveDuty: currentActiveDuty,
      upcomingDuties: upcomingDuties,
      lastUpdated: DateTime.now(),
      isFromCache: !_rosterRepository.isConnected,
      isRefresh: isRefresh,
    ));
  }

  /// Validate if submission has valid data
  bool _hasValidSubmissionData(SubmitComprehensiveGuardDuty event) {
    return (event.rosterUpdates?.isNotEmpty ?? false) ||
           (event.movements?.isNotEmpty ?? false) ||
           (event.perimeterChecks?.isNotEmpty ?? false);
  }

  /// Create submission summary for UI display
  Map<String, int> _createSubmissionSummary(SubmitComprehensiveGuardDuty event) {
    return {
      'rosterUpdates': event.rosterUpdates?.length ?? 0,
      'movements': event.movements?.length ?? 0,
      'perimeterChecks': event.perimeterChecks?.length ?? 0,
      'totalItems': (event.rosterUpdates?.length ?? 0) +
                   (event.movements?.length ?? 0) +
                   (event.perimeterChecks?.length ?? 0),
    };
  }

  /// Clear local cache
  void _clearLocalCache() {
    _lastRosterResponse = null;
    _cachedSites.clear();
  }

  /// Check if current state is an error state
  bool _isErrorState(RosterState state) {
    return state is RosterError ||
           state is RosterSubmissionError ||
           state is RosterSyncPartialError ||
           state is RosterSyncDetailedError ||
           state is RosterRefreshError;
  }

  // ===== PUBLIC GETTERS =====

  /// Get current guard ID
  int? get currentGuardId => _currentGuardId;

  /// Check if bloc has loaded data
  bool get hasLoadedData => state is RosterLoaded;

  /// Check if bloc is in loading state
  bool get isLoading => state is RosterLoading;

  /// Check if bloc has error
  bool get hasError => _isErrorState(state);

  /// Get current error info if in error state
  BlocErrorInfo? get currentError {
    return switch (state) {
      RosterError(:final errorInfo) => errorInfo,
      RosterSubmissionError(:final errorInfo) => errorInfo,
      RosterSyncPartialError(:final errorInfo) => errorInfo,
      RosterSyncDetailedError(:final errorInfo) => errorInfo,
      RosterRefreshError(:final errorInfo) => errorInfo,
      _ => null,
    };
  }

  /// Check if can retry current operation
  bool get canRetry {
    final error = currentError;
    return error?.canRetry ?? false;
  }

  /// Get connectivity status
  bool get isConnected => _rosterRepository.isConnected;

  /// Get roster summary for UI
  Map<String, dynamic> get rosterSummary {
    if (state is RosterLoaded) {
      final loadedState = state as RosterLoaded;
      return {
        'totalRosterItems': loadedState.rosterResponse.data.length,
        'sitesCount': loadedState.sites.length,
        'hasActiveDuty': loadedState.currentActiveDuty != null,
        'upcomingDutiesCount': loadedState.upcomingDuties.length,
        'isFromCache': loadedState.isFromCache,
        'lastUpdated': loadedState.lastUpdated,
      };
    }
    return {
      'totalRosterItems': 0,
      'sitesCount': 0,
      'hasActiveDuty': false,
      'upcomingDutiesCount': 0,
      'isFromCache': false,
      'lastUpdated': null,
    };
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _rosterRepository.dispose();
    return super.close();
  }
}