import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/auth_bloc/auth_bloc.dart';
import 'package:slates_app_wear/core/auth_manager.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/validators.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/data/presentation/widgets/common/app_logo.dart';
import 'package:slates_app_wear/data/presentation/widgets/wearable/large_button.dart';
import 'package:slates_app_wear/data/presentation/widgets/wearable/pin_input.dart';
import 'package:slates_app_wear/data/presentation/widgets/wearable/wearable_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isGuardLogin = true;
  bool _rememberDevice = true;
  String? _lastEmployeeId;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadLastEmployeeId();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _pinController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadLastEmployeeId() async {
    try {
      final userData = await AuthManager().getUserData();
      if (userData != null && userData.isGuard) {
        setState(() {
          _lastEmployeeId = userData.employeeId;
          _identifierController.text = userData.employeeId;
        });
      }
    } catch (e) {
      // Ignore errors when loading last employee ID
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return WearableScaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated || state is AuthOfflineMode) {
            Navigator.of(context).pushReplacementNamed(RouteConstants.home);
          } else if (state is AuthError) {
            _showErrorSnackBar(state.message);
          } else if (state is AuthSessionExpired) {
            _showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading || state is AuthRefreshing;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: responsive.containerPadding,
                child: Form(
                  key: _formKey,
                  child: _buildResponsiveLayout(
                      context, state, isLoading, responsive),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, AuthState state,
      bool isLoading, ResponsiveUtils responsive) {
    if (responsive.isWearable) {
      return _buildWearableLayout(context, state, isLoading, responsive);
    }
    return _buildMobileLayout(context, state, isLoading, responsive);
  }

  Widget _buildWearableLayout(BuildContext context, AuthState state,
      bool isLoading, ResponsiveUtils responsive) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Compact logo
          SlideTransition(
            position: _slideAnimation,
            child: AppLogo(size: responsive.logoSize),
          ),

          responsive.mediumSpacer,

          // Compact login type toggle
          _buildCompactLoginTypeToggle(responsive),
          responsive.mediumSpacer,

          // Identifier input
          _buildResponsiveIdentifierInput(responsive),
          SizedBox(height: responsive.mediumSpacing * 0.75),

          // PIN input
          _buildResponsivePinInput(),
          responsive.mediumSpacer,

          // Remember device (guards only)
          if (_isGuardLogin) _buildCompactRememberDevice(responsive),

          responsive.largeSpacer,

          // Login button
          _buildResponsiveLoginButton(isLoading),

          // Status indicators
          if (state is AuthOfflineMode)
            Padding(
              padding: EdgeInsets.only(top: responsive.mediumSpacing),
              child: _buildCompactOfflineIndicator(responsive),
            ),

          // Clear data button (guards)
          if (_isGuardLogin && _lastEmployeeId != null)
            Padding(
              padding: EdgeInsets.only(top: responsive.smallSpacing),
              child: _buildCompactClearDataButton(responsive),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AuthState state,
      bool isLoading, ResponsiveUtils responsive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App Logo
        SlideTransition(
          position: _slideAnimation,
          child: AppLogo(size: responsive.logoSize),
        ),

        SizedBox(height: responsive.largeSpacing * 1.3),

        // Login Type Toggle
        _buildLoginTypeToggle(responsive),
        responsive.largeSpacer,

        // Identifier Input
        _buildResponsiveIdentifierInput(responsive),
        responsive.mediumSpacer,

        // PIN Input
        _buildResponsivePinInput(),
        SizedBox(height: responsive.largeSpacing * 0.8),

        // Remember Device (for guards only)
        if (_isGuardLogin) _buildRememberDevice(responsive),

        SizedBox(height: responsive.largeSpacing * 1.2),

        // Login Button
        _buildResponsiveLoginButton(isLoading),

        // Offline Status Indicator
        if (state is AuthOfflineMode) _buildOfflineIndicator(responsive),

        // Clear Saved Data Button (for guards)
        if (_isGuardLogin && _lastEmployeeId != null) ...[
          responsive.mediumSpacer,
          _buildClearDataButton(responsive),
        ],
      ],
    );
  }

  Widget _buildCompactLoginTypeToggle(ResponsiveUtils responsive) {
    return Container(
      height: responsive.buttonHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(responsive.largeBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
              child: _buildToggleOption(
                  true, 'Guard', Icons.security, responsive)),
          Expanded(
              child: _buildToggleOption(
                  false, 'Admin', Icons.admin_panel_settings, responsive)),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
      bool isGuard, String label, IconData icon, ResponsiveUtils responsive) {
    final isSelected = _isGuardLogin == isGuard;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isGuardLogin = isGuard);
      },
      child: Container(
        height: responsive.buttonHeight,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(responsive.largeBorderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: responsive.iconSize,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
            if (!responsive.isWearable) ...[
              responsive.smallHorizontalSpacer,
              Text(
                label,
                style: responsive.getTitleStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTypeToggle(ResponsiveUtils responsive) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(responsive.largeBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isGuardLogin = true);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: responsive.isSmallMobile ? 12 : 14),
                decoration: BoxDecoration(
                  color: _isGuardLogin
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(responsive.largeBorderRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security,
                      size: responsive.iconSize,
                      color: _isGuardLogin
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    responsive.smallHorizontalSpacer,
                    Text(
                      'Guard',
                      style: responsive.getTitleStyle(
                        color: _isGuardLogin
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isGuardLogin = false);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: responsive.isSmallMobile ? 12 : 14),
                decoration: BoxDecoration(
                  color: !_isGuardLogin
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(responsive.largeBorderRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: responsive.iconSize,
                      color: !_isGuardLogin
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    responsive.smallHorizontalSpacer,
                    Text(
                      'Admin',
                      style: responsive.getTitleStyle(
                        color: !_isGuardLogin
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveIdentifierInput(ResponsiveUtils responsive) {
    return TextFormField(
      controller: _identifierController,
      enabled: !(_isGuardLogin && _lastEmployeeId != null && _rememberDevice),
      decoration: InputDecoration(
        labelText: _isGuardLogin ? 'Employee ID' : 'Email Address',
        hintText: _isGuardLogin ? 'ABC-123' : 'user@company.com',
        labelStyle: responsive.isWearable ? responsive.getCaptionStyle() : null,
        hintStyle: responsive.isWearable ? responsive.getCaptionStyle() : null,
        contentPadding: responsive.inputPadding,
        prefixIcon: Icon(
          _isGuardLogin ? Icons.badge : Icons.email_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: responsive.largeIconSize,
        ),
        suffixIcon:
            (_isGuardLogin && _lastEmployeeId != null && _rememberDevice)
                ? Icon(
                    Icons.lock_outline,
                    color: Theme.of(context).colorScheme.outline,
                    size: responsive.iconSize,
                  )
                : null,
      ),
      style: responsive.getBodyStyle(),
      textCapitalization: _isGuardLogin
          ? TextCapitalization.characters
          : TextCapitalization.none,
      keyboardType:
          _isGuardLogin ? TextInputType.text : TextInputType.emailAddress,
      validator: _isGuardLogin ? Validators.employeeId : Validators.email,
      onChanged: (value) {
        if (_isGuardLogin) {
          final formatted = value.toUpperCase();
          if (formatted != value) {
            _identifierController.value = _identifierController.value.copyWith(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        }
      },
    );
  }

  Widget _buildResponsivePinInput() {
    return PinInputField(
      controller: _pinController,
      onCompleted: (pin) {
        if (_formKey.currentState?.validate() ?? false) {
          _handleLogin();
        }
      },
    );
  }

  Widget _buildCompactRememberDevice(ResponsiveUtils responsive) {
    return Row(
      children: [
        Transform.scale(
          scale: responsive.isWearable ? 0.8 : 1.0,
          child: Checkbox(
            value: _rememberDevice,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                _rememberDevice = value ?? false;
                if (!_rememberDevice) {
                  _identifierController.clear();
                  _lastEmployeeId = null;
                } else if (_lastEmployeeId != null) {
                  _identifierController.text = _lastEmployeeId!;
                }
              });
            },
          ),
        ),
        Expanded(
          child: Text(
            'Remember device',
            style: responsive.getBodyStyle(),
          ),
        ),
      ],
    );
  }

  Widget _buildRememberDevice(ResponsiveUtils responsive) {
    return Row(
      children: [
        Checkbox(
          value: _rememberDevice,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            setState(() {
              _rememberDevice = value ?? false;
              if (!_rememberDevice) {
                _identifierController.clear();
                _lastEmployeeId = null;
              } else if (_lastEmployeeId != null) {
                _identifierController.text = _lastEmployeeId!;
              }
            });
          },
        ),
        Expanded(
          child: Text(
            'Remember this device',
            style: responsive.getBodyStyle(),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveLoginButton(bool isLoading) {
    return LargeButton(
      text: 'Sign In',
      onPressed: isLoading ? null : _handleLogin,
      isLoading: isLoading,
      icon: Icons.login,
      width: double.infinity,
    );
  }

  Widget _buildCompactOfflineIndicator(ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.padding * 0.5,
        vertical: responsive.smallSpacing,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: responsive.iconSize,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          responsive.smallHorizontalSpacer,
          Text(
            responsive.isWearable ? 'Offline' : 'Offline Mode Active',
            style: responsive.getCaptionStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineIndicator(ResponsiveUtils responsive) {
    return Container(
      margin: EdgeInsets.only(top: responsive.mediumSpacing),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: responsive.iconSize,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          responsive.smallHorizontalSpacer,
          Text(
            'Offline Mode Active',
            style: responsive.getCaptionStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactClearDataButton(ResponsiveUtils responsive) {
    return TextButton.icon(
      onPressed: _clearSavedData,
      style: TextButton.styleFrom(
        padding: responsive.buttonPadding * 0.5,
      ),
      icon: Icon(
        Icons.delete_outline,
        size: responsive.iconSize,
        color: Theme.of(context).colorScheme.error,
      ),
      label: Text(
        responsive.isWearable ? 'Clear' : 'Clear Saved Data',
        style: responsive.getCaptionStyle(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget _buildClearDataButton(ResponsiveUtils responsive) {
    return TextButton.icon(
      onPressed: _clearSavedData,
      icon: Icon(
        Icons.delete_outline,
        size: responsive.iconSize,
        color: Theme.of(context).colorScheme.error,
      ),
      label: Text(
        'Clear Saved Data',
        style: responsive.getCaptionStyle(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.mediumImpact();

      final identifier = _identifierController.text.trim();
      final pin = _pinController.text.trim();

      context.read<AuthBloc>().add(
            LoginEvent(
              identifier: identifier,
              password: pin,
            ),
          );
    }
  }

  void _clearSavedData() async {
    HapticFeedback.mediumImpact();

    await AuthManager().clearAll();
    setState(() {
      _lastEmployeeId = null;
      _identifierController.clear();
      _pinController.clear();
      _rememberDevice = true;
    });

    _showSuccessSnackBar('Saved data cleared successfully');
  }

  void _showErrorSnackBar(String message) {
    final responsive = context.responsive;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: responsive.iconSize,
            ),
            SizedBox(width: responsive.smallSpacing),
            Expanded(
              child: Text(
                message,
                style: responsive.getCaptionStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: Duration(seconds: responsive.isWearable ? 3 : 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
        ),
        margin: EdgeInsets.all(responsive.padding),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final responsive = context.responsive;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: responsive.iconSize,
            ),
            SizedBox(width: responsive.smallSpacing),
            Expanded(
              child: Text(
                message,
                style: responsive.getCaptionStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
        ),
        margin: EdgeInsets.all(responsive.padding),
      ),
    );
  }
}
