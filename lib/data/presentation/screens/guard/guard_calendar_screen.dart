import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/data/presentation/widgets/wearable/wearable_scaffold.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:slates_app_wear/blocs/roster_bloc/roster_bloc.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/presentation/widgets/common/loading_overlay.dart';
import 'package:slates_app_wear/data/presentation/widgets/guard/duty_card_widget.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/utils/status_colors.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/services/date_service.dart';

class GuardCalendarScreen extends StatefulWidget {
  final int guardId;

  const GuardCalendarScreen({
    super.key,
    required this.guardId,
  });

  @override
  State<GuardCalendarScreen> createState() => _GuardCalendarScreenState();
}

class _GuardCalendarScreenState extends State<GuardCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _currentPage = 1;
  bool _isLoadingMore = false;

  final DateService _dateService = DateService();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadRosterData();
  }

  void _loadRosterData({bool forceRefresh = false}) {
    context.read<RosterBloc>().add(
      LoadRosterData(
        guardId: widget.guardId,
        fromDate: _dateService.formatDateForApi(DateTime.now()),
        forceRefresh: forceRefresh,
      ),
    );
  }

  void _loadMoreData() {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    context.read<RosterBloc>().add(
      LoadRosterDataPaginated(
        guardId: widget.guardId,
        fromDate: _dateService.formatDateForApi(DateTime.now()),
        page: _currentPage + 1,
      ),
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
          if (state is RosterLoaded && _isLoadingMore) {
            setState(() {
              _isLoadingMore = false;
              _currentPage++;
            });
          }
        },
        builder: (context, state) {
          if (state is RosterLoading && !_isLoadingMore) {
            return const LoadingOverlay(
              message: 'Loading calendar data...',
              animated: true,
            );
          }
          return _buildCalendarContent(context, state, responsive, theme);
        },
      ),
    );
  }

  Widget _buildCalendarContent(
    BuildContext context, 
    RosterState state, 
    ResponsiveUtils responsive, 
    ThemeData theme
  ) {
    return Column(
      children: [
        _buildHeader(context, responsive, theme),
        Expanded(
          child: SingleChildScrollView(
            padding: responsive.containerPadding,
            child: Column(
              children: [
                _buildCalendar(context, state, responsive, theme),
                responsive.mediumSpacer,
                _buildSelectedDayDuties(context, state, responsive, theme),
              ],
            ),
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
              child: Text(
                'Guard Calendar',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () => _loadRosterData(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              color: theme.colorScheme.onPrimary,
              tooltip: 'Refresh calendar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context, 
    RosterState state, 
    ResponsiveUtils responsive, 
    ThemeData theme
  ) {
    List<RosterUserModel> allDuties = [];

    if (state is RosterLoaded) {
      allDuties = state.rosterResponse.data;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius),
      ),
      child: Padding(
        padding: responsive.containerPadding,
        child: TableCalendar<RosterUserModel>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: CalendarFormat.month,
          eventLoader: (day) {
            return allDuties.where((duty) {
              return _dateService.isSameDay(duty.initialShiftDate, day);
            }).toList();
          },
          startingDayOfWeek: StartingDayOfWeek.monday,
          
          // Calendar styling with theme colors
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(
              color: StatusColors.getGuardDutyStatusColor(0), // Use status colors
            ),
            holidayTextStyle: theme.textTheme.bodyMedium!.copyWith(
              color: StatusColors.getGuardDutyStatusColor(0),
            ),
            selectedTextStyle: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayTextStyle: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary),
            ),
            defaultTextStyle: theme.textTheme.bodyMedium!,
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          
          // Header styling
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: theme.colorScheme.primary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.primary,
            ),
            titleTextStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ) ?? TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
          ),
          
          // Days of week styling
          daysOfWeekStyle: DaysOfWeekStyle(
            weekendStyle: theme.textTheme.labelMedium?.copyWith(
              color: StatusColors.getGuardDutyStatusColor(0),
              fontWeight: FontWeight.w500,
            ) ?? TextStyle(
              color: StatusColors.getGuardDutyStatusColor(0),
              fontWeight: FontWeight.w500,
            ),
            weekdayStyle: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ) ?? TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },

          // Event builder for duty markers
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              
              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: events.take(3).map((event) {
                    final duty = event;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: StatusColors.getGuardDutyStatusColor(duty.status),
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayDuties(
    BuildContext context, 
    RosterState state, 
    ResponsiveUtils responsive, 
    ThemeData theme
  ) {
    if (_selectedDay == null) return const SizedBox.shrink();

    List<RosterUserModel> duties = [];
    if (state is RosterLoaded) {
      duties = state.rosterResponse.data.where((duty) {
        return _dateService.isSameDay(duty.initialShiftDate, _selectedDay!);
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.event,
              color: theme.colorScheme.primary,
              size: responsive.iconSize,
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: Text(
                'Duties for ${_dateService.formatDateSmart(_selectedDay!)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        responsive.smallSpacer,
        
        if (duties.isEmpty)
          _buildEmptyState(responsive, theme)
        else
          ...duties.map((duty) => Padding(
            padding: EdgeInsets.only(bottom: responsive.smallSpacing),
            child: DutyCardWidget(
              duty: duty,
              onTap: () => _navigateToDutyDetails(duty),
            ),
          )),
          
        if (state is RosterLoaded && 
            state.rosterResponse.meta.currentPage < state.rosterResponse.meta.lastPage &&
            duties.isNotEmpty)
          _buildLoadMoreButton(responsive, theme),
      ],
    );
  }

  Widget _buildEmptyState(ResponsiveUtils responsive, ThemeData theme) {
    return Card(
      child: Padding(
        padding: responsive.containerPadding,
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.primary,
              size: responsive.iconSize,
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: Text(
                'No duties scheduled for this day',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(ResponsiveUtils responsive, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(top: responsive.mediumSpacing),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: _isLoadingMore ? null : _loadMoreData,
          style: AppTheme.responsivePrimaryButtonStyle(context),
          icon: _isLoadingMore
              ? SizedBox(
                  width: responsive.iconSize,
                  height: responsive.iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : Icon(
                  Icons.keyboard_arrow_down,
                  size: responsive.iconSize,
                ),
          label: Text(_isLoadingMore ? 'Loading...' : 'Load More'),
        ),
      ),
    );
  }

  void _navigateToDutyDetails(RosterUserModel duty) {
    Navigator.of(context).pushNamed(
      RouteConstants.dutyDetails,
      arguments: duty,
    );
  }
}