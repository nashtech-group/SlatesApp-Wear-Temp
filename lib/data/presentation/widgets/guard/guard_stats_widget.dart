import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/roster_bloc/roster_bloc.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/utils/status_colors.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/services/date_service.dart';

class GuardStatsWidget extends StatelessWidget {
  final int guardId;
  final RosterState rosterState;
  final bool isCompact;

  const GuardStatsWidget({
    super.key,
    required this.guardId,
    required this.rosterState,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: responsive.containerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, responsive, theme),
            responsive.mediumSpacer,
            _buildStatsContent(context, responsive, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.analytics,
          color: theme.colorScheme.primary,
          size: responsive.iconSize,
        ),
        responsive.smallHorizontalSpacer,
        Expanded(
          child: Text(
            isCompact ? 'Stats' : 'Guard Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (rosterState is RosterLoaded)
          _buildLastUpdatedInfo(context, responsive, theme),
      ],
    );
  }

  Widget _buildLastUpdatedInfo(
      BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    final loadedState = rosterState as RosterLoaded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.smallSpacing,
        vertical: responsive.smallSpacing * 0.5,
      ),
      decoration: BoxDecoration(
        color: loadedState.isFromCache
            ? AppTheme.warningOrange.withValues(alpha: 0.1)
            : theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius * 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            loadedState.isFromCache ? Icons.offline_bolt : Icons.cloud_done,
            size: responsive.iconSize * 0.6,
            color: loadedState.isFromCache
                ? AppTheme.warningOrange
                : theme.colorScheme.primary,
          ),
          responsive.smallHorizontalSpacer,
          Text(
            loadedState.formattedLastUpdated,
            style: theme.textTheme.labelSmall?.copyWith(
              color: loadedState.isFromCache
                  ? AppTheme.warningOrange
                  : theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(
      BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    if (rosterState is RosterLoading) {
      return _buildLoadingState(context, responsive, theme);
    }

    if (rosterState is RosterLoaded) {
      final rosterData = (rosterState as RosterLoaded).rosterResponse.data;
      return _buildStatsGrid(context, responsive, theme, rosterData);
    }

    if (rosterState is RosterError) {
      return _buildErrorState(context, responsive, theme);
    }

    return _buildEmptyState(context, responsive, theme);
  }

  Widget _buildLoadingState(
      BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return SizedBox(
      height: isCompact ? 60 : 120,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Container(
      padding: responsive.containerPadding,
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: responsive.iconSize,
          ),
          responsive.smallSpacer,
          Text(
            'Unable to load statistics',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          responsive.smallSpacer,
          ElevatedButton.icon(
            onPressed: () => _refreshStats(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: AppTheme.responsiveDestructiveButtonStyle(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Container(
      padding: responsive.containerPadding,
      child: Column(
        children: [
          Icon(
            Icons.data_usage,
            color: theme.colorScheme.outline,
            size: responsive.iconSize,
          ),
          responsive.smallSpacer,
          Text(
            'No statistics available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme,
    List<RosterUserModel> rosterData,
  ) {
    final stats = _calculateStats(rosterData);

    if (isCompact) {
      return _buildCompactStats(context, responsive, theme, stats);
    }

    return Column(
      children: [
        // Main stats row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                responsive,
                theme,
                'Total Duties',
                stats.totalDuties.toString(),
                Icons.assignment,
                theme.colorScheme.primary,
              ),
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: _buildStatCard(
                context,
                responsive,
                theme,
                'Completed',
                stats.completedDuties.toString(),
                Icons.check_circle,
                StatusColors.getGuardDutyStatusColor(AppConstants.presentStatus),
              ),
            ),
          ],
        ),

        responsive.smallSpacer,

        // Secondary stats row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                responsive,
                theme,
                'Pending',
                stats.pendingDuties.toString(),
                Icons.pending,
                StatusColors.getGuardDutyStatusColor(AppConstants.pendingStatus),
              ),
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: _buildStatCard(
                context,
                responsive,
                theme,
                'Missed',
                stats.missedDuties.toString(),
                Icons.cancel,
                StatusColors.getGuardDutyStatusColor(AppConstants.absentStatus),
              ),
            ),
          ],
        ),

        responsive.mediumSpacer,

        // Additional insights
        _buildAdditionalInsights(context, responsive, theme, stats, rosterData),
      ],
    );
  }

  Widget _buildCompactStats(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme,
    GuardStats stats,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactStatItem(
            context,
            responsive,
            theme,
            stats.totalDuties.toString(),
            'Total',
            theme.colorScheme.primary,
          ),
        ),
        Expanded(
          child: _buildCompactStatItem(
            context,
            responsive,
            theme,
            stats.completedDuties.toString(),
            'Done',
            StatusColors.getGuardDutyStatusColor(AppConstants.presentStatus),
          ),
        ),
        Expanded(
          child: _buildCompactStatItem(
            context,
            responsive,
            theme,
            stats.pendingDuties.toString(),
            'Pending',
            StatusColors.getGuardDutyStatusColor(AppConstants.pendingStatus),
          ),
        ),
        Expanded(
          child: _buildCompactStatItem(
            context,
            responsive,
            theme,
            '${stats.completionRate}%',
            'Rate',
            StatusColors.getCompletionRateColor(stats.completionRate.toDouble()),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: responsive.containerPadding,
      decoration: StatusColors.getStatusIndicatorDecoration(
        color: color,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: responsive.iconSize,
          ),
          responsive.smallSpacer,
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInsights(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme,
    GuardStats stats,
    List<RosterUserModel> rosterData,
  ) {
    return Container(
      padding: responsive.containerPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: theme.colorScheme.primary,
                size: responsive.iconSize * 0.8,
              ),
              responsive.smallHorizontalSpacer,
              Text(
                'Insights',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          responsive.smallSpacer,
          _buildInsightRow(
            context,
            responsive,
            theme,
            'Completion Rate',
            '${stats.completionRate}%',
            StatusColors.getCompletionRateColor(stats.completionRate.toDouble()),
          ),
          _buildInsightRow(
            context,
            responsive,
            theme,
            'Most Active Site',
            stats.mostActiveSite,
            theme.colorScheme.primary,
          ),
          _buildInsightRow(
            context,
            responsive,
            theme,
            'Total Hours',
            '${stats.totalHours}h',
            theme.colorScheme.secondary,
          ),
          if (stats.avgDutiesPerWeek > 0)
            _buildInsightRow(
              context,
              responsive,
              theme,
              'Avg/Week',
              stats.avgDutiesPerWeek.toStringAsFixed(1),
              theme.colorScheme.tertiary,
            ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.smallSpacing * 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  GuardStats _calculateStats(List<RosterUserModel> rosterData) {
    if (rosterData.isEmpty) {
      return const GuardStats(
        totalDuties: 0,
        completedDuties: 0,
        pendingDuties: 0,
        missedDuties: 0,
        completionRate: 0,
        mostActiveSite: 'N/A',
        totalHours: 0,
        avgDutiesPerWeek: 0,
      );
    }

    final total = rosterData.length;
    final completed = rosterData.where((duty) => duty.status == AppConstants.presentStatus).length;
    final pending = rosterData.where((duty) => duty.status == AppConstants.pendingStatus).length;
    final missed = rosterData.where((duty) => duty.status == AppConstants.absentStatus).length;

    final completionRate = total > 0 ? ((completed / total) * 100).round() : 0;

    // Calculate most active site
    final siteFrequency = <String, int>{};
    for (final duty in rosterData) {
      final siteName = duty.site.name;
      siteFrequency[siteName] = (siteFrequency[siteName] ?? 0) + 1;
    }

    final mostActiveSite = siteFrequency.isNotEmpty
        ? siteFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'N/A';

    // Calculate total hours
    var totalHours = 0;
    for (final duty in rosterData) {
      if (duty.status == AppConstants.presentStatus) {
        final duration = duty.endsAt.difference(duty.startsAt);
        totalHours += duration.inHours;
      }
    }

    // Calculate average duties per week
    double avgDutiesPerWeek = 0;
    if (rosterData.isNotEmpty) {
      final firstDuty = rosterData.last.initialShiftDate;
      final lastDuty = rosterData.first.initialShiftDate;
      final weeksDifference = lastDuty.difference(firstDuty).inDays / 7;
      avgDutiesPerWeek =
          weeksDifference > 0 ? total / weeksDifference : total.toDouble();
    }

    return GuardStats(
      totalDuties: total,
      completedDuties: completed,
      pendingDuties: pending,
      missedDuties: missed,
      completionRate: completionRate,
      mostActiveSite: mostActiveSite,
      totalHours: totalHours,
      avgDutiesPerWeek: avgDutiesPerWeek,
    );
  }

  void _refreshStats(BuildContext context) {
    context.read<RosterBloc>().add(
          LoadRosterData(
            guardId: guardId,
            forceRefresh: true,
          ),
        );
  }
}

// Data class for guard statistics
class GuardStats {
  final int totalDuties;
  final int completedDuties;
  final int pendingDuties;
  final int missedDuties;
  final int completionRate;
  final String mostActiveSite;
  final int totalHours;
  final double avgDutiesPerWeek;

  const GuardStats({
    required this.totalDuties,
    required this.completedDuties,
    required this.pendingDuties,
    required this.missedDuties,
    required this.completionRate,
    required this.mostActiveSite,
    required this.totalHours,
    required this.avgDutiesPerWeek,
  });
}