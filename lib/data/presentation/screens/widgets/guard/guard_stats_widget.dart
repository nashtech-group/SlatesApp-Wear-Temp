import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slates_app_wear/blocs/roster_bloc/roster_bloc.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_response_model.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/common/animated_counter.dart';

class GuardStatsWidget extends StatefulWidget {
  final UserModel user;
  final bool isOffline;
  final RosterState rosterState;
  final ResponsiveUtils responsive;
  final bool showDetailed;

  const GuardStatsWidget({
    super.key,
    required this.user,
    required this.isOffline,
    required this.rosterState,
    required this.responsive,
    this.showDetailed = true,
  });

  @override
  State<GuardStatsWidget> createState() => _GuardStatsWidgetState();
}

class _GuardStatsWidgetState extends State<GuardStatsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _statAnimations;
  
  GuardStats? _stats;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _calculateStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GuardStatsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rosterState != widget.rosterState) {
      _calculateStats();
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create staggered animations for stats
    _statAnimations = List.generate(6, (index) {
      final start = index * 0.1;
      final end = start + 0.4;
      
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      ));
    });

    _animationController.forward();
  }

  void _calculateStats() {
    if (widget.rosterState is RosterLoaded) {
      final duties = (widget.rosterState as RosterLoaded).data;
      setState(() {
        _stats = GuardStats.fromDuties(duties);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: widget.responsive.containerPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(widget.responsive.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, theme),
          widget.responsive.mediumSpacer,
          if (_stats != null) ...[
            if (widget.responsive.isWearable)
              _buildWearableStats(context, theme)
            else
              _buildMobileStats(context, theme),
          ] else
            _buildLoadingState(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.analytics,
          color: theme.colorScheme.primary,
          size: widget.responsive.largeIconSize,
        ),
        widget.responsive.smallHorizontalSpacer,
        Expanded(
          child: Text(
            'Performance Stats',
            style: widget.responsive.getTitleStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (widget.isOffline)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.responsive.smallSpacing,
              vertical: widget.responsive.smallSpacing / 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(widget.responsive.borderRadius / 2),
            ),
            child: Text(
              'CACHED',
              style: widget.responsive.getCaptionStyle(
                color: AppTheme.warningOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWearableStats(BuildContext context, ThemeData theme) {
    final primaryStats = _getPrimaryStats();
    
    return Column(
      children: [
        // Primary stats in a row
        Row(
          children: primaryStats.take(2).map((stat) {
            final index = primaryStats.indexOf(stat);
            return Expanded(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(index.isEven ? -1 : 1, 0),
                  end: Offset.zero,
                ).animate(_statAnimations[index]),
                child: _buildStatCard(context, theme, stat, isCompact: true),
              ),
            );
          }).toList(),
        ),
        widget.responsive.smallSpacer,
        
        // Secondary stats
        Row(
          children: primaryStats.skip(2).take(2).map((stat) {
            final index = primaryStats.indexOf(stat);
            return Expanded(
              child: FadeTransition(
                opacity: _statAnimations[index],
                child: _buildStatCard(context, theme, stat, isCompact: true),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMobileStats(BuildContext context, ThemeData theme) {
    final allStats = widget.showDetailed ? _getAllStats() : _getPrimaryStats();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.responsive.isTablet ? 3 : 2,
        crossAxisSpacing: widget.responsive.smallSpacing,
        mainAxisSpacing: widget.responsive.smallSpacing,
        childAspectRatio: widget.responsive.getResponsiveValue(
          wearable: 1.0,
          smallMobile: 1.2,
          mobile: 1.3,
          tablet: 1.4,
        ),
      ),
      itemCount: allStats.length,
      itemBuilder: (context, index) {
        if (index >= _statAnimations.length) {
          return _buildStatCard(context, theme, allStats[index]);
        }
        
        return ScaleTransition(
          scale: _statAnimations[index],
          child: _buildStatCard(context, theme, allStats[index]),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, ThemeData theme, StatItem stat,
      {bool isCompact = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: widget.responsive.smallSpacing / 2),
      padding: widget.responsive.getResponsiveValue(
        wearable: const EdgeInsets.all(8),
        smallMobile: const EdgeInsets.all(10),
        mobile: const EdgeInsets.all(12),
        tablet: const EdgeInsets.all(14),
      ),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(widget.responsive.borderRadius / 2),
        border: Border.all(
          color: stat.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            stat.icon,
            color: stat.color,
            size: widget.responsive.getResponsiveValue(
              wearable: 16.0,
              smallMobile: 18.0,
              mobile: 20.0,
              tablet: 24.0,
            ),
          ),
          widget.responsive.smallSpacer,
          
          if (stat.isPercentage)
            CircularAnimatedCounter(
              value: stat.value,
              maxValue: 100,
              size: widget.responsive.getResponsiveValue(
                wearable: 40.0,
                smallMobile: 45.0,
                mobile: 50.0,
                tablet: 55.0,
              ),
              strokeWidth: widget.responsive.getResponsiveValue(
                wearable: 3.0,
                smallMobile: 3.5,
                mobile: 4.0,
                tablet: 4.5,
              ),
              progressColor: stat.color,
              textStyle: widget.responsive.getCaptionStyle(
                fontWeight: FontWeight.bold,
              ),
            )
          else
            FlexibleAnimatedCounter(
              value: stat.value,
              format: stat.format,
              textStyle: widget.responsive.getBodyStyle(
                fontWeight: FontWeight.bold,
                color: stat.color,
              ),
            ),
          
          widget.responsive.smallSpacer,
          Text(
            stat.label,
            style: widget.responsive.getCaptionStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: isCompact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          if (stat.subtitle != null && !isCompact) ...[
            widget.responsive.smallSpacer,
            Text(
              stat.subtitle!,
              style: widget.responsive.getCaptionStyle(
                color: theme.colorScheme.onSurfaceVariant,
              )?.copyWith(fontSize: widget.responsive.getCaptionStyle()?.fontSize! - 1),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Row(
          children: List.generate(2, (index) {
            return Expanded(
              child: Container(
                height: 80,
                margin: EdgeInsets.symmetric(horizontal: widget.responsive.smallSpacing / 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(widget.responsive.borderRadius / 2),
                ),
              ),
            );
          }),
        ),
        widget.responsive.smallSpacer,
        Row(
          children: List.generate(2, (index) {
            return Expanded(
              child: Container(
                height: 80,
                margin: EdgeInsets.symmetric(horizontal: widget.responsive.smallSpacing / 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(widget.responsive.borderRadius / 2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  List<StatItem> _getPrimaryStats() {
    if (_stats == null) return [];
    
    return [
      StatItem(
        label: 'Total Shifts',
        value: _stats!.totalShifts.toDouble(),
        icon: Icons.work,
        color: AppTheme.primaryTeal,
        format: CounterFormat.integer,
      ),
      StatItem(
        label: 'Completed',
        value: _stats!.completionRate,
        icon: Icons.check_circle,
        color: AppTheme.successGreen,
        isPercentage: true,
      ),
      StatItem(
        label: 'Hours Worked',
        value: _stats!.totalHours,
        icon: Icons.schedule,
        color: AppTheme.secondaryBlue,
        format: CounterFormat.time,
      ),
      StatItem(
        label: 'Checkpoints',
        value: _stats!.totalCheckpoints.toDouble(),
        icon: Icons.location_on,
        color: AppTheme.warningOrange,
        format: CounterFormat.integer,
      ),
    ];
  }

  List<StatItem> _getAllStats() {
    if (_stats == null) return [];
    
    return [
      ..._getPrimaryStats(),
      StatItem(
        label: 'On Time Rate',
        value: _stats!.punctualityRate,
        icon: Icons.access_time,
        color: AppTheme.accentCyan,
        isPercentage: true,
        subtitle: 'Punctuality',
      ),
      StatItem(
        label: 'Sites Covered',
        value: _stats!.uniqueSites.toDouble(),
        icon: Icons.location_city,
        color: AppTheme.primaryTeal,
        format: CounterFormat.integer,
        subtitle: 'Different locations',
      ),
    ];
  }
}

/// Compact stats widget for dashboard
class CompactGuardStats extends StatelessWidget {
  final UserModel user;
  final bool isOffline;
  final RosterState rosterState;
  final int maxStats;

  const CompactGuardStats({
    super.key,
    required this.user,
    required this.isOffline,
    required this.rosterState,
    this.maxStats = 3,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return GuardStatsWidget(
      user: user,
      isOffline: isOffline,
      rosterState: rosterState,
      responsive: responsive,
      showDetailed: false,
    );
  }
}

/// Stats summary for quick overview
class StatsSummaryWidget extends StatelessWidget {
  final GuardStats stats;
  final bool isHorizontal;

  const StatsSummaryWidget({
    super.key,
    required this.stats,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    final summaryItems = [
      _SummaryItem(
        label: 'Shifts',
        value: stats.totalShifts.toString(),
        color: AppTheme.primaryTeal,
      ),
      _SummaryItem(
        label: 'Completion',
        value: '${stats.completionRate.toInt()}%',
        color: AppTheme.successGreen,
      ),
      _SummaryItem(
        label: 'Hours',
        value: stats.totalHours.toInt().toString(),
        color: AppTheme.secondaryBlue,
      ),
    ];

    if (isHorizontal) {
      return Row(
        children: summaryItems.map((item) {
          return Expanded(
            child: _buildSummaryItem(context, responsive, theme, item),
          );
        }).toList(),
      );
    }

    return Column(
      children: summaryItems.map((item) {
        return _buildSummaryItem(context, responsive, theme, item);
      }).toList(),
    );
  }

  Widget _buildSummaryItem(BuildContext context, ResponsiveUtils responsive,
      ThemeData theme, _SummaryItem item) {
    return Container(
      padding: responsive.getResponsiveValue(
        wearable: const EdgeInsets.all(8),
        smallMobile: const EdgeInsets.all(10),
        mobile: const EdgeInsets.all(12),
        tablet: const EdgeInsets.all(14),
      ),
      child: Column(
        children: [
          Text(
            item.value,
            style: responsive.getTitleStyle(
              color: item.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            item.label,
            style: responsive.getCaptionStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Data classes
class GuardStats {
  final int totalShifts;
  final int completedShifts;
  final double totalHours;
  final int totalCheckpoints;
  final int uniqueSites;
  final int onTimeShifts;

  const GuardStats({
    required this.totalShifts,
    required this.completedShifts,
    required this.totalHours,
    required this.totalCheckpoints,
    required this.uniqueSites,
    required this.onTimeShifts,
  });

  double get completionRate {
    if (totalShifts == 0) return 0.0;
    return (completedShifts / totalShifts) * 100;
  }

  double get punctualityRate {
    if (totalShifts == 0) return 0.0;
    return (onTimeShifts / totalShifts) * 100;
  }

  static GuardStats fromDuties(List<ComprehensiveGuardDutyResponseModel> duties) {
    final total = duties.length;
    final completed = duties.where((d) => d.statusLabel?.toLowerCase() != 'absent').length;
    final totalHours = duties.fold<double>(0, (sum, duty) {
      return sum + duty.endsAt.difference(duty.startsAt).inMinutes / 60.0;
    });
    
    final checkpoints = duties.fold<int>(0, (sum, duty) {
      return sum + (duty.site?.perimeters
          ?.expand((p) => p.checkPoints ?? [])
          .length ?? 0);
    });
    
    final sites = duties.map((d) => d.site?.id).where((id) => id != null).toSet().length;
    
    // Calculate on-time based on some logic (placeholder)
    final onTime = duties.where((d) => 
        d.statusLabel?.toLowerCase() != 'absent' && 
        d.statusLabel?.toLowerCase() != 'late'
    ).length;

    return GuardStats(
      totalShifts: total,
      completedShifts: completed,
      totalHours: totalHours,
      totalCheckpoints: checkpoints,
      uniqueSites: sites,
      onTimeShifts: onTime,
    );
  }
}

class StatItem {
  final String label;
  final String? subtitle;
  final double value;
  final IconData icon;
  final Color color;
  final CounterFormat format;
  final bool isPercentage;

  const StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.format = CounterFormat.integer,
    this.isPercentage = false,
  });
}

class _SummaryItem {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });
}