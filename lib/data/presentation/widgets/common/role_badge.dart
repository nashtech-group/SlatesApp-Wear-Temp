import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  final bool compact;

  const RoleBadge({
    super.key,
    required this.role,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isCompact = compact || responsive.isWearable;
    
    final displayRole = AppConstants.getRoleDisplayName(role);
    final badgeColor = _getRoleColor();
    
    return Container(
      padding: responsive.badgePadding,
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(),
            color: badgeColor,
            size: responsive.badgeIconSize,
          ),
          SizedBox(width: responsive.smallSpacing * 0.5),
          Text(
            isCompact && role == AppConstants.guardRole ? 'Guard' : displayRole,
            style: responsive.getCaptionStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              baseFontSize: responsive.badgeTextSize,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor() {
    switch (role.toLowerCase()) {
      case AppConstants.guardRole:
        return AppTheme.primaryTeal;
      case AppConstants.adminRole:
        return AppTheme.errorRed;
      case AppConstants.managerRole:
        return AppTheme.secondaryBlue;
      case AppConstants.supervisorRole:
        return AppTheme.warningOrange;
      default:
        return AppTheme.mediumGrey;
    }
  }

  IconData _getRoleIcon() {
    switch (role.toLowerCase()) {
      case AppConstants.guardRole:
        return Icons.security;
      case AppConstants.adminRole:
        return Icons.admin_panel_settings;
      case AppConstants.managerRole:
        return Icons.business_center;
      case AppConstants.supervisorRole:
        return Icons.supervisor_account;
      default:
        return Icons.person;
    }
  }
}