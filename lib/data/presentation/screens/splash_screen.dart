import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/auth_bloc/auth_bloc.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // Responsive properties
  bool get _isWearable {
    final size = MediaQuery.of(context).size;
    return size.width < 250 || size.height < 250;
  }

  bool get _isSmallMobile {
    final size = MediaQuery.of(context).size;
    return size.width < 360 || size.height < 640;
  }

  double get _logoSize {
    if (_isWearable) return 80.0;
    if (_isSmallMobile) return 120.0;
    return 150.0;
  }

  double get _logoRadius {
    if (_isWearable) return 20.0;
    if (_isSmallMobile) return 25.0;
    return 30.0;
  }

  double get _logoPadding {
    if (_isWearable) return 12.0;
    if (_isSmallMobile) return 16.0;
    return 20.0;
  }

  double get _spacing {
    if (_isWearable) return 16.0;
    if (_isSmallMobile) return 24.0;
    return 40.0;
  }

  double get _smallSpacing {
    if (_isWearable) return 4.0;
    if (_isSmallMobile) return 6.0;
    return 8.0;
  }

  double get _loadingSpacing {
    if (_isWearable) return 24.0;
    if (_isSmallMobile) return 40.0;
    return 60.0;
  }

  double get _loadingSize {
    if (_isWearable) return 20.0;
    if (_isSmallMobile) return 25.0;
    return 30.0;
  }

  double get _loadingStrokeWidth {
    if (_isWearable) return 2.0;
    if (_isSmallMobile) return 2.5;
    return 3.0;
  }

  EdgeInsets get _containerPadding {
    if (_isWearable) return const EdgeInsets.all(8.0);
    if (_isSmallMobile) return const EdgeInsets.all(12.0);
    return const EdgeInsets.all(16.0);
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthStatus();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  void _checkAuthStatus() {
    Future.delayed(
      const Duration(seconds: AppConstants.splashScreenDuration),
      () {
        if (mounted) {
          context.read<AuthBloc>().add(const CheckAuthStatusEvent());
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthOfflineMode) {
          Navigator.of(context).pushReplacementNamed(RouteConstants.home);
        } else if (state is AuthUnauthenticated || state is AuthError) {
          Navigator.of(context).pushReplacementNamed(RouteConstants.login);
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Padding(
                padding: _containerPadding,
                child: _buildResponsiveLayout(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout() {
    if (_isWearable) {
      return _buildWearableLayout();
    }
    return _buildMobileLayout();
  }

  Widget _buildWearableLayout() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom -
              16,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Compact logo
            _buildAnimatedLogo(),

            SizedBox(height: _spacing * 0.8),

            // Compact title
            _buildAnimatedTitle(),

            SizedBox(height: _loadingSpacing * 0.8),

            // Loading indicator
            _buildLoadingIndicator(),

            SizedBox(height: _spacing * 0.5),

            // Loading text
            _buildLoadingText(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo with animations
        _buildAnimatedLogo(),

        SizedBox(height: _spacing),

        // App title with slide animation
        _buildAnimatedTitle(),

        SizedBox(height: _loadingSpacing),

        // Loading indicator
        _buildLoadingIndicator(),

        SizedBox(height: _spacing * 0.5),

        // Loading text
        _buildLoadingText(),
      ],
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: _logoSize,
              height: _logoSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_logoRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: _isWearable ? 10 : 20,
                    offset: Offset(0, _isWearable ? 5 : 10),
                  ),
                ],
              ),
              padding: EdgeInsets.all(_logoPadding),
              child: Image.asset(
                'assets/images/applogo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTitle() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Text(
              AppConstants.appTitle,
              style: _getHeadlineStyle(),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _smallSpacing),
            Text(
              AppConstants.appSubtitle,
              style: _getSubtitleStyle(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: _loadingSize,
        height: _loadingSize,
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: _loadingStrokeWidth,
        ),
      ),
    );
  }

  Widget _buildLoadingText() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        'Initializing...',
        style: _getLoadingTextStyle(),
        textAlign: TextAlign.center,
      ),
    );
  }

  TextStyle? _getHeadlineStyle() {
    if (_isWearable) {
      return Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          );
    } else if (_isSmallMobile) {
      return Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          );
    } else {
      return Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          );
    }
  }

  TextStyle? _getSubtitleStyle() {
    if (_isWearable) {
      return Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          );
    } else if (_isSmallMobile) {
      return Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
          );
    } else {
      return Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          );
    }
  }

  TextStyle? _getLoadingTextStyle() {
    if (_isWearable) {
      return Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
          );
    } else if (_isSmallMobile) {
      return Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          );
    } else {
      return Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          );
    }
  }
}
