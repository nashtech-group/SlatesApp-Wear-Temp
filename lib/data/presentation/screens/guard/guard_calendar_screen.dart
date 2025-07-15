import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:slates_app_wear/blocs/roster_bloc/roster_bloc.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_response_model.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/wearable/wearable_scaffold.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/common/loading_overlay.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/guard/duty_card_widget.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/common/status_indicator.dart';

class GuardCalendarScreen extends StatefulWidget {
  final UserModel user;
  final bool isOffline;

  const GuardCalendarScreen({
    super.key,
    required this.user,
    required this.isOffline,
  });

  @override
  State<GuardCalendarScreen> createState() => _GuardCalendarScreenState();
}

class _GuardCalendarScreenState extends State<GuardCalendarScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  List<ComprehensiveGuardDutyResponseModel> _selectedDayDuties = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  void _loadInitialData() {
    final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    
    context.read<RosterBloc>().add(LoadRosterDataEvent(
      guardId: widget.user.id,
      fromDate: startDate.subtract(const Duration(days: 7)),
      toDate: endDate.add(const Duration(days: 7)),
    ));
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
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCalendarContent(context, responsive),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: responsive.isWearable ? null : _buildFAB(context),
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
                  'Guard Calendar',
                  style: responsive.getTitleStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusIndicator(
                isOnline: !widget.isOffline,
                size: responsive.iconSize,
              ),
              responsive.smallHorizontalSpacer,
              IconButton(
                onPressed: () => _showCalendarOptions(context),
                icon: const Icon(Icons.more_vert),
                color: Colors.white,
              ),
            ],
          ),
          responsive.smallSpacer,
          Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.white.withValues(alpha: 0.8),
                size: responsive.iconSize,
              ),
              responsive.smallHorizontalSpacer,
              Text(
                '${widget.user.firstName} ${widget.user.lastName}',
                style: responsive.getBodyStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
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
              'Offline Mode - Showing cached calendar data',
              style: responsive.getCaptionStyle(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContent(BuildContext context, ResponsiveUtils responsive) {
    return BlocConsumer<RosterBloc, RosterState>(
      listener: (context, state) {
        if (state is RosterLoaded) {
          _updateSelectedDayDuties(state.data);
        } else if (state is RosterError && !widget.isOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load calendar: ${state.message}'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is RosterLoading && !_isLoadingMore) {
          return const LoadingOverlay(message: 'Loading calendar...');
        }

        if (state is RosterError && state.data.isEmpty) {
          return _buildErrorState(context, responsive, state.message);
        }

        final duties = state is RosterLoaded ? state.data : <ComprehensiveGuardDutyResponseModel>[];
        
        return Column(
          children: [
            _buildCalendar(context, responsive, duties),
            responsive.smallSpacer,
            Expanded(
              child: _buildDutyList(context, responsive),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendar(BuildContext context, ResponsiveUtils responsive,
      List<ComprehensiveGuardDutyResponseModel> duties) {
    final theme = Theme.of(context);

    if (responsive.isWearable) {
      return _buildWearableCalendar(context, responsive, duties);
    }

    return Container(
      margin: responsive.containerPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<ComprehensiveGuardDutyResponseModel>(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: (day) => _getEventsForDay(day, duties),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: responsive.getCaptionStyle(
            color: theme.colorScheme.error,
          ),
          holidayTextStyle: responsive.getCaptionStyle(
            color: theme.colorScheme.error,
          ),
          defaultTextStyle: responsive.getCaptionStyle(),
          selectedTextStyle: responsive.getCaptionStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          todayTextStyle: responsive.getCaptionStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: AppTheme.successGreen,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: !responsive.isWearable,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(responsive.borderRadius / 2),
          ),
          formatButtonTextStyle: responsive.getCaptionStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          titleTextStyle: responsive.getTitleStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: responsive.getCaptionStyle(
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: responsive.getCaptionStyle(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        onDaySelected: _onDaySelected,
        onPageChanged: _onPageChanged,
        onFormatChanged: _onFormatChanged,
      ),
    );
  }

  Widget _buildWearableCalendar(BuildContext context, ResponsiveUtils responsive,
      List<ComprehensiveGuardDutyResponseModel> duties) {
    final theme = Theme.of(context);
    final weekDays = _getWeekDays(_focusedDay);

    return Container(
      height: 120,
      margin: responsive.containerPadding,
      child: Column(
        children: [
          // Month/Year header
          Container(
            padding: EdgeInsets.symmetric(vertical: responsive.smallSpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _navigateMonth(-1),
                  icon: Icon(Icons.chevron_left, size: responsive.iconSize),
                ),
                Text(
                  _getMonthYearString(_focusedDay),
                  style: responsive.getTitleStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => _navigateMonth(1),
                  icon: Icon(Icons.chevron_right, size: responsive.iconSize),
                ),
              ],
            ),
          ),
          
          // Week view
          Expanded(
            child: Row(
              children: weekDays.map((day) {
                final isSelected = isSameDay(day, _selectedDay);
                final isToday = isSameDay(day, DateTime.now());
                final hasDuty = _getEventsForDay(day, duties).isNotEmpty;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onDaySelected(day, _getEventsForDay(day, duties)),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: responsive.smallSpacing / 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                : null,
                        borderRadius: BorderRadius.circular(responsive.borderRadius / 2),
                        border: hasDuty
                            ? Border.all(color: AppTheme.successGreen, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getDayName(day),
                            style: responsive.getCaptionStyle(
                              color: isSelected ? Colors.white : null,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            day.day.toString(),
                            style: responsive.getBodyStyle(
                              color: isSelected ? Colors.white : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hasDuty)
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : AppTheme.successGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDutyList(BuildContext context, ResponsiveUtils responsive) {
    if (_selectedDayDuties.isEmpty) {
      return _buildEmptyDayState(context, responsive);
    }

    return Container(
      margin: responsive.containerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayHeader(context, responsive),
          responsive.smallSpacer,
          Expanded(
            child: ListView.builder(
              itemCount: _selectedDayDuties.length,
              itemBuilder: (context, index) {
                return DutyCardWidget(
                  duty: _selectedDayDuties[index],
                  isOffline: widget.isOffline,
                  responsive: responsive,
                  onTap: () => _showDutyDetails(context, _selectedDayDuties[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(BuildContext context, ResponsiveUtils responsive) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.event,
          color: theme.colorScheme.primary,
          size: responsive.largeIconSize,
        ),
        responsive.smallHorizontalSpacer,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getSelectedDayString(),
                style: responsive.getTitleStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_selectedDayDuties.length} ${_selectedDayDuties.length == 1 ? 'duty' : 'duties'}',
                style: responsive.getCaptionStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDayState(BuildContext context, ResponsiveUtils responsive) {
    final theme = Theme.of(context);

    return Container(
      margin: responsive.containerPadding,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: responsive.largeIconSize * 2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            responsive.mediumSpacer,
            Text(
              'No duties scheduled',
              style: responsive.getTitleStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            responsive.smallSpacer,
            Text(
              'for ${_getSelectedDayString()}',
              style: responsive.getBodyStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ResponsiveUtils responsive, String message) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: responsive.containerPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: responsive.largeIconSize * 2,
              color: theme.colorScheme.error,
            ),
            responsive.mediumSpacer,
            Text(
              'Failed to load calendar',
              style: responsive.getTitleStyle(
                color: theme.colorScheme.error,
              ),
            ),
            responsive.smallSpacer,
            Text(
              message,
              style: responsive.getBodyStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            responsive.mediumSpacer,
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _navigateToToday(),
      child: const Icon(Icons.today),
    );
  }

  // Helper Methods
  List<ComprehensiveGuardDutyResponseModel> _getEventsForDay(
    DateTime day,
    List<ComprehensiveGuardDutyResponseModel> duties,
  ) {
    return duties.where((duty) {
      final dutyDate = DateTime(
        duty.initialShiftDate.year,
        duty.initialShiftDate.month,
        duty.initialShiftDate.day,
      );
      final targetDate = DateTime(day.year, day.month, day.day);
      return dutyDate == targetDate;
    }).toList();
  }

  void _updateSelectedDayDuties(List<ComprehensiveGuardDutyResponseModel> duties) {
    setState(() {
      _selectedDayDuties = _getEventsForDay(_selectedDay, duties);
    });
  }

  void _onDaySelected(DateTime selectedDay, List<ComprehensiveGuardDutyResponseModel> events) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _selectedDayDuties = events;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    
    // Load data for new month if needed
    final rosterState = context.read<RosterBloc>().state;
    if (rosterState is RosterLoaded) {
      final startDate = DateTime(focusedDay.year, focusedDay.month, 1);
      final endDate = DateTime(focusedDay.year, focusedDay.month + 1, 0);
      
      // Check if we need to load more data
      final hasDataForMonth = rosterState.data.any((duty) {
        final dutyMonth = DateTime(
          duty.initialShiftDate.year,
          duty.initialShiftDate.month,
        );
        final targetMonth = DateTime(focusedDay.year, focusedDay.month);
        return dutyMonth == targetMonth;
      });

      if (!hasDataForMonth && !widget.isOffline) {
        setState(() {
          _isLoadingMore = true;
        });
        
        context.read<RosterBloc>().add(LoadRosterDataPaginatedEvent(
          guardId: widget.user.id,
          fromDate: startDate.subtract(const Duration(days: 7)),
          toDate: endDate.add(const Duration(days: 7)),
        ));
      }
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      setState(() {
        _calendarFormat = format;
      });
    }
  }

  void _navigateMonth(int direction) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + direction, 1);
    });
    _onPageChanged(_focusedDay);
  }

  void _navigateToToday() {
    final today = DateTime.now();
    setState(() {
      _focusedDay = today;
      _selectedDay = today;
    });
    _onPageChanged(today);
    _onDaySelected(today, []);
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getDayName(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }

  String _getSelectedDayString() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    if (selectedDate == today) {
      return 'Today';
    } else if (selectedDate == tomorrow) {
      return 'Tomorrow';
    } else {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[_selectedDay.month - 1]} ${_selectedDay.day}, ${_selectedDay.year}';
    }
  }

  void _showDutyDetails(BuildContext context, ComprehensiveGuardDutyResponseModel duty) {
    Navigator.of(context).pushNamed(
      RouteConstants.dutyDetails,
      arguments: duty,
    );
  }

  void _showCalendarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.responsive.borderRadius),
        ),
      ),
      builder: (context) => Container(
        padding: context.responsive.containerPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Go to Today'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToToday();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Refresh Calendar'),
              onTap: () {
                Navigator.of(context).pop();
                _loadInitialData();
              },
            ),
            if (!widget.isOffline)
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download More Data'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Load more calendar data
                },
              ),
          ],
        ),
      ),
    );
  }
}