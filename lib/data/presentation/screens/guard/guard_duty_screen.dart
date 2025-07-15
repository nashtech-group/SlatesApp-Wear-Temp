import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/roster_bloc/roster_bloc.dart';
import 'package:slates_app_wear/blocs/checkpoint_bloc/checkpoint_bloc.dart';
import 'package:slates_app_wear/blocs/location_bloc/location_bloc.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/wearable/wearable_scaffold.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/guard/guard_status_widget.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/guard/duty_actions_widget.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/guard/guard_stats_widget.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/common/loading_overlay.dart';

class GuardDutyScreen extends StatefulWidget {
  final UserModel user;
  final bool isOffline;

  const GuardDutyScreen({
    super.key,
    required this.user,
    required this.isOffline,
  });

  @override
  State<GuardDutyScreen> createState() => _GuardDutyScreenState();
}

class _GuardDutyScreenState extends State<GuardDutyScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late AnimationController _statusController;
  late Animation<double> _statusAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupControllers();
    _initializeBlocs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _setupControllers() {
    _tabController = TabController(length: 4, vsync: this);
    _statusController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _statusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statusController,
      curve: Curves.easeInOut,
    ));
    _statusController.forward();
  }

  void _initializeBlocs() {
    // Load roster data for current user
    context.read<RosterBloc>().add(LoadRosterDataEvent(
      guardId: widget.user.id,
      fromDate: DateTime.now().subtract(const Duration(days: 7)),
      toDate: DateTime.now().add(const Duration(days: 30)),
    ));

    // Initialize location tracking
    context.read<LocationBloc>().add(const InitializeLocationEvent());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      context.read<RosterBloc>().add(LoadRosterDataEvent(
        guardId: widget.user.id,
        fromDate: DateTime.now().subtract(const Duration(days: 7)),
        toDate: DateTime.now().add(const Duration(days: 30)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return WearableScaffold(
      isRoundScreen: responsive.isRoundScreen,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, responsive),
              if (widget.isOffline) _buildOfflineBanner(context, responsive),
              _buildTabBar(context, responsive),
              Expanded(
                child: _buildTabContent(context, responsive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ResponsiveUtils responsive) {
    final theme = Theme.of(context);

    return Container(
      padding: responsive.containerPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!responsive.isWearable)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                ),
              Expanded(
                child: Text(
                  'Guard Duty',
                  style: responsive.getTitleStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showNotifications(context),
                icon: const Icon(Icons.notifications),
                color: Colors.white,
              ),
              if (!responsive.isWearable)
                IconButton(
                  onPressed: () => _showSettings(context),
                  icon: const Icon(Icons.settings),
                  color: Colors.white,
                ),
            ],
          ),
          responsive.smallSpacer,
          FadeTransition(
            opacity: _statusAnimation,
            child: Text(
              'Hello, ${widget.user.firstName}',
              style: responsive.getBodyStyle(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context, ResponsiveUtils responsive) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.padding,
        vertical: responsive.smallSpacing,
      ),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            color: theme.colorScheme.onErrorContainer,
            size: responsive.iconSize,
          ),
          responsive.smallHorizontalSpacer,
          Expanded(
            child: Text(
              'Offline Mode - Data will sync when connected',
              style: responsive.getCaptionStyle(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, ResponsiveUtils responsive) {
    final theme = Theme.of(context);

    if (responsive.isWearable) {
      // For wearables, use simplified navigation
      return Container(
        height: 40,
        margin: EdgeInsets.symmetric(horizontal: responsive.padding),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _tabController.animateTo(0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _tabController.index == 0
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(responsive.borderRadius),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.dashboard,
                      color: _tabController.index == 0
                          ? Colors.white
                          : theme.colorScheme.primary,
                      size: responsive.iconSize,
                    ),
                  ),
                ),
              ),
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: GestureDetector(
                onTap: () => _tabController.animateTo(1),
                child: Container(
                  decoration: BoxDecoration(
                    color: _tabController.index == 1
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(responsive.borderRadius),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.calendar_today,
                      color: _tabController.index == 1
                          ? Colors.white
                          : theme.colorScheme.primary,
                      size: responsive.iconSize,
                    ),
                  ),
                ),
              ),
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: GestureDetector(
                onTap: () => _tabController.animateTo(2),
                child: Container(
                  decoration: BoxDecoration(
                    color: _tabController.index == 2
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(responsive.borderRadius),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.map,
                      color: _tabController.index == 2
                          ? Colors.white
                          : theme.colorScheme.primary,
                      size: responsive.iconSize,
                    ),
                  ),
                ),
              ),
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: GestureDetector(
                onTap: () => _tabController.animateTo(3),
                child: Container(
                  decoration: BoxDecoration(
                    color: _tabController.index == 3
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(responsive.borderRadius),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.history,
                      color: _tabController.index == 3
                          ? Colors.white
                          : theme.colorScheme.primary,
                      size: responsive.iconSize,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return TabBar(
      controller: _tabController,
      indicatorColor: theme.colorScheme.primary,
      labelColor: theme.colorScheme.primary,
      unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      labelStyle: responsive.getCaptionStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: responsive.getCaptionStyle(),
      tabs: const [
        Tab(icon: Icon(Icons.dashboard), text: 'Status'),
        Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
        Tab(icon: Icon(Icons.map), text: 'Map'),
        Tab(icon: Icon(Icons.history), text: 'History'),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context, ResponsiveUtils responsive) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Status Tab
        _GuardStatusTab(
          user: widget.user,
          isOffline: widget.isOffline,
          responsive: responsive,
        ),
        
        // Calendar Tab
        _GuardCalendarTab(
          user: widget.user,
          isOffline: widget.isOffline,
          responsive: responsive,
        ),
        
        // Map Tab
        _GuardMapTab(
          user: widget.user,
          isOffline: widget.isOffline,
          responsive: responsive,
        ),
        
        // History Tab
        _GuardHistoryTab(
          user: widget.user,
          isOffline: widget.isOffline,
          responsive: responsive,
        ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    Navigator.of(context).pushNamed(RouteConstants.notificationCenter);
  }

  void _showSettings(BuildContext context) {
    Navigator.of(context).pushNamed(RouteConstants.settings);
  }
}

// Status Tab Widget
class _GuardStatusTab extends StatelessWidget {
  final UserModel user;
  final bool isOffline;
  final ResponsiveUtils responsive;

  const _GuardStatusTab({
    required this.user,
    required this.isOffline,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RosterBloc, RosterState>(
      builder: (context, rosterState) {
        return BlocBuilder<LocationBloc, LocationState>(
          builder: (context, locationState) {
            return SingleChildScrollView(
              padding: responsive.containerPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Status Widget
                  GuardStatusWidget(
                    user: user,
                    isOffline: isOffline,
                    rosterState: rosterState,
                    locationState: locationState,
                    responsive: responsive,
                  ),
                  
                  responsive.mediumSpacer,
                  
                  // Quick Actions
                  DutyActionsWidget(
                    user: user,
                    isOffline: isOffline,
                    rosterState: rosterState,
                    locationState: locationState,
                    responsive: responsive,
                  ),
                  
                  responsive.mediumSpacer,
                  
                  // Stats Widget
                  GuardStatsWidget(
                    user: user,
                    isOffline: isOffline,
                    rosterState: rosterState,
                    responsive: responsive,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Calendar Tab Widget
class _GuardCalendarTab extends StatelessWidget {
  final UserModel user;
  final bool isOffline;
  final ResponsiveUtils responsive;

  const _GuardCalendarTab({
    required this.user,
    required this.isOffline,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RosterBloc, RosterState>(
      builder: (context, state) {
        if (state is RosterLoading) {
          return const LoadingOverlay(message: 'Loading calendar...');
        }

        if (state is RosterError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: responsive.largeIconSize * 2,
                  color: Theme.of(context).colorScheme.error,
                ),
                responsive.mediumSpacer,
                Text(
                  'Failed to load calendar',
                  style: responsive.getBodyStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                responsive.mediumSpacer,
                ElevatedButton(
                  onPressed: () {
                    context.read<RosterBloc>().add(LoadRosterDataEvent(
                      guardId: user.id,
                      fromDate: DateTime.now().subtract(const Duration(days: 7)),
                      toDate: DateTime.now().add(const Duration(days: 30)),
                    ));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Load calendar component
        return const Center(
          child: Text('Calendar View - Implementation in next artifact'),
        );
      },
    );
  }
}

// Map Tab Widget
class _GuardMapTab extends StatelessWidget {
  final UserModel user;
  final bool isOffline;
  final ResponsiveUtils responsive;

  const _GuardMapTab({
    required this.user,
    required this.isOffline,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        if (state is LocationLoading) {
          return const LoadingOverlay(message: 'Loading map...');
        }

        // Load map component
        return const Center(
          child: Text('Map View - Implementation in next artifact'),
        );
      },
    );
  }
}

// History Tab Widget
class _GuardHistoryTab extends StatelessWidget {
  final UserModel user;
  final bool isOffline;
  final ResponsiveUtils responsive;

  const _GuardHistoryTab({
    required this.user,
    required this.isOffline,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RosterBloc, RosterState>(
      builder: (context, state) {
        if (state is RosterLoading) {
          return const LoadingOverlay(message: 'Loading history...');
        }

        // Load history component
        return const Center(
          child: Text('History View - Implementation in next artifact'),
        );
      },
    );
  }
}