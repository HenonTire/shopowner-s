import 'package:flutter/material.dart';
import 'package:shop_manager/pages/main_navigation_page.dart';
import 'package:shop_manager/services/auth_service.dart';
import 'package:shop_manager/theme/app_themes.dart';

class LoginPage extends StatefulWidget {
  LoginPage({
    super.key,
    AuthService? authService,
    this.isDarkMode = false,
    this.onThemeChanged,
  }) : authService = authService ?? BackendAuthService();

  final AuthService authService;
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
    Widget? suffixIcon,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: scheme.secondary, fontSize: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.secondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      suffixIcon: suffixIcon,
      fillColor: scheme.primary.withOpacity(0.05),
    );
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.login(
        LoginRequest(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigationPage(
            isDarkMode: widget.isDarkMode,
            onThemeChanged: widget.onThemeChanged,
          ),
        ),
      );
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop =
        isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: bgBottom,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[bgTop, bgBottom, bgBottom],
            stops: const <double>[0.0, 0.22, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        Text(
                          'Login',
                          style: AppThemes.poppins(
                            context,
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Log in to your existing account',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 50),
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter email or username';
                            }
                            return null;
                          },
                          decoration: _inputDecoration(
                            context,
                            hintText: 'Email or username',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          decoration: _inputDecoration(
                            context,
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ),
                        if (_errorMessage != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style:
                                textTheme.bodySmall?.copyWith(color: Colors.red),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 56,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(
                                  side: BorderSide(
                                    color: scheme.primary,
                                    width: 0.5,
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.arrow_forward,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
