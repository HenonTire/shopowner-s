import 'package:flutter/material.dart';
import 'package:shop_manager/theme/app_themes.dart';

/// Verification steps
enum _VerifyStep { email, identity, review }

class VerifyAccountPage extends StatefulWidget {
  const VerifyAccountPage({super.key, required this.userEmail});
  final String userEmail;

  @override
  State<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends State<VerifyAccountPage> {
  _VerifyStep _step = _VerifyStep.email;

  // ── Step 1: Email OTP ──
  final List<TextEditingController> _otpControllers =
      List<TextEditingController>.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List<FocusNode>.generate(6, (_) => FocusNode());
  bool _otpSending = false;
  bool _otpSent = false;
  bool _otpVerifying = false;
  int _resendSeconds = 0;

  // ── Step 2: Identity ──
  final TextEditingController _docTypeCtrl = TextEditingController();
  final TextEditingController _docNumberCtrl = TextEditingController();

  // Simulated picked files — replace with real File objects via image_picker
  String? _frontImageName;
  String? _backImageName;
  String? _selfieImageName;

  bool _submitting = false;

  @override
  void dispose() {
    for (final TextEditingController c in _otpControllers) { c.dispose(); }
    for (final FocusNode f in _otpFocusNodes) { f.dispose(); }
    _docTypeCtrl.dispose();
    _docNumberCtrl.dispose();
    super.dispose();
  }

  // ── OTP helpers ──
  Future<void> _sendOtp() async {
    setState(() { _otpSending = true; });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    // TODO: await AuthService.sendEmailOtp(widget.userEmail);
    if (!mounted) return;
    setState(() { _otpSending = false; _otpSent = true; _resendSeconds = 60; });
    _startResendTimer();
  }

  void _startResendTimer() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted || _resendSeconds <= 0) return;
      setState(() => _resendSeconds--);
      _startResendTimer();
    });
  }

  String get _otpValue => _otpControllers.map((TextEditingController c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otpValue.length < 6) {
      _showSnack('Enter the full 6-digit code.');
      return;
    }
    setState(() => _otpVerifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    // TODO: final bool ok = await AuthService.verifyEmailOtp(_otpValue);
    if (!mounted) return;
    setState(() { _otpVerifying = false; _step = _VerifyStep.identity; });
  }

  // ── Identity helpers ──
  Future<void> _pickImage(String slot) async {
    // TODO: replace with image_picker:
    // final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
    // if (file != null) setState(() => ...);
    setState(() {
      if (slot == 'front') _frontImageName = 'id_front.jpg';
      if (slot == 'back') _backImageName = 'id_back.jpg';
      if (slot == 'selfie') _selfieImageName = 'selfie.jpg';
    });
  }

  Future<void> _submitIdentity() async {
    if (_docTypeCtrl.text.trim().isEmpty) {
      _showSnack('Enter the document type.');
      return;
    }
    if (_docNumberCtrl.text.trim().isEmpty) {
      _showSnack('Enter the document number.');
      return;
    }
    if (_frontImageName == null || _selfieImageName == null) {
      _showSnack('Upload the front of your ID and a selfie.');
      return;
    }
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    // TODO: await AuthService.submitVerification(docType, docNumber, frontFile, backFile, selfieFile);
    if (!mounted) return;
    setState(() { _submitting = false; _step = _VerifyStep.review; });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;

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
                          Text('Verify Account', style: AppThemes.poppins(context, fontSize: 20, fontWeight: FontWeight.w700)),
                          Text(
                            'Complete both steps to get verified.',
                            style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSurface.withOpacity(0.55)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ── Step indicator ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StepBar(current: _step),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (Widget child, Animation<double> anim) =>
                      FadeTransition(opacity: anim, child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
                        child: child,
                      )),
                  child: KeyedSubtree(
                    key: ValueKey<_VerifyStep>(_step),
                    child: _step == _VerifyStep.email
                        ? _EmailStep(
                            email: widget.userEmail,
                            otpControllers: _otpControllers,
                            otpFocusNodes: _otpFocusNodes,
                            otpSent: _otpSent,
                            otpSending: _otpSending,
                            otpVerifying: _otpVerifying,
                            resendSeconds: _resendSeconds,
                            onSendOtp: _sendOtp,
                            onVerifyOtp: _verifyOtp,
                          )
                        : _step == _VerifyStep.identity
                            ? _IdentityStep(
                                docTypeCtrl: _docTypeCtrl,
                                docNumberCtrl: _docNumberCtrl,
                                frontImageName: _frontImageName,
                                backImageName: _backImageName,
                                selfieImageName: _selfieImageName,
                                onPickImage: _pickImage,
                                onSubmit: _submitIdentity,
                                submitting: _submitting,
                              )
                            : _ReviewStep(onDone: () => Navigator.of(context).pop()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Step bar
// ══════════════════════════════════════════════
class _StepBar extends StatelessWidget {
  const _StepBar({required this.current});
  final _VerifyStep current;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<String> labels = <String>['Email', 'Identity', 'Done'];
    final int currentIndex = _VerifyStep.values.indexOf(current);

    return Row(
      children: List<Widget>.generate(labels.length * 2 - 1, (int i) {
        if (i.isOdd) {
          // connector line
          final bool filled = currentIndex > i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? scheme.primary : scheme.onSurface.withOpacity(0.12),
            ),
          );
        }
        final int idx = i ~/ 2;
        final bool done = currentIndex > idx;
        final bool active = currentIndex == idx;
        return _StepDot(index: idx, label: labels[idx], done: done, active: active);
      }),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.label, required this.done, required this.active});
  final int index;
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color bg = done || active ? scheme.primary : scheme.onSurface.withOpacity(0.12);
    final Color fg = done || active ? scheme.onPrimary : scheme.onSurface.withOpacity(0.40);

    return Column(
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(
            child: done
                ? Icon(Icons.check_rounded, color: fg, size: 17)
                : Text('${index + 1}', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppThemes.poppins(
            context,
            fontSize: 9,
            fontWeight: active || done ? FontWeight.w700 : FontWeight.w500,
            color: active || done ? scheme.primary : scheme.onSurface.withOpacity(0.42),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// Step 1 — Email OTP
// ══════════════════════════════════════════════
class _EmailStep extends StatelessWidget {
  const _EmailStep({
    required this.email,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.otpSent,
    required this.otpSending,
    required this.otpVerifying,
    required this.resendSeconds,
    required this.onSendOtp,
    required this.onVerifyOtp,
  });

  final String email;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final bool otpSent;
  final bool otpSending;
  final bool otpVerifying;
  final int resendSeconds;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: <Widget>[
        Center(
          child: Container(
            width: 72,
            height: 72,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: scheme.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.mark_email_unread_outlined, color: scheme.primary, size: 34),
          ),
        ),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Verify your email', style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'We\'ll send a 6-digit code to $email',
                style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.60), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              if (!otpSent) ...<Widget>[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: otpSending ? null : onSendOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: otpSending
                        ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary))
                        : Text('Send code', style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
                  ),
                ),
              ] else ...<Widget>[
                Text('Enter the 6-digit code', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List<Widget>.generate(6, (int i) {
                    return SizedBox(
                      width: 44,
                      height: 52,
                      child: TextFormField(
                        controller: otpControllers[i],
                        focusNode: otpFocusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: AppThemes.poppins(context, fontSize: 20, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: scheme.primary.withOpacity(0.05),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.14))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.14))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.primary, width: 1.5)),
                        ),
                        onChanged: (String v) {
                          if (v.isNotEmpty && i < 5) {
                            FocusScope.of(context).requestFocus(otpFocusNodes[i + 1]);
                          } else if (v.isEmpty && i > 0) {
                            FocusScope.of(context).requestFocus(otpFocusNodes[i - 1]);
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      resendSeconds > 0 ? 'Resend in ${resendSeconds}s' : '',
                      style: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.50)),
                    ),
                    if (resendSeconds == 0)
                      GestureDetector(
                        onTap: onSendOtp,
                        child: Text('Resend code', style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w700, color: scheme.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: otpVerifying ? null : onVerifyOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: otpVerifying
                        ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary))
                        : Text('Confirm code', style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// Step 2 — Identity document
// ══════════════════════════════════════════════
class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    required this.docTypeCtrl,
    required this.docNumberCtrl,
    required this.frontImageName,
    required this.backImageName,
    required this.selfieImageName,
    required this.onPickImage,
    required this.onSubmit,
    required this.submitting,
  });

  final TextEditingController docTypeCtrl;
  final TextEditingController docNumberCtrl;
  final String? frontImageName;
  final String? backImageName;
  final String? selfieImageName;
  final void Function(String slot) onPickImage;
  final VoidCallback onSubmit;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: <Widget>[
        Center(
          child: Container(
            width: 72,
            height: 72,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: scheme.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.badge_outlined, color: scheme.primary, size: 34),
          ),
        ),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Identity document', style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Upload any government-issued ID. We accept national IDs, passports, driver\'s licences, and more.',
                style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.60), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _SimpleField(controller: docTypeCtrl, label: 'Document type', hint: 'e.g. National ID, Passport, Driver\'s Licence'),
              const SizedBox(height: 4),
              _SimpleField(controller: docNumberCtrl, label: 'Document number', hint: 'e.g. ID123456789'),
              const SizedBox(height: 16),
              Text('Upload photos', style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _UploadSlot(
                label: 'Front of ID',
                sublabel: 'Required',
                icon: Icons.credit_card_rounded,
                fileName: frontImageName,
                required: true,
                onTap: () => onPickImage('front'),
              ),
              const SizedBox(height: 10),
              _UploadSlot(
                label: 'Back of ID',
                sublabel: 'If applicable',
                icon: Icons.flip_rounded,
                fileName: backImageName,
                required: false,
                onTap: () => onPickImage('back'),
              ),
              const SizedBox(height: 10),
              _UploadSlot(
                label: 'Selfie holding your ID',
                sublabel: 'Required',
                icon: Icons.face_outlined,
                fileName: selfieImageName,
                required: true,
                onTap: () => onPickImage('selfie'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: submitting
                      ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary))
                      : Text('Submit for review', style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadSlot extends StatelessWidget {
  const _UploadSlot({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.fileName,
    required this.required,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final String? fileName;
  final bool required;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool uploaded = fileName != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: uploaded ? const Color(0xFF1B8F4D).withOpacity(0.06) : scheme.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded ? const Color(0xFF1B8F4D).withOpacity(0.30) : scheme.onSurface.withOpacity(0.12),
            width: uploaded ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: uploaded ? const Color(0xFF1B8F4D).withOpacity(0.10) : scheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(uploaded ? Icons.check_circle_rounded : icon, color: uploaded ? const Color(0xFF1B8F4D) : scheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(label, style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      if (required)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('Required', style: AppThemes.poppins(context, fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFFC62828))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    uploaded ? fileName! : sublabel,
                    style: AppThemes.poppins(
                      context,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: uploaded ? const Color(0xFF1B8F4D) : scheme.onSurface.withOpacity(0.50),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              uploaded ? Icons.edit_outlined : Icons.upload_rounded,
              size: 18,
              color: uploaded ? const Color(0xFF1B8F4D) : scheme.onSurface.withOpacity(0.40),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleField extends StatelessWidget {
  const _SimpleField({required this.controller, required this.label, this.hint});
  final TextEditingController controller;
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.35)),
        labelStyle: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSurface.withOpacity(isDark ? 0.78 : 0.64)),
        filled: true,
        fillColor: scheme.onPrimary.withOpacity(0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.14), width: 0.7)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.14), width: 0.7)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.primary.withOpacity(0.40), width: 1)),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Step 3 — Under review
// ══════════════════════════════════════════════
class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: <Widget>[
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(color: const Color(0xFF1B8F4D).withOpacity(0.10), shape: BoxShape.circle),
            child: const Icon(Icons.verified_outlined, color: Color(0xFF1B8F4D), size: 44),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Submitted for review',
          textAlign: TextAlign.center,
          style: AppThemes.poppins(context, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Your documents are under review. This usually takes 1–2 business days. We\'ll notify you once your account is verified.',
          textAlign: TextAlign.center,
          style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w500, color: scheme.onSurface.withOpacity(0.60)),
        ),
        const SizedBox(height: 28),
        _Card(
          child: Column(
            children: <Widget>[
              _ReviewItem(icon: Icons.email_outlined, label: 'Email verified', done: true),
              const SizedBox(height: 10),
              _ReviewItem(icon: Icons.badge_outlined, label: 'Identity submitted', done: true),
              const SizedBox(height: 10),
              _ReviewItem(icon: Icons.admin_panel_settings_outlined, label: 'Manual review pending', done: false, pending: true),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Back to profile', style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
          ),
        ),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.icon, required this.label, required this.done, this.pending = false});
  final IconData icon;
  final String label;
  final bool done;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = done ? const Color(0xFF1B8F4D) : pending ? const Color(0xFFF9A825) : scheme.onSurface.withOpacity(0.40);
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600))),
        Icon(done ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded, size: 18, color: color),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// Shared widgets
// ══════════════════════════════════════════════
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 14, offset: const Offset(0, 7)),
        ],
      ),
      child: child,
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