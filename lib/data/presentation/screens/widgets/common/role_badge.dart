import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  final bool compact;

  const RoleBadge({
    Key? key,
    required this.role,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWearable = screenSize.width < 250 || screenSize.height < 250;
    final isCompact = compact || isWearable;
    
    final displayRole = AppConstants.getRoleDisplayName(role);
    final badgeColor = _getRoleColor();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
        border: Border.all(
          color: badgeColor.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(),
            color: badgeColor,
            size: isCompact ? 10 : 12,
          ),
          SizedBox(width: isCompact ? 3 : 4),
          Text(
            isCompact && role == AppConstants.guardRole ? 'Guard' : displayRole,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 9 : 11,
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

