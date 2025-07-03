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

class RosterError extends RosterState {
  final String message;
  final ApiErrorModel? error;
  final bool isNetworkError;
  final bool canRetry;

  const RosterError({
    required this.message,
    this.error,
    this.isNetworkError = false,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, error, isNetworkError, canRetry];
}

class RosterCacheCleared extends RosterState {
  final String message;

  const RosterCacheCleared({required this.message});

  @override
  List<Object?> get props => [message];
}