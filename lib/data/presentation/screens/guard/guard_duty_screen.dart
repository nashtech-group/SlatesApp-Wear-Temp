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
import 'package:slates_app_wear/core/utils/status_colors.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/data/presentation/widgets/wearable/wearable_scaffold.dart';
import 'package:slates_app_wear/services/date_service.dart';

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

  final DateService _dateService = DateService();

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
    final theme = Theme.of(context);

    return WearableScaffold(
      body: BlocConsumer<RosterBloc, RosterState>(
        listener: (context, state) {
          if (state is RosterError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorInfo.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
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
          return _buildDutyContent(context, state, responsive, theme);
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

  Widget _buildDutyContent(
    BuildContext context, 
    RosterState state, 
    ResponsiveUtils responsive, 
    ThemeData theme
  ) {
    return Column(
      children: [
        _buildHeader(context, responsive, theme),
        _buildTabBar(context, responsive, theme),
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

  Widget _buildHeader(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Container(
      padding: responsive.containerPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
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
              color: theme.colorScheme.onPrimary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Guard Duty',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentDuty != null)
                    Text(
                      _currentDuty!.site.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
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
              color: theme.colorScheme.onPrimary,
              tooltip: 'Notifications',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
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
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: theme.colorScheme.primary,
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

          responsive.mediumSpacer,

          // Duty Actions
          if (currentDuty != null)
            DutyActionsWidget(
              duty: currentDuty!,
            ),

          responsive.mediumSpacer,

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
    final theme = Theme.of(context);
    final dateService = DateService();

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
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: theme.colorScheme.primary,
                        size: responsive.iconSize,
                      ),
                      responsive.smallHorizontalSpacer,
                      Text(
                        'This Week\'s Duties',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  responsive.smallSpacer,
                  _buildWeeklyDuties(context, responsive, theme, dateService),
                ],
              ),
            ),
          ),

          responsive.mediumSpacer,

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
              style: AppTheme.responsivePrimaryButtonStyle(context),
              icon: const Icon(Icons.calendar_month),
              label: const Text('View Full Calendar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyDuties(BuildContext context, ResponsiveUtils responsive, ThemeData theme, DateService dateService) {
    if (rosterState is! RosterLoaded) {
      return Container(
        padding: responsive.containerPadding,
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.onSurfaceVariant,
              size: responsive.iconSize,
            ),
            responsive.smallHorizontalSpacer,
            Text(
              'No duty data available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
      return Container(
        padding: responsive.containerPadding,
        child: Row(
          children: [
            Icon(
              Icons.event_busy,
              color: theme.colorScheme.onSurfaceVariant,
              size: responsive.iconSize,
            ),
            responsive.smallHorizontalSpacer,
            Text(
              'No duties scheduled this week',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: weekDuties.map((duty) {
        return Padding(
          padding: EdgeInsets.only(bottom: responsive.smallSpacing),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: StatusColors.getGuardDutyStatusColor(duty.status),
              radius: responsive.iconSize * 0.6,
              child: Text(
                '${duty.initialShiftDate.day}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: StatusColors.getTextColorForBackground(
                    StatusColors.getGuardDutyStatusColor(duty.status)
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              duty.site.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${dateService.formatTimeForDisplay(duty.startsAt)} - ${dateService.formatTimeForDisplay(duty.endsAt)}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: StatusColors.getStatusIndicatorDecoration(
                color: StatusColors.getGuardDutyStatusColor(duty.status),
                borderRadius: BorderRadius.circular(responsive.borderRadius / 2),
              ),
              child: Text(
                StatusColors.getGuardDutyStatusLabel(duty.status),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: StatusColors.getGuardDutyStatusColor(duty.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
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