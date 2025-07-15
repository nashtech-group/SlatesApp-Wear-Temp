import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/roster_bloc/roster_bloc.dart';
import 'package:slates_app_wear/blocs/location_bloc/location_bloc.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/presentation/widgets/common/loading_overlay.dart';
import 'package:slates_app_wear/data/presentation/widgets/guard/guard_status_widget.dart';
import 'package:slates_app_wear/data/presentation/widgets/guard/duty_actions_widget.dart';
import 'package:slates_app_wear/data/presentation/widgets/guard/guard_stats_widget.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';
import 'package:slates_app_wear/data/presentation/widgets/wearable/wearable_scaffold.dart';

class GuardDutyScreen extends StatefulWidget {
  final int guardId;

  const GuardDutyScreen({
    super.key,
    required this.guardId,
  });

  @override
  State<GuardDutyScreen> createState() => _GuardDutyScreenState();
}

class _GuardDutyScreenState extends State<GuardDutyScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  RosterUserModel? _currentDuty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  void _loadInitialData() {
    // Load roster data
    context.read<RosterBloc>().add(
      LoadRosterData(
        guardId: widget.guardId,
        forceRefresh: true,
      ),
    );

    // Initialize location tracking
    context.read<LocationBloc>().add(
      const InitializeLocationTracking(),
    );

    // Refresh roster data periodically
    _setupPeriodicRefresh();
  }

  void _setupPeriodicRefresh() {
    context.read<RosterBloc>().add(
      RefreshRosterData(guardId: widget.guardId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return WearableScaffold(
      body: BlocConsumer<RosterBloc, RosterState>(
        listener: (context, state) {
          if (state is RosterError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorInfo.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          if (state is RosterLoaded) {
            _updateCurrentDuty(state);
          }
        },
        builder: (context, state) {
          if (state is RosterLoading) {
            return const LoadingOverlay(
              message: 'Loading duty information...',
              animated: true,
            );
          }
          return _buildDutyContent(context, state, responsive);
        },
      ),
    );
  }

  void _updateCurrentDuty(RosterLoaded state) {
    final now = DateTime.now();
    final currentDuty = state.rosterResponse.data.where((duty) {
      return now.isAfter(duty.startsAt) && now.isBefore(duty.endsAt);
    }).firstOrNull;

    if (currentDuty != _currentDuty) {
      setState(() {
        _currentDuty = currentDuty;
      });
    }
  }

  Widget _buildDutyContent(BuildContext context, RosterState state, ResponsiveUtils responsive) {
    return Column(
      children: [
        _buildHeader(context, responsive),
        _buildTabBar(context, responsive),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _GuardDutyTab(
                guardId: widget.guardId,
                currentDuty: _currentDuty,
                rosterState: state,
              ),
              _GuardCalendarTab(
                guardId: widget.guardId,
                rosterState: state,
              ),
              _GuardStatsTab(
                guardId: widget.guardId,
                rosterState: state,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ResponsiveUtils responsive) {
    return Container(
      padding: responsive.containerPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(responsive.borderRadius),
          bottomRight: Radius.circular(responsive.borderRadius),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Guard Duty',
                    style: (Theme.of(context).textTheme.titleLarge ?? const TextStyle()).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentDuty != null)
                    Text(
                      _currentDuty!.site.name,
                      style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pushNamed(
                RouteConstants.notificationCenter,
              ),
              icon: const Icon(Icons.notifications),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, ResponsiveUtils responsive) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.security),
            text: 'Duty',
          ),
          Tab(
            icon: Icon(Icons.calendar_today),
            text: 'Calendar',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: 'Stats',
          ),
        ],
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelStyle: responsive.getCaptionStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: responsive.getCaptionStyle(),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _GuardDutyTab extends StatelessWidget {
  final int guardId;
  final RosterUserModel? currentDuty;
  final RosterState rosterState;

  const _GuardDutyTab({
    required this.guardId,
    required this.currentDuty,
    required this.rosterState,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return SingleChildScrollView(
      padding: responsive.containerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Guard Status
          GuardStatusWidget(
            guardId: guardId,
            currentDuty: currentDuty,
          ),

          SizedBox(height: responsive.mediumSpacing),

          // Duty Actions
          if (currentDuty != null)
            DutyActionsWidget(
              duty: currentDuty!,
            ),

          SizedBox(height: responsive.mediumSpacing),

          // Quick Stats
          if (rosterState is RosterLoaded)
            GuardStatsWidget(
              guardId: guardId,
              rosterState: rosterState,
              isCompact: true,
            ),
        ],
      ),
    );
  }
}

class _GuardCalendarTab extends StatelessWidget {
  final int guardId;
  final RosterState rosterState;

  const _GuardCalendarTab({
    required this.guardId,
    required this.rosterState,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return SingleChildScrollView(
      padding: responsive.containerPadding,
      child: Column(
        children: [
          // Quick calendar view
          Card(
            child: Padding(
              padding: responsive.containerPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week\'s Duties',
                    style: (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: responsive.smallSpacing),
                  _buildWeeklyDuties(context, responsive),
                ],
              ),
            ),
          ),

          SizedBox(height: responsive.mediumSpacing),

          // Full calendar button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<RosterBloc>().add(
                  LoadRosterData(guardId: guardId),
                );
                Navigator.of(context).pushNamed(RouteConstants.guardCalendar);
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('View Full Calendar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyDuties(BuildContext context, ResponsiveUtils responsive) {
    if (rosterState is! RosterLoaded) {
      return const Center(
        child: Text('No duty data available'),
      );
    }

    final rosterData = (rosterState as RosterLoaded).rosterResponse.data;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final weekDuties = rosterData.where((duty) {
      return duty.initialShiftDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
             duty.initialShiftDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();

    if (weekDuties.isEmpty) {
      return const Text('No duties scheduled this week');
    }

    return Column(
      children: weekDuties.map((duty) {
        return Padding(
          padding: EdgeInsets.only(bottom: responsive.smallSpacing),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getDutyStatusColor(context, duty),
              child: Text(
                '${duty.initialShiftDate.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(duty.site.name),
            subtitle: Text(
              '${_formatTime(duty.startsAt)} - ${_formatTime(duty.endsAt)}',
            ),
            trailing: Text(
              duty.statusLabel,
              style: TextStyle(
                color: _getDutyStatusColor(context, duty),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getDutyStatusColor(BuildContext context, RosterUserModel duty) {
    switch (duty.status) {
      case 1: return Colors.green;
      case 0: return Colors.red;
      case -1: return Colors.orange;
      default: return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _GuardStatsTab extends StatelessWidget {
  final int guardId;
  final RosterState rosterState;

  const _GuardStatsTab({
    required this.guardId,
    required this.rosterState,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return SingleChildScrollView(
      padding: responsive.containerPadding,
      child: GuardStatsWidget(
        guardId: guardId,
        rosterState: rosterState,
        isCompact: false,
      ),
    );
  }
}