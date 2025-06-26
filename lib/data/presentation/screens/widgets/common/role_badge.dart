import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  final bool isActive;

  const RoleBadge({
    Key? key,
    required this.role,
    this.isActive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (role.toLowerCase()) {
      case 'guard':
        backgroundColor = isActive ? AppTheme.successGreen : AppTheme.lightGrey;
        textColor = isActive ? Colors.white : AppTheme.mediumGrey;
        icon = Icons.security;
        break;
      case 'admin':
        backgroundColor = isActive ? AppTheme.primaryTeal : AppTheme.lightGrey;
        textColor = isActive ? Colors.white : AppTheme.mediumGrey;
        icon = Icons.admin_panel_settings;
        break;
      case 'manager':
        backgroundColor = isActive ? AppTheme.secondaryBlue : AppTheme.lightGrey;
        textColor = isActive ? Colors.white : AppTheme.mediumGrey;
        icon = Icons.manage_accounts;
        break;
      case 'supervisor':
        backgroundColor = isActive ? AppTheme.warningOrange : AppTheme.lightGrey;
        textColor = isActive ? Colors.white : AppTheme.mediumGrey;
        icon = Icons.supervisor_account;
        break;
      default:
        backgroundColor = AppTheme.lightGrey;
        textColor = AppTheme.mediumGrey;
        icon = Icons.person;
    }

    final displayRole = role.isNotEmpty 
        ? role[0].toUpperCase() + role.substring(1).toLowerCase()
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: !isActive 
            ? Border.all(color: AppTheme.lightGrey)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            displayRole,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
      