import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/auth_bloc/auth_bloc.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';
import '../../bloc/auth_bloc/auth_bloc.dart';
import '../../core/constants/route_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/user_model.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/wearable/large_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _greetingController;
  late Animation<double> _greetingAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
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
  void dispose() {
    _greetingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          UserModel? user;
          bool isOffline = false;
          
          if (state is AuthAuthenticated) {
            user = state.user;
            isOffline = state.isOffline;
          } else if (state is AuthOfflineMode) {
            user = state.user;
            isOffline = true;
          }
          
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with logo and user info
                  _buildHeader(user, isOffline),
                  
                  const SizedBox(height: 32),
                  
                  // Greeting section
                  _buildGreeting(user),
                  
                  const SizedBox(height: 32),
                  
                  // Quick stats or status
                  _buildStatusCard(user, isOffline),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons based on user role
                  Expanded(
                    child: _buildActionButtons(user),
                  ),
                  
                  // Settings and logout
                  _buildBottomActions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(UserModel user, bool isOffline) {
    return Row(
      children: [
        const AppLogo(size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SlatesApp',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isOffline)
                Text(
                  'Offline Mode',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
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
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          tooltip: 'Toggle Theme',
        ),
      ],
    );
  }

  Widget _buildGreeting(UserModel user) {
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
      opacity: _greetingAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.fullName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.displayRole,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(UserModel user, bool isOffline) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOffline ? Icons.wifi_off : Icons.check_circle,
                  color: isOffline 
                      ? Theme.of(context).colorScheme.error
                      : AppTheme.successGreen,
                ),
                const SizedBox(width: 12),
                Text(
                  isOffline ? 'Working Offline' : 'Connected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Employee ID',
                    user.employeeId,
                    Icons.badge,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusItem(
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

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(UserModel user) {
    if (user.isGuard) {
      return _buildGuardActions();
    } else {
      return _buildAdminActions();
    }
  }

  Widget _buildGuardActions() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildActionCard(
          'Start Duty',
          Icons.play_circle_filled,
          AppTheme.successGreen,
          () => _showComingSoon('Start Duty'),
        ),
        _buildActionCard(
          'Movements',
          Icons.my_location,
          AppTheme.primaryTeal,
          () => _showComingSoon('Movement Tracking'),
        ),
        _buildActionCard(
          'Checkpoints',
          Icons.location_on,
          AppTheme.warningOrange,