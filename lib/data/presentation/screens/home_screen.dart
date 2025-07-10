// lib/data/presentation/pages/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/auth_bloc/auth_bloc.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/constants/api_constants.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/theme/theme_provider.dart';
import 'package:slates_app_wear/core/error/common_error_states.dart';
import 'package:slates_app_wear/core/error/error_handler.dart';
import 'package:slates_app_wear/core/error/error_state_factory.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';
import 'package:slates_app_wear/data/presentation/screens/error_screen.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/common/app_logo.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/common/role_badge.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/wearable/large_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _greetingController;
  late Animation<double> _greetingAnimation;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    // Check auth status when screen loads
    context.read<AuthBloc>().add(const CheckAuthStatusEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _greetingController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _greetingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _greetingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeInOut,
    ));

    _greetingController.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes for security
    if (state == AppLifecycleState.resumed) {
      context.read<AuthBloc>().add(const CheckAuthStatusEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteConstants.login,
            (Route<dynamic> route) => false,
          );
        } else if (state is AuthSessionExpired) {
          ErrorScreen.showErrorDialog(
            context,
            errorState: SessionExpiredErrorState(
              errorInfo: BlocErrorInfo(
                type: ErrorType.authentication,
                message: state.message,
                statusCode: ApiConstants.unauthorizedCode,
              ),
            ),
            onRetry: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                RouteConstants.login,
                (Route<dynamic> route) => false,
              );
            },
          );
        } else if (state is AuthError) {
          ErrorScreen.showErrorSnackBar(
            context,
            errorState: ErrorStateFactory.createFromDynamicError(
              state,
              context: 'AuthBloc Error',
              additionalData: {'errorCode': state.errorCode},
            ),
            onRetry: () {
              context.read<AuthBloc>().add(const CheckAuthStatusEvent());
            },
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return const _LoadingHomeScreen();
        }

        if (state is AuthAuthenticated) {
          return _AuthenticatedHomeScreen(
            user: state.user,
            isOffline: state.isOffline,
            selectedIndex: _selectedIndex,
            onIndexChanged: (index) => setState(() => _selectedIndex = index),
            greetingAnimation: _greetingAnimation,
          );
        }

        if (state is AuthOfflineMode) {
          return _AuthenticatedHomeScreen(
            user: state.user,
            isOffline: true,
            selectedIndex: _selectedIndex,
            onIndexChanged: (index) => setState(() => _selectedIndex = index),
            greetingAnimation: _greetingAnimation,
          );
        }

        if (state is AuthError) {
          return ErrorScreen(
            errorState: ErrorStateFactory.createFromDynamicError(
              state,
              context: 'Authentication Error',
              additionalData: {
                'message': state.message,
                'errorCode': state.errorCode,
              },
            ),
            onRetry: () {
              context.read<AuthBloc>().add(const CheckAuthStatusEvent());
            },
          );
        }

        // Fallback to login if no valid state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteConstants.login,
            (Route<dynamic> route) => false,
          );
        });

        return const SizedBox.shrink();
      },
    );
  }
}

// Loading screen component
class _LoadingHomeScreen extends StatelessWidget {
  const _LoadingHomeScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        centerTitle: true,
      ),
      body: Container(
        decoration: AppTheme.getBrandGradientDecoration(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Authenticated home screen
class _AuthenticatedHomeScreen extends StatelessWidget {
  final UserModel user;
  final bool isOffline;
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final Animation<double> greetingAnimation;

  const _AuthenticatedHomeScreen({
    required this.user,
    required this.isOffline,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.greetingAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar with user info
            _buildCustomAppBar(context),

            // Offline mode banner
            if (isOffline) _buildOfflineBanner(context),

            // Main content
            Expanded(child: _buildMainContent(context)),
          ],
        ),
      ),

      // Bottom navigation for different user roles
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const AppLogo(size: 40, showText: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getLogoTextColor(context),
                  ),
                ),
                if (isOffline)
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Offline Mode',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Theme toggle button
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<ThemeProvider>().toggleTheme();
            },
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle Theme',
          ),

          // User menu
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user.initials,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (value) => _handleMenuSelection(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: theme.colorScheme.onSurface),
                    const SizedBox(width: 12),
                    const Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: theme.colorScheme.onSurface),
                    const SizedBox(width: 12),
                    const Text('Settings'),
                  ],
                ),
              ),
              if (isOffline)
                PopupMenuItem(
                  value: 'sync',
                  child: Row(
                    children: [
                      Icon(Icons.sync, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      const Text('Sync Data'),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            color: theme.colorScheme.onErrorContainer,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are in offline mode. Some features may be limited.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _handleMenuSelection(context, 'sync'),
            child: Text(
              'Sync',
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return _DashboardTab(
          user: user,
          isOffline: isOffline,
          greetingAnimation: greetingAnimation,
        );
      case 1:
        if (user.isGuard) {
          return _GuardDutyTab(user: user, isOffline: isOffline);
        } else {
          return _ManagementTab(user: user, isOffline: isOffline);
        }
      case 2:
        return _MoreTab(user: user, isOffline: isOffline);
      default:
        return _DashboardTab(
          user: user,
          isOffline: isOffline,
          greetingAnimation: greetingAnimation,
        );
    }
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final theme = Theme.of(context);

    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
    ];

    if (user.isGuard) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.security),
        label: 'Duty',
      ));
    } else {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.business),
        label: 'Management',
      ));
    }

    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.more_horiz),
      label: 'More',
    ));

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        HapticFeedback.lightImpact();
        onIndexChanged(index);
      },
      items: items,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      backgroundColor: theme.colorScheme.surface,
      elevation: 8,
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        Navigator.of(context).pushNamed(RouteConstants.profile);
        break;
      case 'settings':
        Navigator.of(context).pushNamed(RouteConstants.settings);
        break;
      case 'sync':
        context.read<AuthBloc>().add(const RefreshTokenEvent());
        break;
      case 'logout':
        _showLogoutConfirmation(context);
        break;
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const LogoutEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Dashboard Tab - Shows overview and quick stats
class _DashboardTab extends StatelessWidget {
  final UserModel user;
  final bool isOffline;
  final Animation<double> greetingAnimation;

  const _DashboardTab({
    required this.user,
    required this.isOffline,
    required this.greetingAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting section
          _buildGreeting(context),
          const SizedBox(height: 24),

          // Status Overview
          _buildStatusOverview(context),
          const SizedBox(height: 24),

          // Quick Actions Grid
          _buildQuickActions(context),
          const SizedBox(height: 24),

          // Recent Activity or Current Duty Info
          _buildActivitySection(context),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final theme = Theme.of(context);
    final timeOfDay = DateTime.now().hour;
    String greeting;

    if (timeOfDay < 12) {
      greeting = 'Good Morning';
    } else if (timeOfDay < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return FadeTransition(
      opacity: greetingAnimation,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.fullName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RoleBadge(role: user.role),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverview(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOffline ? Icons.cloud_off : Icons.check_circle,
                  color: isOffline
                      ? theme.colorScheme.error
                      : AppTheme.successGreen,
                ),
                const SizedBox(width: 12),
                Text(
                  isOffline ? 'Working Offline' : 'Connected',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isOffline
                  ? 'You can continue working. Data will sync when connected.'
                  : 'All systems operational. Ready for duty.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    context,
                    'Employee ID',
                    user.employeeId,
                    Icons.badge,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusItem(
                    context,
                    'Department',
                    user.department,
                    Icons.business,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    if (user.isGuard) {
      return _buildGuardQuickActions(context);
    } else {
      return _buildAdminQuickActions(context);
    }
  }

  Widget _buildGuardQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              context,
              'Start Duty',
              Icons.play_circle_filled,
              AppTheme.successGreen,
              () => _showComingSoon(context, 'Start Duty'),
            ),
            _buildActionCard(
              context,
              'Movements',
              Icons.my_location,
              AppTheme.primaryTeal,
              () => _showComingSoon(context, 'Movement Tracking'),
            ),
            _buildActionCard(
              context,
              'Checkpoints',
              Icons.location_on,
              AppTheme.warningOrange,
              () => _showComingSoon(context, 'Checkpoint Scanning'),
            ),
            _buildActionCard(
              context,
              'Emergency',
              Icons.emergency,
              AppTheme.errorRed,
              () => _showEmergencyDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              context,
              'Roster',
              Icons.people,
              AppTheme.primaryTeal,
              () => Navigator.of(context).pushNamed(RouteConstants.roster),
            ),
            _buildActionCard(
              context,
              'Reports',
              Icons.analytics,
              AppTheme.secondaryBlue,
              () => Navigator.of(context).pushNamed(RouteConstants.reports),
            ),
            _buildActionCard(
              context,
              'Sites',
              Icons.location_city,
              AppTheme.warningOrange,
              () => Navigator.of(context)
                  .pushNamed(RouteConstants.siteManagement),
            ),
            _buildActionCard(
              context,
              'Users',
              Icons.manage_accounts,
              AppTheme.accentCyan,
              () => Navigator.of(context)
                  .pushNamed(RouteConstants.userManagement),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.isGuard ? 'Current Duty Status' : 'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                child: Icon(
                  user.isGuard ? Icons.schedule : Icons.notifications,
                  color: AppTheme.primaryTeal,
                ),
              ),
              title: Text(
                user.isGuard ? 'Ready for Duty' : 'System Status Normal',
              ),
              subtitle: Text(
                user.isGuard
                    ? 'Tap "Start Duty" to begin your shift'
                    : 'All operations running smoothly',
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.construction,
              color: AppTheme.warningOrange,
            ),
            SizedBox(width: 12),
            Text('Coming Soon'),
          ],
        ),
        content: Text('$feature feature is under development.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning,
              color: AppTheme.errorRed,
            ),
            SizedBox(width: 12),
            Text('Emergency Alert'),
          ],
        ),
        content: const Text(
          'This will send an emergency alert to your supervisors. '
          'Only use in case of actual emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showComingSoon(context, 'Emergency Alert');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }
}

// Guard Duty Tab - For security guards
class _GuardDutyTab extends StatelessWidget {
  final UserModel user;
  final bool isOffline;

  const _GuardDutyTab({
    required this.user,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guard Duty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),

          // Duty Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppTheme.warningOrange,
                      ),
                      SizedBox(width: 12),
                      Text('Off Duty'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LargeButton(
                    text: 'Start Duty',
                    icon: Icons.play_circle,
                    backgroundColor: AppTheme.successGreen,
                    onPressed: () => _showComingSoon(context, 'Start Duty'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quick Actions for Guards
          _buildGuardActions(context),
        ],
      ),
    );
  }

  Widget _buildGuardActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guard Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  child: const Icon(Icons.my_location, color: AppTheme.primaryTeal),
                ),
                title: const Text('Movement Tracking'),
                subtitle: const Text('Record your patrol movements'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoon(context, 'Movement Tracking'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      AppTheme.warningOrange.withValues(alpha: 0.1),
                  child: const Icon(Icons.location_on, color: AppTheme.warningOrange),
                ),
                title: const Text('Perimeter Checks'),
                subtitle: const Text('Scan checkpoints during patrol'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoon(context, 'Perimeter Checks'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.errorRed.withValues(alpha: 0.1),
                  child: const Icon(Icons.emergency, color: AppTheme.errorRed),
                ),
                title: const Text('Emergency Alert'),
                subtitle: const Text('Send emergency notification'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showEmergencyAlert(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.construction, color: AppTheme.warningOrange),
            SizedBox(width: 12),
            Text('Coming Soon'),
          ],
        ),
        content: Text('$feature feature is under development.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed),
            SizedBox(width: 12),
            Text('Emergency Alert'),
          ],
        ),
        content: const Text(
          'This will send an emergency alert to your supervisors. '
          'Only use in case of actual emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showComingSoon(context, 'Emergency Alert');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }
}

// Management Tab - For admins and managers
class _ManagementTab extends StatelessWidget {
  final UserModel user;
  final bool isOffline;

  const _ManagementTab({
    required this.user,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),

          // Quick Stats
          _buildQuickStats(context),
          const SizedBox(height: 20),

          // Management Actions
          _buildManagementActions(context),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.people,
                        color: AppTheme.primaryTeal,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Active Guards',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '12',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTeal,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_city,
                        color: AppTheme.secondaryBlue,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sites',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '5',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryBlue,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management Tools',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  child: const Icon(Icons.people, color: AppTheme.primaryTeal),
                ),
                title: const Text('Roster Management'),
                subtitle: const Text('Manage guard schedules and assignments'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () =>
                    Navigator.of(context).pushNamed(RouteConstants.roster),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      AppTheme.secondaryBlue.withValues(alpha: 0.1),
                  child: const Icon(Icons.analytics,
                      color: AppTheme.secondaryBlue),
                ),
                title: const Text('Reports & Analytics'),
                subtitle: const Text('View performance reports and insights'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () =>
                    Navigator.of(context).pushNamed(RouteConstants.reports),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      AppTheme.warningOrange.withValues(alpha: 0.1),
                  child: const Icon(Icons.location_city,
                      color: AppTheme.warningOrange),
                ),
                title: const Text('Site Management'),
                subtitle: const Text('Configure sites and checkpoints'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context)
                    .pushNamed(RouteConstants.siteManagement),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.1),
                  child: const Icon(Icons.manage_accounts,
                      color: AppTheme.accentCyan),
                ),
                title: const Text('User Management'),
                subtitle: const Text('Manage user accounts and permissions'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context)
                    .pushNamed(RouteConstants.userManagement),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// More Tab - Additional features and settings
class _MoreTab extends StatelessWidget {
  final UserModel user;
  final bool isOffline;

  const _MoreTab({
    required this.user,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          _buildMoreOptions(context),
        ],
      ),
    );
  }

  Widget _buildMoreOptions(BuildContext context) {
    final options = [
      _MoreOption(
        title: 'Profile',
        subtitle: 'Manage your profile information',
        icon: Icons.person,
        onTap: () => Navigator.of(context).pushNamed(RouteConstants.profile),
      ),
      _MoreOption(
        title: 'Settings',
        subtitle: 'App preferences and configuration',
        icon: Icons.settings,
        onTap: () => Navigator.of(context).pushNamed(RouteConstants.settings),
      ),
      if (user.hasAdminAccess) ...[
        _MoreOption(
          title: 'User Management',
          subtitle: 'Manage user accounts',
          icon: Icons.manage_accounts,
          onTap: () =>
              Navigator.of(context).pushNamed(RouteConstants.userManagement),
        ),
        _MoreOption(
          title: 'Reports',
          subtitle: 'View system reports',
          icon: Icons.analytics,
          onTap: () => Navigator.of(context).pushNamed(RouteConstants.reports),
        ),
      ],
      _MoreOption(
        title: 'Help & Support',
        subtitle: 'Get help and contact support',
        icon: Icons.help_outline,
        onTap: () => _showHelpDialog(context),
      ),
      _MoreOption(
        title: 'About',
        subtitle: 'App information and version',
        icon: Icons.info_outline,
        onTap: () => _showAboutDialog(context),
      ),
    ];

    return Column(
      children:
          options.map((option) => _buildOptionTile(context, option)).toList(),
    );
  }

  Widget _buildOptionTile(BuildContext context, _MoreOption option) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            option.icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(option.title),
        subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          option.onTap();
        },
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('For assistance, please contact:'),
            const SizedBox(height: 12),
            Text(
              'Email: ${AppConstants.supportEmail}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appTitle,
      applicationVersion: AppConstants.appVersion,
      applicationLegalese: '© 2024 ${AppConstants.companyName}',
      children: [
        const SizedBox(height: 16),
        const Text(AppConstants.appSubtitle),
      ],
    );
  }
}

class _MoreOption {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MoreOption({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });
}