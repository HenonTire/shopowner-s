import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shop_manager/services/auth_service.dart';
import 'package:shop_manager/services/identity_verification_repository.dart';
import 'package:shop_manager/theme/app_themes.dart';

class VerifyAccountPage extends StatefulWidget {
  const VerifyAccountPage({super.key, required this.userEmail});
  final String userEmail;

  @override
  State<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends State<VerifyAccountPage> {
  // ── Email step ──
  bool _sending = false;
  bool _emailSent = false;
  bool _emailVerified = false;
  Timer? _pollTimer;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  // ── Identity step ──
  bool get _isCustomer => (AuthSessionStore.user?.role.toUpperCase() ?? '') == 'CUSTOMER';
  bool _loadingIdentity = false;
  IdentityVerificationStatus? _identityStatus;
  bool _consentGiven = false;
  final TextEditingController _docTypeCtrl = TextEditingController();
  final TextEditingController _docNumberCtrl = TextEditingController();
  Uint8List? _frontBytes;
  String? _frontName;
  Uint8List? _backBytes;
  String? _backName;
  Uint8List? _selfieBytes;
  String? _selfieName;
  bool _submitting = false;
  bool _deleting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _emailVerified = AuthSessionStore.user?.isVerified ?? false;
    if (_emailVerified && !_isCustomer) {
      _loadIdentityStatus();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _resendTimer?.cancel();
    _docTypeCtrl.dispose();
    _docNumberCtrl.dispose();
    super.dispose();
  }

  // ── Email helpers ──
  Future<void> _sendVerificationEmail() async {
    setState(() => _sending = true);
    try {
      await BackendAuthService().resendVerificationEmail(widget.userEmail);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _emailSent = true;
        _resendSeconds = 60;
      });
      _startResendCooldown();
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _showSnack(e.toString().replaceFirst('AuthFailure: ', ''));
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted || _resendSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) async {
      try {
        final AuthUser user = await BackendAuthService().fetchMyProfile();
        if (!mounted) return;
        if (user.isVerified) {
          timer.cancel();
          setState(() => _emailVerified = true);
          if (!_isCustomer) _loadIdentityStatus();
        }
      } catch (_) {
        // Silently ignore transient poll failures — next tick will retry.
      }
    });
  }

  // ── Identity helpers ──
  Future<void> _loadIdentityStatus() async {
    setState(() => _loadingIdentity = true);
    try {
      final IdentityVerificationStatus? status = await IdentityVerificationRepository().fetchMyStatus();
      if (!mounted) return;
      setState(() {
        _identityStatus = status;
        _loadingIdentity = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingIdentity = false);
      _showSnack('Could not load verification status.');
    }
  }

  Future<void> _pickImage(String slot) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      if (slot == 'front') {
        _frontBytes = bytes;
        _frontName = file.name;
      } else if (slot == 'back') {
        _backBytes = bytes;
        _backName = file.name;
      } else if (slot == 'selfie') {
        _selfieBytes = bytes;
        _selfieName = file.name;
      }
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
    if (_frontBytes == null || _selfieBytes == null) {
      _showSnack('Upload the front of your ID and a selfie.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final IdentityVerificationStatus status = await IdentityVerificationRepository().submit(
        documentType: _docTypeCtrl.text.trim(),
        documentNumber: _docNumberCtrl.text.trim(),
        frontImageBytes: _frontBytes!,
        frontImageName: _frontName ?? 'front.jpg',
        backImageBytes: _backBytes,
        backImageName: _backName,
        selfieImageBytes: _selfieBytes!,
        selfieImageName: _selfieName ?? 'selfie.jpg',
      );
      if (!mounted) return;
      setState(() {
        _identityStatus = status;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(e.toString());
    }
  }

  void _resetForResubmit() {
    setState(() {
      _identityStatus = null;
      _consentGiven = false;
      _docTypeCtrl.clear();
      _docNumberCtrl.clear();
      _frontBytes = null;
      _frontName = null;
      _backBytes = null;
      _backName = null;
      _selfieBytes = null;
      _selfieName = null;
    });
  }

  Future<void> _confirmDeleteData() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Delete your documents?', style: AppThemes.poppins(context, fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text(
            'This permanently removes your uploaded ID photos and document details from our servers. You can submit again later if needed.',
            style: AppThemes.poppins(context, fontSize: 12),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel', style: AppThemes.poppins(context, fontSize: 12)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFC62828)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await IdentityVerificationRepository().deleteMyData();
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _resetForResubmit();
      });
      _showSnack('Your documents have been deleted.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _showSnack('Could not delete documents. Try again.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onInverseSurface),
        ),
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
                            _isCustomer ? 'Confirm your email address.' : 'Confirm your email and identity.',
                            style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSurface.withOpacity(0.55)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!_isCustomer)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _StepBar(emailDone: _emailVerified, identityDone: _identityStatus?.isApproved ?? false),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: _headerIconColor(scheme).withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_headerIcon(), color: _headerIconColor(scheme), size: 34),
                      ),
                    ),
                    _Card(child: _buildBody(context, scheme)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _headerIcon() {
    if (!_emailVerified) return Icons.mark_email_unread_outlined;
    if (_isCustomer) return Icons.verified_rounded;
    if (_identityStatus?.isApproved ?? false) return Icons.verified_rounded;
    if (_identityStatus?.isPending ?? false) return Icons.hourglass_top_rounded;
    if (_identityStatus?.isRejected ?? false) return Icons.error_outline_rounded;
    return Icons.badge_outlined;
  }

  Color _headerIconColor(ColorScheme scheme) {
    if (!_emailVerified) return scheme.primary;
    if (_isCustomer || (_identityStatus?.isApproved ?? false)) return const Color(0xFF1B8F4D);
    if (_identityStatus?.isRejected ?? false) return const Color(0xFFC62828);
    return scheme.primary;
  }

  Widget _buildBody(BuildContext context, ColorScheme scheme) {
    if (!_emailVerified) {
      return _emailSent ? _buildEmailWaitingState(context, scheme) : _buildEmailInitialState(context, scheme);
    }
    if (_isCustomer) {
      return _buildDoneState(context, scheme, title: 'Email verified', message: 'Your account is verified. You\'re all set.');
    }
    if (_loadingIdentity) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_identityStatus == null) {
      return _consentGiven ? _buildIdentityForm(context, scheme) : _buildConsentState(context, scheme);
    }
    if (_identityStatus!.isApproved) {
      return _buildDoneState(context, scheme, title: 'Identity verified', message: 'Your identity has been approved. You\'re fully verified.');
    }
    if (_identityStatus!.isPending) {
      return _buildPendingState(context, scheme);
    }
    return _buildRejectedState(context, scheme);
  }

  // ── Email states ──
  Widget _buildEmailInitialState(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Verify your email', style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'We\'ll send a verification link to ${widget.userEmail}',
          style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.60), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _sending ? null : _sendVerificationEmail,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _sending
                ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary))
                : Text('Send verification email', style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailWaitingState(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Check your inbox', style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'We sent a link to ${widget.userEmail}. Open it to verify — this screen will update automatically.',
          style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.60), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary)),
            const SizedBox(width: 10),
            Text('Waiting for verification…', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface.withOpacity(0.60))),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: _resendSeconds > 0
              ? Text('Resend in ${_resendSeconds}s', style: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.50)))
              : GestureDetector(
                  onTap: _sendVerificationEmail,
                  child: Text('Resend email', style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w700, color: scheme.primary)),
                ),
        ),
      ],
    );
  }

  // ── Consent state ──
  Widget _buildConsentState(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Before you continue', style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'To verify your identity, we collect and store the following:',
          style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.60), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        _ConsentPoint(icon: Icons.badge_outlined, text: 'Your document type and number'),
        _ConsentPoint(icon: Icons.credit_card_rounded, text: 'Photos of the front (and back, if applicable) of your ID'),
        _ConsentPoint(icon: Icons.face_outlined, text: 'A selfie photo, used to confirm the ID belongs to you'),
        const SizedBox(height: 12),
        Text(
          'This data is used only to verify your identity as a seller on this platform, and is kept only as long as needed for that purpose. You can request deletion of this data at any time from this screen.',
          style: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.55), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: _consentGiven,
                onChanged: (bool? v) => setState(() => _consentGiven = v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _consentGiven = !_consentGiven),
                  child: Text(
                    'I understand and agree to share this information for identity verification.',
                    style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _consentGiven ? () => setState(() {}) : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Continue', style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
          ),
        ),
      ],
    );
  }

  // ── Identity states ──
  Widget _buildIdentityForm(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Identity document', style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Upload any government-issued ID. We accept national IDs, passports, driver\'s licences, and more.',
          style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.60), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _SimpleField(controller: _docTypeCtrl, label: 'Document type', hint: 'e.g. National ID, Passport, Driver\'s Licence'),
        const SizedBox(height: 4),
        _SimpleField(controller: _docNumberCtrl, label: 'Document number', hint: 'e.g. ID123456789'),
        const SizedBox(height: 16),
        Text('Upload photos', style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _UploadSlot(
          label: 'Front of ID',
          sublabel: 'Required',
          icon: Icons.credit_card_rounded,
          fileName: _frontName,
          required: true,
          onTap: () => _pickImage('front'),
        ),
        const SizedBox(height: 10),
        _UploadSlot(
          label: 'Back of ID',
          sublabel: 'If applicable',
          icon: Icons.flip_rounded,
          fileName: _backName,
          required: false,
          onTap: () => _pickImage('back'),
        ),
        const SizedBox(height: 10),
        _UploadSlot(
          label: 'Selfie holding your ID',
          sublabel: 'Required',
          icon: Icons.face_outlined,
          fileName: _selfieName,
          required: true,
          onTap: () => _pickImage('selfie'),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitIdentity,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary))
                : Text('Submit for review', style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingState(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Submitted for review', style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Your documents are under review. This usually takes 1–2 business days. We\'ll notify you once your account is verified.',
          style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.60), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _loadIdentityStatus,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text('Refresh status', style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 10),
        _buildDeleteDataLink(context, scheme),
      ],
    );
  }

  Widget _buildRejectedState(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Submission rejected', style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFC62828))),
        const SizedBox(height: 6),
        Text(
          _identityStatus!.reviewNotes.isNotEmpty
              ? _identityStatus!.reviewNotes
              : 'Your submission didn\'t pass review. Please try again with clearer photos.',
          style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.60), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _resetForResubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Resubmit documents', style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
          ),
        ),
        const SizedBox(height: 10),
        _buildDeleteDataLink(context, scheme),
      ],
    );
  }

  Widget _buildDoneState(BuildContext context, ColorScheme scheme, {required String title, required String message}) {
    final bool showDelete = !_isCustomer && _identityStatus != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1B8F4D))),
        const SizedBox(height: 6),
        Text(message, style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.60), fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Back to profile', style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
          ),
        ),
        if (showDelete) ...<Widget>[
          const SizedBox(height: 10),
          _buildDeleteDataLink(context, scheme),
        ],
      ],
    );
  }

  Widget _buildDeleteDataLink(BuildContext context, ColorScheme scheme) {
    return Center(
      child: _deleting
          ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onSurface.withOpacity(0.4)))
          : GestureDetector(
              onTap: _confirmDeleteData,
              child: Text(
                'Delete my documents',
                style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFC62828)),
              ),
            ),
    );
  }
}

// ══════════════════════════════════════════════
// Consent point row
// ══════════════════════════════════════════════
class _ConsentPoint extends StatelessWidget {
  const _ConsentPoint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w500, color: scheme.onSurface.withOpacity(0.72))),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Step bar
// ══════════════════════════════════════════════
class _StepBar extends StatelessWidget {
  const _StepBar({required this.emailDone, required this.identityDone});
  final bool emailDone;
  final bool identityDone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        _StepDot(index: 0, label: 'Email', done: emailDone, active: !emailDone),
        Expanded(
          child: Container(
            height: 2,
            color: emailDone ? scheme.primary : scheme.onSurface.withOpacity(0.12),
          ),
        ),
        _StepDot(index: 1, label: 'Identity', done: identityDone, active: emailDone && !identityDone),
      ],
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
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
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