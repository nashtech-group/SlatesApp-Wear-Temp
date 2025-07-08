part of 'roster_bloc.dart';

abstract class RosterState extends Equatable {
  const RosterState();
  
  @override
  List<Object?> get props => [];
}

final class RosterInitial extends RosterState {}

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
  final DateTime lastUpdated;

  const RosterLoaded({
    required this.rosterResponse,
    required this.sites,
    this.currentActiveDuty,
    required this.upcomingDuties,
    this.isFromCache = false,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        rosterResponse,
        sites,
        currentActiveDuty,
        upcomingDuties,
        isFromCache,
        lastUpdated,
      ];

  RosterLoaded copyWith({
    RosterResponseModel? rosterResponse,
    List<SiteModel>? sites,
    RosterUserModel? currentActiveDuty,
    List<RosterUserModel>? upcomingDuties,
    bool? isFromCache,
    DateTime? lastUpdated,
  }) {
    return RosterLoaded(
      rosterResponse: rosterResponse ?? this.rosterResponse,
      sites: sites ?? this.sites,
      currentActiveDuty: currentActiveDuty ?? this.currentActiveDuty,
      upcomingDuties: upcomingDuties ?? this.upcomingDuties,
      isFromCache: isFromCache ?? this.isFromCache,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class RosterSubmissionSuccess extends RosterState {
  final ComprehensiveGuardDutyResponseModel response;
  final String message;

  const RosterSubmissionSuccess({
    required this.response,
    required this.message,
  });

  @override
  List<Object?> get props => [response, message];
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
}

class RosterError extends RosterState {
  final BlocErrorInfo errorInfo;

  const RosterError({required this.errorInfo});

  @override
  List<Object?> get props => [errorInfo];

  // Convenience getters for backward compatibility
  String get message => errorInfo.message;
  bool get canRetry => errorInfo.canRetry;
  bool get isNetworkError => errorInfo.isNetworkError;
  ErrorType get errorType => errorInfo.type;
  List<String>? get validationErrors => errorInfo.validationErrors;
}

class RosterCacheCleared extends RosterState {
  final String message;

  const RosterCacheCleared({required this.message});

  @override
  List<Object?> get props => [message];
}