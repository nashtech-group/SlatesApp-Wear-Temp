part of 'roster_bloc.dart';

abstract class RosterState extends Equatable {
  const RosterState();
  
  @override
  List<Object?> get props => [];
}

class RosterInitial extends RosterState {
  const RosterInitial();
}

class RosterLoading extends RosterState {
  final String? message;

  const RosterLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class RosterLoaded extends RosterState {
  final RosterResponseModel rosterResponse;
  final List<SiteModel> sites;
  final RosterUserModel? currentActiveDuty;
  final List<RosterUserModel> upcomingDuties;
  final bool isFromCache;
  final bool isRefresh;
  final DateTime lastUpdated;

  const RosterLoaded({
    required this.rosterResponse,
    required this.sites,
    this.currentActiveDuty,
    required this.upcomingDuties,
    this.isFromCache = false,
    this.isRefresh = false,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        rosterResponse,
        sites,
        currentActiveDuty,
        upcomingDuties,
        isFromCache,
        isRefresh,
        lastUpdated,
      ];

  RosterLoaded copyWith({
    RosterResponseModel? rosterResponse,
    List<SiteModel>? sites,
    RosterUserModel? currentActiveDuty,
    List<RosterUserModel>? upcomingDuties,
    bool? isFromCache,
    bool? isRefresh,
    DateTime? lastUpdated,
  }) {
    return RosterLoaded(
      rosterResponse: rosterResponse ?? this.rosterResponse,
      sites: sites ?? this.sites,
      currentActiveDuty: currentActiveDuty ?? this.currentActiveDuty,
      upcomingDuties: upcomingDuties ?? this.upcomingDuties,
      isFromCache: isFromCache ?? this.isFromCache,
      isRefresh: isRefresh ?? this.isRefresh,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convenience getters for UI
  bool get hasCurrentDuty => currentActiveDuty != null;
  bool get hasUpcomingDuties => upcomingDuties.isNotEmpty;
  bool get hasSites => sites.isNotEmpty;
  int get totalRosterItems => rosterResponse.data.length;
  String get statusText => isFromCache ? 'Offline Data' : 'Live Data';
  
  /// Get formatted last updated time
  String get formattedLastUpdated {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class RosterSubmissionSuccess extends RosterState {
  final ComprehensiveGuardDutyResponseModel response;
  final String message;
  final Map<String, int> submissionSummary;

  const RosterSubmissionSuccess({
    required this.response,
    required this.message,
    required this.submissionSummary,
  });

  @override
  List<Object?> get props => [response, message, submissionSummary];

  /// Get total items submitted
  int get totalItemsSubmitted => submissionSummary['totalItems'] ?? 0;
  
  /// Get formatted submission summary
  String get formattedSummary {
    final total = totalItemsSubmitted;
    final rosterUpdates = submissionSummary['rosterUpdates'] ?? 0;
    final movements = submissionSummary['movements'] ?? 0;
    final checks = submissionSummary['perimeterChecks'] ?? 0;
    
    final parts = <String>[];
    if (rosterUpdates > 0) parts.add('$rosterUpdates roster updates');
    if (movements > 0) parts.add('$movements movements');
    if (checks > 0) parts.add('$checks perimeter checks');
    
    return parts.isEmpty ? 'No items submitted' : 'Submitted ${parts.join(', ')} ($total total)';
  }
}

class RosterSyncSuccess extends RosterState {
  final String message;
  final Map<String, dynamic> syncStatus;

  const RosterSyncSuccess({
    required this.message,
    required this.syncStatus,
  });

  @override
  List<Object?> get props => [message, syncStatus];

  /// Get pending submissions count
  int get pendingSubmissions => syncStatus['pendingSubmissions'] as int? ?? 0;
  
  /// Get last sync time
  String get lastSyncTime {
    final lastSync = syncStatus['lastSyncTime'] as String?;
    return lastSync ?? 'Never';
  }
  
  /// Check if sync is required
  bool get isSyncRequired => syncStatus['isSyncRequired'] as bool? ?? false;
}

class RosterSyncDetailedSuccess extends RosterState {
  final SyncResult syncResult;
  final String message;
  final Map<String, dynamic>? syncStatus;

  const RosterSyncDetailedSuccess({
    required this.syncResult,
    required this.message,
    this.syncStatus,
  });

  @override
  List<Object?> get props => [syncResult, message, syncStatus];

  /// Get formatted sync summary
  String get formattedSyncSummary => 
      'Synced ${syncResult.successCount}/${syncResult.totalCount} items (${syncResult.successPercentage}% success)';
}

class RosterSyncDetailedError extends RosterState {
  final SyncResult syncResult;
  final BlocErrorInfo errorInfo;

  const RosterSyncDetailedError({
    required this.syncResult,
    required this.errorInfo,
  });

  @override
  List<Object?> get props => [syncResult, errorInfo];

  // Convenience getters for backward compatibility
  String get message => errorInfo.message;
  bool get canRetry => errorInfo.canRetry;
  
  /// Get formatted error summary
  String get formattedErrorSummary => 
      'Failed to sync ${syncResult.failureCount}/${syncResult.totalCount} items';
}

class RosterSyncReportLoaded extends RosterState {
  final Map<String, dynamic> report;
  final String message;

  const RosterSyncReportLoaded({
    required this.report,
    required this.message,
  });

  @override
  List<Object?> get props => [report, message];

  /// Get report summary
  Map<String, dynamic> get reportSummary {
    return {
      'totalSyncAttempts': report['totalSyncAttempts'] ?? 0,
      'successfulSyncs': report['successfulSyncs'] ?? 0,
      'failedSyncs': report['failedSyncs'] ?? 0,
      'pendingItems': report['pendingItems'] ?? 0,
      'lastSyncTime': report['lastSyncTime'] ?? 'Never',
    };
  }
}

class RosterStorageUsageLoaded extends RosterState {
  final Map<String, dynamic> usage;
  final String message;

  const RosterStorageUsageLoaded({
    required this.usage,
    required this.message,
  });

  @override
  List<Object?> get props => [usage, message];

  /// Get formatted storage usage
  String get formattedUsage {
    final dbSize = usage['databaseSizeMB'] as String? ?? '0';
    final totalRecords = usage['totalRecords'] as int? ?? 0;
    return 'Database: ${dbSize}MB, Records: $totalRecords';
  }
  
  /// Check if storage is getting full
  bool get isStorageHigh {
    final dbSizeStr = usage['databaseSizeMB'] as String? ?? '0';
    final dbSize = double.tryParse(dbSizeStr) ?? 0;
    return dbSize > 100; // 100MB threshold
  }
}

class RosterCacheCleared extends RosterState {
  final String message;

  const RosterCacheCleared({required this.message});

  @override
  List<Object?> get props => [message];
}

class RosterError extends RosterState with ErrorStateMixin {
  @override
  final BlocErrorInfo errorInfo;

  const RosterError({required this.errorInfo});

  @override
  List<Object?> get props => [errorInfo];

  /// Create copy with updated error info
  RosterError copyWith({BlocErrorInfo? errorInfo}) {
    return RosterError(errorInfo: errorInfo ?? this.errorInfo);
  }
}

/// Submission-specific error state with additional context
class RosterSubmissionError extends RosterState with ErrorStateMixin {
  @override
  final BlocErrorInfo errorInfo;
  final bool submissionCached;

  const RosterSubmissionError({
    required this.errorInfo,
    required this.submissionCached,
  });

  @override
  List<Object?> get props => [errorInfo, submissionCached];

  /// Create copy with updated properties
  RosterSubmissionError copyWith({
    BlocErrorInfo? errorInfo,
    bool? submissionCached,
  }) {
    return RosterSubmissionError(
      errorInfo: errorInfo ?? this.errorInfo,
      submissionCached: submissionCached ?? this.submissionCached,
    );
  }
}

/// Partial sync error state with sync status context
class RosterSyncPartialError extends RosterState with ErrorStateMixin {
  @override
  final BlocErrorInfo errorInfo;
  final Map<String, dynamic> syncStatus;

  const RosterSyncPartialError({
    required this.errorInfo,
    required this.syncStatus,
  });

  @override
  List<Object?> get props => [errorInfo, syncStatus];

  /// Get failed items count
  int get failedItemsCount => syncStatus['failedItems'] as int? ?? 0;

  /// Create copy with updated properties
  RosterSyncPartialError copyWith({
    BlocErrorInfo? errorInfo,
    Map<String, dynamic>? syncStatus,
  }) {
    return RosterSyncPartialError(
      errorInfo: errorInfo ?? this.errorInfo,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class RosterRefreshError extends RosterState with ErrorStateMixin {
  @override
  final BlocErrorInfo errorInfo;
  final RosterLoaded previousState;

  const RosterRefreshError({
    required this.errorInfo,
    required this.previousState,
  });

  @override
  List<Object?> get props => [errorInfo, previousState];

  /// Create copy with updated error info
  RosterRefreshError copyWith({BlocErrorInfo? errorInfo}) {
    return RosterRefreshError(
      errorInfo: errorInfo ?? this.errorInfo,
      previousState: previousState,
    );
  }
}