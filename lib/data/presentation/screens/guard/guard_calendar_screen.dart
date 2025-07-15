import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/data/presentation/widgets/wearable/wearable_scaffold.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:slates_app_wear/blocs/roster_bloc/roster_bloc.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/presentation/widgets/common/loading_overlay.dart';
import 'package:slates_app_wear/data/presentation/widgets/guard/duty_card_widget.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';

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
        fromDate: DateTime.now().toIso8601String().split('T')[0],
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
        fromDate: DateTime.now().toIso8601String().split('T')[0],
        page: _currentPage + 1,
      ),
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
          return _buildCalendarContent(context, state, responsive);
        },
      ),
    );
  }

  Widget _buildCalendarContent(BuildContext context, RosterState state, ResponsiveUtils responsive) {
    return Column(
      children: [
        _buildHeader(context, responsive),
        Expanded(
          child: SingleChildScrollView(
            padding: responsive.containerPadding,
            child: Column(
              children: [
                _buildCalendar(context, state, responsive),
                SizedBox(height: responsive.mediumSpacing),
                _buildSelectedDayDuties(context, state, responsive),
              ],
            ),
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
              child: Text(
                'Guard Calendar',
                style: (Theme.of(context).textTheme.titleLarge ?? const TextStyle()).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () => _loadRosterData(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, RosterState state, ResponsiveUtils responsive) {
    final theme = Theme.of(context);
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
              return isSameDay(duty.initialShiftDate, day);
            }).toList();
          },
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
              color: theme.colorScheme.error,
            ),
            holidayTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
              color: theme.colorScheme.error,
            ),
            selectedTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
              color: Colors.white,
            ),
            todayTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
              color: theme.colorScheme.primary,
            ),
            defaultTextStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
            markersMaxCount: 3,
          ),
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
            titleTextStyle: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekendStyle: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
              color: theme.colorScheme.error,
            ),
            weekdayStyle: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
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
        ),
      ),
    );
  }

  Widget _buildSelectedDayDuties(BuildContext context, RosterState state, ResponsiveUtils responsive) {
    if (_selectedDay == null) return const SizedBox.shrink();

    List<RosterUserModel> duties = [];
    if (state is RosterLoaded) {
      duties = state.rosterResponse.data.where((duty) {
        return isSameDay(duty.initialShiftDate, _selectedDay!);
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duties for ${_formatDate(_selectedDay!)}',
          style: (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: responsive.smallSpacing),
        if (duties.isEmpty)
          Card(
            child: Padding(
              padding: responsive.containerPadding,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: responsive.smallSpacing),
                  Text(
                    'No duties scheduled for this day',
                    style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                  ),
                ],
              ),
            ),
          )
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
          Padding(
            padding: EdgeInsets.only(top: responsive.mediumSpacing),
            child: Center(
              child: ElevatedButton(
                onPressed: _isLoadingMore ? null : _loadMoreData,
                child: _isLoadingMore
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Text('Load More'),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToDutyDetails(RosterUserModel duty) {
    Navigator.of(context).pushNamed(
      RouteConstants.dutyDetails,
      arguments: duty,
    );
  }
}