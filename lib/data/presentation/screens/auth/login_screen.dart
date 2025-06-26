import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/auth_bloc/auth_bloc.dart';
import 'package:slates_app_wear/core/auth_manager.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/validators.dart';
import '../../widgets/wearable/large_button.dart';
import '../../widgets/wearable/pin_input.dart';
import '../../widgets/wearable/wearable_scaffold.dart';
import '../../widgets/common/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
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
                  Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                  Theme.of(context).colorScheme.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo with theme-aware text
                      SlideTransition(
                        position: _slideAnimation,
                        child: const AppLogo(size: 120),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Login Type Toggle
                      _buildLoginTypeToggle(),
                      const SizedBox(height: 24),
                      
                      // Identifier Input
                      _buildIdentifierInput(),
                      const SizedBox(height: 16),
                      
                      // PIN Input
                      _buildPinInput(),
                      const SizedBox(height: 20),
                      
                      // Remember Device (for guards only)
                      if (_isGuardLogin) _buildRememberDevice(),
                      
                      const SizedBox(height: 28),
                      
                      // Login Button
                      _buildLoginButton(isLoading),
                      
                      // Offline Status Indicator
                      if (state is AuthOfflineMode) _buildOfflineIndicator(),
                      
                      // Clear Saved Data Button (for guards)
                      if (_isGuardLogin && _lastEmployeeId != null) ...[
                        const SizedBox(height: 16),
                        _buildClearDataButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isGuardLogin ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security,
                      size: 18,
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_isGuardLogin ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 18,
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

  Widget _buildIdentifierInput() {
    return TextFormField(
      controller: _identifierController,
      enabled: !(_isGuardLogin && _lastEmployeeId != null && _rememberDevice),
      decoration: InputDecoration(
        labelText: _isGuardLogin ? 'Employee ID' : 'Email Address',
        hintText: _isGuardLogin ? 'ABC-123' : 'user@company.com',
        prefixIcon: Icon(
          _isGuardLogin ? Icons.badge : Icons.email_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        suffixIcon: (_isGuardLogin && _lastEmployeeId != null && _rememberDevice)
            ? Icon(
                Icons.lock_outline,
                color: Theme.of(context).colorScheme.outline,
                size: 20,
              )
            : null,
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      textCapitalization: _isGuardLogin ? TextCapitalization.characters : TextCapitalization.none,
      keyboardType: _isGuardLogin ? TextInputType.text : TextInputType.emailAddress,
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

  Widget _buildPinInput() {
    return PinInputField(
      controller: _pinController,
      onCompleted: (pin) {
        if (_formKey.currentState?.validate() ?? false) {
          _handleLogin();
        }
      },
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
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return LargeButton(
      text: 'Sign In',
      onPressed: isLoading ? null : _handleLogin,
      isLoading: isLoading,
      icon: Icons.login,
      width: double.infinity,
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha:0.3),
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
            ),
          ),
        ],
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
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
