import 'package:flutter/material.dart';
import 'package:shop_manager/theme/app_themes.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _saving = false;

  // Password strength
  int get _strength {
    final String p = _newCtrl.text;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  Color _strengthColor(int score) {
    switch (score) {
      case 1: return const Color(0xFFC62828);
      case 2: return const Color(0xFFE65100);
      case 3: return const Color(0xFFF9A825);
      case 4: return const Color(0xFF1B8F4D);
      default: return Colors.transparent;
    }
  }

  String _strengthLabel(int score) {
    switch (score) {
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Strong';
      default: return '';
    }
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    // TODO: call your change-password API here
    // e.g. await AuthService.changePassword(current: _currentCtrl.text, newPass: _newCtrl.text);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Password updated successfully.',
          style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;
    final int strength = _strength;

    return Scaffold(
      backgroundColor: bgBottom,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[bgTop, bgBottom, bgBottom],
            stops: const <double>[0.0, 0.18, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: <Widget>[
                    _BackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Change Password',
                            style: AppThemes.poppins(context, fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Keep your account secure.',
                            style: AppThemes.poppins(
                              context,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: <Widget>[
                    // Lock icon hero
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lock_outline_rounded, color: scheme.primary, size: 34),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withOpacity(0.045),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _FormField(
                              controller: _currentCtrl,
                              label: 'Current password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: !_showCurrent,
                              onToggleVisibility: () => setState(() => _showCurrent = !_showCurrent),
                              showVisibility: _showCurrent,
                              validator: (String? v) {
                                if (v == null || v.isEmpty) return 'Current password is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 4),
                            _FormField(
                              controller: _newCtrl,
                              label: 'New password',
                              icon: Icons.vpn_key_outlined,
                              obscureText: !_showNew,
                              onToggleVisibility: () => setState(() => _showNew = !_showNew),
                              showVisibility: _showNew,
                              onChanged: (_) => setState(() {}),
                              validator: (String? v) {
                                if (v == null || v.isEmpty) return 'New password is required';
                                if (v.length < 8) return 'At least 8 characters required';
                                return null;
                              },
                            ),
                            // Strength bar
                            if (_newCtrl.text.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 6),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(99),
                                      child: LinearProgressIndicator(
                                        value: strength / 4,
                                        minHeight: 4,
                                        backgroundColor: scheme.onSurface.withOpacity(0.10),
                                        valueColor: AlwaysStoppedAnimation<Color>(_strengthColor(strength)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _strengthLabel(strength),
                                    style: AppThemes.poppins(
                                      context,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _strengthColor(strength),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Tips
                              _PasswordHint(met: _newCtrl.text.length >= 8, label: 'At least 8 characters'),
                              _PasswordHint(met: _newCtrl.text.contains(RegExp(r'[A-Z]')), label: 'One uppercase letter'),
                              _PasswordHint(met: _newCtrl.text.contains(RegExp(r'[0-9]')), label: 'One number'),
                              _PasswordHint(
                                met: _newCtrl.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
                                label: 'One special character',
                              ),
                              const SizedBox(height: 4),
                            ],
                            _FormField(
                              controller: _confirmCtrl,
                              label: 'Confirm new password',
                              icon: Icons.check_circle_outline_rounded,
                              obscureText: !_showConfirm,
                              onToggleVisibility: () => setState(() => _showConfirm = !_showConfirm),
                              showVisibility: _showConfirm,
                              validator: (String? v) {
                                if (v != _newCtrl.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _saving
                                    ? SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                                      )
                                    : Text(
                                        'Update password',
                                        style: AppThemes.poppins(
                                          context,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onPrimary,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Info note
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.primary.withOpacity(0.12)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(Icons.info_outline_rounded, color: scheme.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'After updating your password, you will remain signed in on this device. Other sessions will be logged out.',
                              style: AppThemes.poppins(
                                context,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurface.withOpacity(0.68),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordHint extends StatelessWidget {
  const _PasswordHint({required this.met, required this.label});
  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color color = met ? const Color(0xFF1B8F4D) : Theme.of(context).colorScheme.onSurface.withOpacity(0.42);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: <Widget>[
          Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 13, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.showVisibility,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final bool showVisibility;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppThemes.poppins(
            context,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface.withOpacity(isDark ? 0.78 : 0.64),
          ),
          prefixIcon: Icon(icon, size: 18, color: scheme.onSurface.withOpacity(0.52)),
          suffixIcon: IconButton(
            icon: Icon(showVisibility ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
            onPressed: onToggleVisibility,
          ),
          filled: true,
          fillColor: scheme.onPrimary.withOpacity(0.03),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.14), width: 0.7)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.14), width: 0.7)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.primary.withOpacity(0.40), width: 1)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC62828), width: 0.8)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC62828), width: 1)),
          errorStyle: AppThemes.poppins(context, fontSize: 10, color: const Color(0xFFC62828)),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.onPrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withOpacity(0.12), width: 0.6),
      ),
      child: IconButton(
        tooltip: 'Back',
        onPressed: onTap,
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: scheme.primary, size: 18),
      ),
    );
  }
}