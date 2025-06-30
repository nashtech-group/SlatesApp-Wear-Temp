import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/auth_bloc/auth_bloc.dart';
import 'package:slates_app_wear/core/auth_manager.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/validators.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/common/app_logo.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/wearable/large_button.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/wearable/pin_input.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/wearable/wearable_scaffold.dart';

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

  // Responsive properties
  bool get _isWearable {
    final size = MediaQuery.of(context).size;
    return size.width < 250 || size.height < 250;
  }

  bool get _isSmallMobile {
    final size = MediaQuery.of(context).size;
    return size.width < 360 || size.height < 640;
  }

  double get _responsivePadding {
    if (_isWearable) return 8.0;
    if (_isSmallMobile) return 16.0;
    return 20.0;
  }

  double get _responsiveSpacing {
    if (_isWearable) return 8.0;
    if (_isSmallMobile) return 12.0;
    return 16.0;
  }

  double get _responsiveLargeSpacing {
    if (_isWearable) return 16.0;
    if (_isSmallMobile) return 20.0;
    return 24.0;
  }

  double get _logoSize {
    if (_isWearable) return 60.0;
    if (_isSmallMobile) return 80.0;
    return 120.0;
  }

  double get _buttonHeight {
    if (_isWearable) return 36.0;
    if (_isSmallMobile) return 44.0;
    return 48.0;
  }

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
                padding: EdgeInsets.all(_responsivePadding),
                child: Form(
                  key: _formKey,
                  child: _buildResponsiveLayout(context, state, isLoading),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveLayout(
      BuildContext context, AuthState state, bool isLoading) {
    if (_isWearable) {
      return _buildWearableLayout(context, state, isLoading);
    }
    return _buildMobileLayout(context, state, isLoading);
  }

  Widget _buildWearableLayout(
      BuildContext context, AuthState state, bool isLoading) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Compact logo
          SlideTransition(
            position: _slideAnimation,
            child: AppLogo(size: _logoSize),
          ),

          SizedBox(height: _responsiveSpacing),

          // Compact login type toggle
          _buildCompactLoginTypeToggle(),
          SizedBox(height: _responsiveSpacing),

          // Identifier input
          _buildResponsiveIdentifierInput(),
          SizedBox(height: _responsiveSpacing * 0.75),

          // PIN input
          _buildResponsivePinInput(),
          SizedBox(height: _responsiveSpacing),

          // Remember device (guards only)
          if (_isGuardLogin) _buildCompactRememberDevice(),

          SizedBox(height: _responsiveLargeSpacing),

          // Login button
          _buildResponsiveLoginButton(isLoading),

          // Status indicators
          if (state is AuthOfflineMode)
            Padding(
              padding: EdgeInsets.only(top: _responsiveSpacing),
              child: _buildCompactOfflineIndicator(),
            ),

          // Clear data button (guards)
          if (_isGuardLogin && _lastEmployeeId != null)
            Padding(
              padding: EdgeInsets.only(top: _responsiveSpacing * 0.5),
              child: _buildCompactClearDataButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, AuthState state, bool isLoading) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App Logo
        SlideTransition(
          position: _slideAnimation,
          child: AppLogo(size: _logoSize),
        ),

        SizedBox(height: _responsiveLargeSpacing * 1.3),

        // Login Type Toggle
        _buildLoginTypeToggle(),
        SizedBox(height: _responsiveLargeSpacing),

        // Identifier Input
        _buildResponsiveIdentifierInput(),
        SizedBox(height: _responsiveSpacing),

        // PIN Input
        _buildResponsivePinInput(),
        SizedBox(height: _responsiveLargeSpacing * 0.8),

        // Remember Device (for guards only)
        if (_isGuardLogin) _buildRememberDevice(),

        SizedBox(height: _responsiveLargeSpacing * 1.2),

        // Login Button
        _buildResponsiveLoginButton(isLoading),

        // Offline Status Indicator
        if (state is AuthOfflineMode) _buildOfflineIndicator(),

        // Clear Saved Data Button (for guards)
        if (_isGuardLogin && _lastEmployeeId != null) ...[
          SizedBox(height: _responsiveSpacing),
          _buildClearDataButton(),
        ],
      ],
    );
  }

  Widget _buildCompactLoginTypeToggle() {
    return Container(
      height: _buttonHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(_isWearable ? 20 : 30),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleOption(true, 'Guard', Icons.security)),
          Expanded(
              child: _buildToggleOption(
                  false, 'Admin', Icons.admin_panel_settings)),
        ],
      ),
    );
  }

  Widget _buildToggleOption(bool isGuard, String label, IconData icon) {
    final isSelected = _isGuardLogin == isGuard;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isGuardLogin = isGuard);
      },
      child: Container(
        height: _buttonHeight,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(_isWearable ? 20 : 30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: _isWearable ? 14 : 18,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
            if (!_isWearable) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: _isSmallMobile ? 13 : null,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
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
                padding:
                    EdgeInsets.symmetric(vertical: _isSmallMobile ? 12 : 14),
                decoration: BoxDecoration(
                  color: _isGuardLogin
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security,
                      size: _isSmallMobile ? 16 : 18,
                      color: _isGuardLogin
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Guard',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _isGuardLogin
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: _isSmallMobile ? 13 : null,
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
                padding:
                    EdgeInsets.symmetric(vertical: _isSmallMobile ? 12 : 14),
                decoration: BoxDecoration(
                  color: !_isGuardLogin
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: _isSmallMobile ? 16 : 18,
                      color: !_isGuardLogin
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Admin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: !_isGuardLogin
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: _isSmallMobile ? 13 : null,
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

  Widget _buildResponsiveIdentifierInput() {
    return TextFormField(
      controller: _identifierController,
      enabled: !(_isGuardLogin && _lastEmployeeId != null && _rememberDevice),
      decoration: InputDecoration(
        labelText: _isGuardLogin ? 'Employee ID' : 'Email Address',
        hintText: _isGuardLogin ? 'ABC-123' : 'user@company.com',
        labelStyle: _isWearable ? Theme.of(context).textTheme.bodySmall : null,
        hintStyle: _isWearable ? Theme.of(context).textTheme.bodySmall : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: _isWearable ? 12 : 16,
          vertical: _isWearable ? 8 : 16,
        ),
        prefixIcon: Icon(
          _isGuardLogin ? Icons.badge : Icons.email_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: _isWearable ? 18 : 24,
        ),
        suffixIcon:
            (_isGuardLogin && _lastEmployeeId != null && _rememberDevice)
                ? Icon(
                    Icons.lock_outline,
                    color: Theme.of(context).colorScheme.outline,
                    size: _isWearable ? 16 : 20,
                  )
                : null,
      ),
      style: _isWearable
          ? Theme.of(context).textTheme.bodySmall
          : Theme.of(context).textTheme.bodyLarge,
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

  Widget _buildCompactRememberDevice() {
    return Row(
      children: [
        Transform.scale(
          scale: _isWearable ? 0.8 : 1.0,
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
            style: _isWearable
                ? Theme.of(context).textTheme.bodySmall
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildRememberDevice() {
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: _isSmallMobile ? 13 : null,
                ),
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

  Widget _buildCompactOfflineIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isWearable ? 8 : 16,
        vertical: _isWearable ? 4 : 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(_isWearable ? 8 : 12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: _isWearable ? 12 : 18,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          SizedBox(width: _isWearable ? 4 : 8),
          Text(
            _isWearable ? 'Offline' : 'Offline Mode Active',
            style: (_isWearable
                    ? Theme.of(context).textTheme.bodySmall
                    : Theme.of(context).textTheme.bodySmall)
                ?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontWeight: FontWeight.w500,
              fontSize: _isWearable ? 10 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      margin: EdgeInsets.only(top: _responsiveSpacing),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: 18,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Text(
            'Offline Mode Active',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                  fontSize: _isSmallMobile ? 12 : null,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactClearDataButton() {
    return TextButton.icon(
      onPressed: _clearSavedData,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: _isWearable ? 8 : 16,
          vertical: _isWearable ? 4 : 8,
        ),
      ),
      icon: Icon(
        Icons.delete_outline,
        size: _isWearable ? 12 : 16,
        color: Theme.of(context).colorScheme.error,
      ),
      label: Text(
        _isWearable ? 'Clear' : 'Clear Saved Data',
        style: (_isWearable
                ? Theme.of(context).textTheme.bodySmall
                : Theme.of(context).textTheme.bodySmall)
            ?.copyWith(
          color: Theme.of(context).colorScheme.error,
          fontSize: _isWearable ? 10 : null,
        ),
      ),
    );
  }

  Widget _buildClearDataButton() {
    return TextButton.icon(
      onPressed: _clearSavedData,
      icon: Icon(
        Icons.delete_outline,
        size: 16,
        color: Theme.of(context).colorScheme.error,
      ),
      label: Text(
        'Clear Saved Data',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontSize: _isSmallMobile ? 12 : null,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: _isWearable ? 16 : 20,
            ),
            SizedBox(width: _isWearable ? 8 : 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _isWearable ? 12 : 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: Duration(seconds: _isWearable ? 3 : 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isWearable ? 8 : 12),
        ),
        margin: EdgeInsets.all(_isWearable ? 8 : 16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: _isWearable ? 16 : 20,
            ),
            SizedBox(width: _isWearable ? 8 : 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _isWearable ? 12 : 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isWearable ? 8 : 12),
        ),
        margin: EdgeInsets.all(_isWearable ? 8 : 16),
      ),
    );
  }
}
