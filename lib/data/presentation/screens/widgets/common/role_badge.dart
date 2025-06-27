// lib/data/presentation/widgets/role_badge.dart
import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';

enum RoleBadgeSize { small, medium, large }

class RoleBadge extends StatelessWidget {
  final String role;
  final bool isActive;
  final RoleBadgeSize size;
  final bool showIcon;
  final bool outlined;

  const RoleBadge({
    Key? key,
    required this.role,
    this.isActive = true,
    this.size = RoleBadgeSize.medium,
    this.showIcon = true,
    this.outlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorData = _getRoleColorData(role, isActive, theme);
    final sizeData = _getSizeData(size);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizeData.horizontalPadding,
        vertical: sizeData.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : colorData.backgroundColor,
        borderRadius: BorderRadius.circular(sizeData.borderRadius),
        border: outlined || !isActive 
            ? Border.all(
                color: colorData.borderColor,
                width: outlined ? 1.5 : 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              colorData.icon,
              size: sizeData.iconSize,
              color: colorData.textColor,
            ),
            SizedBox(width: sizeData.spacing),
          ],
          Text(
            _getDisplayRole(role),
            style: TextStyle(
              color: colorData.textColor,
              fontSize: sizeData.fontSize,
              fontWeight: sizeData.fontWeight,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  _RoleColorData _getRoleColorData(String role, bool isActive, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    IconData icon;

    switch (role.toLowerCase()) {
      case 'guard':
        backgroundColor = isActive 
            ? AppTheme.successGreen 
            : (isDark ? AppTheme.successGreen.withValues(alpha:0.2) : AppTheme.lightGrey);
        textColor = isActive 
            ? Colors.white 
            : (isDark ? AppTheme.successGreen : AppTheme.mediumGrey);
        borderColor = AppTheme.successGreen;
        icon = Icons.security;
        break;
        
      case 'admin':
        backgroundColor = isActive 
            ? AppTheme.primaryTeal 
            : (isDark ? AppTheme.primaryTeal.withValues(alpha:0.2) : AppTheme.lightGrey);
        textColor = isActive 
            ? Colors.white 
            : (isDark ? AppTheme.primaryTeal : AppTheme.mediumGrey);
        borderColor = AppTheme.primaryTeal;
        icon = Icons.admin_panel_settings;
        break;
        
      case 'manager':
        backgroundColor = isActive 
            ? AppTheme.secondaryBlue 
            : (isDark ? AppTheme.secondaryBlue.withValues(alpha:0.2) : AppTheme.lightGrey);
        textColor = isActive 
            ? Colors.white 
            : (isDark ? AppTheme.secondaryBlue : AppTheme.mediumGrey);
        borderColor = AppTheme.secondaryBlue;
        icon = Icons.manage_accounts;
        break;
        
      case 'supervisor':
        backgroundColor = isActive 
            ? AppTheme.warningOrange 
            : (isDark ? AppTheme.warningOrange.withValues(alpha:0.2) : AppTheme.lightGrey);
        textColor = isActive 
            ? Colors.white 
            : (isDark ? AppTheme.warningOrange : AppTheme.mediumGrey);
        borderColor = AppTheme.warningOrange;
        icon = Icons.supervisor_account;
        break;
        
      case 'executive':
        backgroundColor = isActive 
            ? AppTheme.accentCyan 
            : (isDark ? AppTheme.accentCyan.withValues(alpha:0.2) : AppTheme.lightGrey);
        textColor = isActive 
            ? Colors.white 
            : (isDark ? AppTheme.accentCyan : AppTheme.mediumGrey);
        borderColor = AppTheme.accentCyan;
        icon = Icons.business_center;
        break;
        
      default:
        backgroundColor = isActive 
            ? theme.colorScheme.primary 
            : (isDark ? theme.colorScheme.primary.withValues(alpha:0.2) : AppTheme.lightGrey);
        textColor = isActive 
            ? Colors.white 
            : (isDark ? theme.colorScheme.primary : AppTheme.mediumGrey);
        borderColor = theme.colorScheme.primary;
        icon = Icons.person;
    }

    // Handle outlined style
    if (outlined) {
      backgroundColor = Colors.transparent;
      textColor = borderColor;
    }

    return _RoleColorData(
      backgroundColor: backgroundColor,
      textColor: textColor,
      borderColor: borderColor,
      icon: icon,
    );
  }

  _RoleSizeData _getSizeData(RoleBadgeSize size) {
    switch (size) {
      case RoleBadgeSize.small:
        return const _RoleSizeData(
          fontSize: 10,
          iconSize: 12,
          horizontalPadding: 8,
          verticalPadding: 4,
          borderRadius: 16,
          spacing: 4,
          fontWeight: FontWeight.w500,
        );
        
      case RoleBadgeSize.medium:
        return const _RoleSizeData(
          fontSize: 12,
          iconSize: 16,
          horizontalPadding: 12,
          verticalPadding: 6,
          borderRadius: 20,
          spacing: 6,
          fontWeight: FontWeight.w600,
        );
        
      case RoleBadgeSize.large:
        return const _RoleSizeData(
          fontSize: 14,
          iconSize: 18,
          horizontalPadding: 16,
          verticalPadding: 8,
          borderRadius: 24,
          spacing: 8,
          fontWeight: FontWeight.w600,
        );
    }
  }

  String _getDisplayRole(String role) {
    if (role.isEmpty) return 'Unknown';
    
    // Use the app constants method for consistent role display
    return AppConstants.getRoleDisplayName(role);
  }

  // Factory constructors for common role badges
  factory RoleBadge.guard({
    bool isActive = true,
    RoleBadgeSize size = RoleBadgeSize.medium,
    bool showIcon = true,
    bool outlined = false,
  }) {
    return RoleBadge(
      role: AppConstants.guardRole,
      isActive: isActive,
      size: size,
      showIcon: showIcon,
      outlined: outlined,
    );
  }

  factory RoleBadge.admin({
    bool isActive = true,
    RoleBadgeSize size = RoleBadgeSize.medium,
    bool showIcon = true,
    bool outlined = false,
  }) {
    return RoleBadge(
      role: AppConstants.adminRole,
      isActive: isActive,
      size: size,
      showIcon: showIcon,
      outlined: outlined,
    );
  }

  factory RoleBadge.manager({
    bool isActive = true,
    RoleBadgeSize size = RoleBadgeSize.medium,
    bool showIcon = true,
    bool outlined = false,
  }) {
    return RoleBadge(
      role: AppConstants.managerRole,
      isActive: isActive,
      size: size,
      showIcon: showIcon,
      outlined: outlined,
    );
  }

  factory RoleBadge.supervisor({
    bool isActive = true,
    RoleBadgeSize size = RoleBadgeSize.medium,
    bool showIcon = true,
    bool outlined = false,
  }) {
    return RoleBadge(
      role: AppConstants.supervisorRole,
      isActive: isActive,
      size: size,
      showIcon: showIcon,
      outlined: outlined,
    );
  }

  // Static method to get role color for consistency across the app
  static Color getRoleColor(String role, {bool isActive = true}) {
    switch (role.toLowerCase()) {
      case 'guard':
        return isActive ? AppTheme.successGreen : AppTheme.lightGrey;
      case 'admin':
        return isActive ? AppTheme.primaryTeal : AppTheme.lightGrey;
      case 'manager':
        return isActive ? AppTheme.secondaryBlue : AppTheme.lightGrey;
      case 'supervisor':
        return isActive ? AppTheme.warningOrange : AppTheme.lightGrey;
      case 'executive':
        return isActive ? AppTheme.accentCyan : AppTheme.lightGrey;
      default:
        return AppTheme.lightGrey;
    }
  }

  // Static method to get role icon
  static IconData getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'guard':
        return Icons.security;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.manage_accounts;
      case 'supervisor':
        return Icons.supervisor_account;
      case 'executive':
        return Icons.business_center;
      default:
        return Icons.person;
    }
  }

  // Method to check if role has elevated privileges
  bool get hasElevatedPrivileges {
    return AppConstants.hasAdminPrivileges(role);
  }

  // Method to get role priority (for sorting)
  int get rolePriority {
    switch (role.toLowerCase()) {
      case 'executive':
        return 1;
      case 'admin':
        return 2;
      case 'manager':
        return 3;
      case 'supervisor':
        return 4;
      case 'guard':
        return 5;
      default:
        return 6;
    }
  }
}

// Data classes for role styling
class _RoleColorData {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final IconData icon;

  const _RoleColorData({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.icon,
  });
}

class _RoleSizeData {
  final double fontSize;
  final double iconSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double spacing;
  final FontWeight fontWeight;

  const _RoleSizeData({
    required this.fontSize,
    required this.iconSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
    required this.spacing,
    required this.fontWeight,
  });
}

// Extension for theme-aware role badge styling
extension RoleBadgeTheme on BuildContext {
  Color getRoleBackgroundColor(String role, {bool isActive = true}) {
    final theme = Theme.of(this);
    final isDark = theme.brightness == Brightness.dark;
    
    if (!isActive) {
      return isDark 
          ? theme.colorScheme.surfaceContainerHighest 
          : AppTheme.lightGrey;
    }
    
    return RoleBadge.getRoleColor(role, isActive: isActive);
  }

  Color getRoleTextColor(String role, {bool isActive = true, bool outlined = false}) {
    Theme.of(this);
    
    if (outlined || !isActive) {
      return RoleBadge.getRoleColor(role, isActive: true);
    }
    
    return Colors.white;
  }
}