import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/auth_bloc/auth_bloc.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

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
    final responsive = context.responsive;

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
                padding: responsive.containerPadding,
                child: _buildResponsiveLayout(responsive),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(ResponsiveUtils responsive) {
    if (responsive.isWearable) {
      return _buildWearableLayout(responsive);
    }
    return _buildMobileLayout(responsive);
  }

  Widget _buildWearableLayout(ResponsiveUtils responsive) {
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
            _buildAnimatedLogo(responsive),

            SizedBox(height: responsive.largeSpacing * 0.8),

            // Compact title
            _buildAnimatedTitle(responsive),

            SizedBox(height: responsive.extraLargeSpacing * 0.8),

            // Loading indicator
            _buildLoadingIndicator(responsive),

            responsive.largeSpacer,

            // Loading text
            _buildLoadingText(responsive),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(ResponsiveUtils responsive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo with animations
        _buildAnimatedLogo(responsive),

        responsive.extraLargeSpacer,

        // App title with slide animation
        _buildAnimatedTitle(responsive),

        SizedBox(height: responsive.extraLargeSpacing * 1.5),

        // Loading indicator
        _buildLoadingIndicator(responsive),

        responsive.largeSpacer,

        // Loading text
        _buildLoadingText(responsive),
      ],
    );
  }

  Widget _buildAnimatedLogo(ResponsiveUtils responsive) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: responsive.splashLogoSize,
              height: responsive.splashLogoSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(responsive.largeBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: responsive.isWearable ? 10 : 20,
                    offset: Offset(0, responsive.isWearable ? 5 : 10),
                  ),
                ],
              ),
              padding: EdgeInsets.all(responsive.padding),
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

  Widget _buildAnimatedTitle(ResponsiveUtils responsive) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Text(
              AppConstants.appTitle,
              style: responsive.getHeadlineStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            responsive.smallSpacer,
            Text(
              AppConstants.appSubtitle,
              style: responsive.getTitleStyle(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ResponsiveUtils responsive) {
    final loadingSize = responsive.getResponsiveValue(
      wearable: 20.0,
      smallMobile: 25.0,
      mobile: 30.0,
      tablet: 35.0,
    );

    final strokeWidth = responsive.getResponsiveValue(
      wearable: 2.0,
      smallMobile: 2.5,
      mobile: 3.0,
      tablet: 3.5,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: loadingSize,
        height: loadingSize,
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }

  Widget _buildLoadingText(ResponsiveUtils responsive) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        'Initializing...',
        style: responsive.getBodyStyle(
          color: Colors.white.withValues(alpha: 0.8),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
