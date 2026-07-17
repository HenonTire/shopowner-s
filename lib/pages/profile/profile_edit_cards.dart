import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop_manager/theme/app_themes.dart';

// ─────────────────────────────────────────────
// ENTRY POINT — drop any of these cards into
// your edit screens wherever you need them.
// ─────────────────────────────────────────────

// ══════════════════════════════════════════════
// 1. PERSONAL INFORMATION EDIT CARD
// ══════════════════════════════════════════════
class PersonalInfoEditCard extends StatefulWidget {
  const PersonalInfoEditCard({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.initialUsername,
    required this.onSave,
  });

  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String initialUsername;
  final Future<void> Function({
    required String name,
    required String email,
    required String phone,
    required String username,
  }) onSave;

  @override
  State<PersonalInfoEditCard> createState() => _PersonalInfoEditCardState();
}
class _PersonalInfoEditCardState extends State<PersonalInfoEditCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _usernameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
    _usernameCtrl = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('AuthFailure: ', ''),
              style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onError),
            ),
            backgroundColor: scheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return _EditCard(
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      onSave: _submit,
      saving: _saving,
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            _Field(
              controller: _nameCtrl,
              label: 'Full name',
              icon: Icons.badge_outlined,
              validator: _requiredValidator('Full name'),
            ),
            _Field(
              controller: _emailCtrl,
              label: 'Email address',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            _Field(
              controller: _phoneCtrl,
              label: 'Phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[+\d\s]')),
              ],
              validator: _requiredValidator('Phone number'),
            ),
            _Field(
              controller: _usernameCtrl,
              label: 'Username',
              icon: Icons.alternate_email_rounded,
              validator: _requiredValidator('Username'),
              hint: '@yourname',
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 2. ADDRESS EDIT CARD
// ══════════════════════════════════════════════
class AddressEditCard extends StatefulWidget {
  const AddressEditCard({
    super.key,
    required this.initialShipping,
    required this.initialBilling,
    required this.onSave,
  });

  final String initialShipping;
  final String initialBilling;
  final Future<void> Function({
    required String shipping,
    required String billing,
  }) onSave;

  @override
  State<AddressEditCard> createState() => _AddressEditCardState();
}

class _AddressEditCardState extends State<AddressEditCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _shippingCtrl;
  late final TextEditingController _billingCtrl;
  bool _saving = false;
  bool _sameBilling = false;

  @override
  void initState() {
    super.initState();
    _shippingCtrl = TextEditingController(text: widget.initialShipping);
    _billingCtrl = TextEditingController(text: widget.initialBilling);
  }

  @override
  void dispose() {
    _shippingCtrl.dispose();
    _billingCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        shipping: _shippingCtrl.text.trim(),
        billing: _sameBilling ? _shippingCtrl.text.trim() : _billingCtrl.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onError),
            ),
            backgroundColor: scheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return _EditCard(
      title: 'Address Management',
      icon: Icons.location_on_outlined,
      onSave: _submit,
      saving: _saving,
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            _SectionLabel(label: 'Shipping address'),
            _Field(
              controller: _shippingCtrl,
              label: 'Street, city, country',
              icon: Icons.local_shipping_outlined,
              maxLines: 2,
              validator: _requiredValidator('Shipping address'),
              onChanged: (_) {
                if (_sameBilling) setState(() {});
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Transform.scale(
                  scale: 0.82,
                  child: Checkbox(
                    value: _sameBilling,
                    onChanged: (bool? v) => setState(() => _sameBilling = v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                Text(
                  'Same as billing address',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withOpacity(0.72),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_sameBilling) ...<Widget>[
              _SectionLabel(label: 'Billing address'),
              _Field(
                controller: _billingCtrl,
                label: 'Street, city, country',
                icon: Icons.receipt_long_outlined,
                maxLines: 2,
                validator: _requiredValidator('Billing address'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 3. PAYMENT METHODS EDIT CARD
// ══════════════════════════════════════════════
class PaymentEditCard extends StatefulWidget {
  const PaymentEditCard({
    super.key,
    required this.initialMobile,
    required this.initialPayoutBank,
    required this.initialBankAccount,
    required this.isSeller,
    required this.onSave,
  });

  final String initialMobile;
  final String initialPayoutBank;
  final String initialBankAccount;
  final bool isSeller;
  final Future<void> Function({
    required String mobile,
    required String payoutBank,
    required String bankAccount,
  }) onSave;

  @override
  State<PaymentEditCard> createState() => _PaymentEditCardState();
}

class _PaymentEditCardState extends State<PaymentEditCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _bankAccountCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mobileCtrl = TextEditingController(text: widget.initialMobile);
    _bankNameCtrl = TextEditingController(text: widget.initialPayoutBank);
    _bankAccountCtrl = TextEditingController(text: widget.initialBankAccount);
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        mobile: _mobileCtrl.text.trim(),
        payoutBank: _bankNameCtrl.text.trim(),
        bankAccount: _bankAccountCtrl.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onError),
            ),
            backgroundColor: scheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      title: 'Payment Methods',
      icon: Icons.account_balance_wallet_outlined,
      onSave: _submit,
      saving: _saving,
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            _SectionLabel(label: 'Mobile money'),
            _Field(
              controller: _mobileCtrl,
              label: 'Telebirr number',
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              validator: _requiredValidator('Mobile number'),
            ),
            if (widget.isSeller) ...<Widget>[
              const SizedBox(height: 4),
              _SectionLabel(label: 'Payout details'),
              _Field(
                controller: _bankNameCtrl,
                label: 'Payout bank',
                icon: Icons.account_balance_outlined,
                validator: _requiredValidator('Payout bank'),
              ),
              _Field(
                controller: _bankAccountCtrl,
                label: 'Bank account number',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: _requiredValidator('Bank account'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 4. DELIVERY & SHIPPING EDIT CARD
// ══════════════════════════════════════════════
class DeliveryEditCard extends StatefulWidget {
  const DeliveryEditCard({
    super.key,
    required this.initialRegions,
    required this.initialFee,
    required this.initialPickup,
    required this.initialProcessingTime,
    required this.processingTimes,
    required this.onSave,
  });

  final String initialRegions;
  final String initialFee;
  final bool initialPickup;
  final String initialProcessingTime;
  final List<String> processingTimes;
  final Future<void> Function({
    required String regions,
    required String fee,
    required bool pickup,
    required String processingTime,
  }) onSave;

  @override
  State<DeliveryEditCard> createState() => _DeliveryEditCardState();
}

class _DeliveryEditCardState extends State<DeliveryEditCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _regionsCtrl;
  late final TextEditingController _feeCtrl;
  late bool _pickup;
  late String _processingTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _regionsCtrl = TextEditingController(text: widget.initialRegions);
    _feeCtrl = TextEditingController(text: widget.initialFee);
    _pickup = widget.initialPickup;
    _processingTime = widget.initialProcessingTime;
  }

  @override
  void dispose() {
    _regionsCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        regions: _regionsCtrl.text.trim(),
        fee: _feeCtrl.text.trim(),
        pickup: _pickup,
        processingTime: _processingTime,
      );
    } catch (e) {
      if (mounted) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onError),
            ),
            backgroundColor: scheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      title: 'Delivery & Shipping',
      icon: Icons.local_shipping_outlined,
      onSave: _submit,
      saving: _saving,
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            _Field(
              controller: _regionsCtrl,
              label: 'Delivery regions (comma separated)',
              icon: Icons.map_outlined,
              hint: 'Addis Ababa, Adama, Bishoftu',
              maxLines: 2,
              validator: _requiredValidator('Delivery regions'),
            ),
            _Field(
              controller: _feeCtrl,
              label: 'Delivery fee (ETB)',
              icon: Icons.sell_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: _requiredValidator('Delivery fee'),
            ),
            const SizedBox(height: 4),
            _ToggleRow(
              icon: Icons.shopping_bag_outlined,
              title: 'Pickup availability',
              subtitle: _pickup ? 'Customers can pick up orders' : 'Pickup is disabled',
              value: _pickup,
              onChanged: (bool v) => setState(() => _pickup = v),
            ),
            const SizedBox(height: 10),
            _DropdownField<String>(
              label: 'Processing time',
              icon: Icons.timelapse_rounded,
              value: _processingTime,
              items: widget.processingTimes,
              onChanged: (String? v) {
                if (v != null) setState(() => _processingTime = v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 5. NOTIFICATIONS EDIT CARD
// ══════════════════════════════════════════════
class NotificationsEditCard extends StatefulWidget {
  const NotificationsEditCard({
    super.key,
    required this.initialPush,
    required this.initialEmail,
    required this.onSave,
  });

  final bool initialPush;
  final bool initialEmail;
  final Future<void> Function({required bool push, required bool email}) onSave;

  @override
  State<NotificationsEditCard> createState() => _NotificationsEditCardState();
}

class _NotificationsEditCardState extends State<NotificationsEditCard> {
  late bool _push;
  late bool _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _push = widget.initialPush;
    _email = widget.initialEmail;
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(push: _push, email: _email);
    } catch (e) {
      if (mounted) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onError),
            ),
            backgroundColor: scheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      title: 'Notifications',
      icon: Icons.notifications_none_rounded,
      onSave: _submit,
      saving: _saving,
      child: Column(
        children: <Widget>[
          _ToggleRow(
            icon: Icons.notifications_active_outlined,
            title: 'Push notifications',
            subtitle: 'Alerts on this device',
            value: _push,
            onChanged: (bool v) => setState(() => _push = v),
          ),
          _ToggleRow(
            icon: Icons.mark_email_unread_outlined,
            title: 'Email notifications',
            subtitle: 'Account and order emails',
            value: _email,
            onChanged: (bool v) => setState(() => _email = v),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 6. SECURITY EDIT CARD
// ══════════════════════════════════════════════
class SecurityEditCard extends StatefulWidget {
  const SecurityEditCard({
    super.key,
    required this.onSave,
    required this.onLogoutAll,
    required this.onDeleteAccount,
  });

  final void Function({
    required String currentPassword,
    required String newPassword,
  }) onSave;
  final VoidCallback onLogoutAll;
  final VoidCallback onDeleteAccount;

  @override
  State<SecurityEditCard> createState() => _SecurityEditCardState();
}

class _SecurityEditCardState extends State<SecurityEditCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

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
    await Future<void>.delayed(const Duration(milliseconds: 600));
    widget.onSave(
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
    );
    _currentCtrl.clear();
    _newCtrl.clear();
    _confirmCtrl.clear();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return _EditCard(
      title: 'Security',
      icon: Icons.lock_outline_rounded,
      onSave: _submit,
      saving: _saving,
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            _SectionLabel(label: 'Change password'),
            _Field(
              controller: _currentCtrl,
              label: 'Current password',
              icon: Icons.lock_outline_rounded,
              obscureText: !_showCurrent,
              suffixIcon: IconButton(
                icon: Icon(_showCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                onPressed: () => setState(() => _showCurrent = !_showCurrent),
              ),
              validator: _requiredValidator('Current password'),
            ),
            _Field(
              controller: _newCtrl,
              label: 'New password',
              icon: Icons.vpn_key_outlined,
              obscureText: !_showNew,
              suffixIcon: IconButton(
                icon: Icon(_showNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                onPressed: () => setState(() => _showNew = !_showNew),
              ),
              validator: (String? v) {
                if (v == null || v.isEmpty) return 'New password is required';
                if (v.length < 8) return 'At least 8 characters';
                return null;
              },
            ),
            _Field(
              controller: _confirmCtrl,
              label: 'Confirm new password',
              icon: Icons.check_circle_outline_rounded,
              obscureText: !_showConfirm,
              suffixIcon: IconButton(
                icon: Icon(_showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                onPressed: () => setState(() => _showConfirm = !_showConfirm),
              ),
              validator: (String? v) {
                if (v != _newCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _DangerRow(
              icon: Icons.logout_rounded,
              label: 'Logout from all devices',
              color: scheme.onSurface,
              onTap: widget.onLogoutAll,
            ),
            const SizedBox(height: 6),
            _DangerRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete account',
              color: const Color(0xFFC62828),
              onTap: widget.onDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 7. 885ERENCES EDIT CARD
// ══════════════════════════════════════════════
class PreferencesEditCard extends StatefulWidget {
  const PreferencesEditCard({
    super.key,
    required this.initialLanguage,
    required this.initialCurrency,
    required this.initialDarkMode,
    required this.languages,
    required this.currencies,
    required this.onSave,
    this.onThemeChanged,
  });

  final String initialLanguage;
  final String initialCurrency;
  final bool initialDarkMode;
  final List<String> languages;
  final List<String> currencies;
  final void Function({
    required String language,
    required String currency,
    required bool darkMode,
  }) onSave;
  final ValueChanged<bool>? onThemeChanged;

  @override
  State<PreferencesEditCard> createState() => _PreferencesEditCardState();
}

class _PreferencesEditCardState extends State<PreferencesEditCard> {
  late String _language;
  late String _currency;
  late bool _darkMode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _currency = widget.initialCurrency;
    _darkMode = widget.initialDarkMode;
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    widget.onSave(language: _language, currency: _currency, darkMode: _darkMode);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      title: 'Preferences',
      icon: Icons.tune_rounded,
      onSave: _submit,
      saving: _saving,
      child: Column(
        children: <Widget>[
          _DropdownField<String>(
            label: 'Language',
            icon: Icons.language_rounded,
            value: _language,
            items: widget.languages,
            onChanged: (String? v) {
              if (v != null) setState(() => _language = v);
            },
          ),
          const SizedBox(height: 10),
          _DropdownField<String>(
            label: 'Currency',
            icon: Icons.attach_money_rounded,
            value: _currency,
            items: widget.currencies,
            onChanged: (String? v) {
              if (v != null) setState(() => _currency = v);
            },
          ),
          const SizedBox(height: 4),
          _ToggleRow(
            icon: _darkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            title: 'Dark mode',
            subtitle: _darkMode ? 'Dark appearance enabled' : 'Light appearance enabled',
            value: _darkMode,
            onChanged: (bool v) {
              setState(() => _darkMode = v);
              widget.onThemeChanged?.call(v);
            },
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
// SHARED PRIVATE BUILDING BLOCKS
// ═════════════════════════════════════════════

class _EditCard extends StatelessWidget {
  const _EditCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.onSave,
    required this.saving,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          Row(
            children: <Widget>[
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: scheme.primary, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 16),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saving ? null : onSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: saving
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : Text(
                      'Save changes',
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
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.inputFormatters,
    this.validator,
    this.hint,
    this.suffixIcon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final String? hint;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedColor = scheme.onSurface.withOpacity(isDark ? 0.78 : 0.64);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: onChanged,
        style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.35)),
          labelStyle: AppThemes.poppins(
            context,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: mutedColor,
          ),
          prefixIcon: Icon(icon, size: 18, color: scheme.onSurface.withOpacity(0.52)),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: scheme.onPrimary.withOpacity(0.03),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.14), width: 0.7),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.14), width: 0.7),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary.withOpacity(0.40), width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC62828), width: 0.8),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC62828), width: 1),
          ),
          errorStyle: AppThemes.poppins(context, fontSize: 10, color: const Color(0xFFC62828)),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: scheme.onSurface.withOpacity(0.52), size: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppThemes.poppins(
          context,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface.withOpacity(isDark ? 0.78 : 0.64),
        ),
        prefixIcon: Icon(icon, size: 18, color: scheme.onSurface.withOpacity(0.52)),
        filled: true,
        fillColor: scheme.onPrimary.withOpacity(0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.14), width: 0.7),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.14), width: 0.7),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.40), width: 1),
        ),
      ),
      items: items
          .map(
            (T item) => DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString(), style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 19, color: scheme.onSurface.withOpacity(0.58)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(
                  subtitle,
                  style: AppThemes.poppins(
                    context,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withOpacity(0.56),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppThemes.poppins(
          context,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withOpacity(0.50),
        ),
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 19, color: color.withOpacity(0.80)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.40)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// SHARED VALIDATOR HELPER
// ═════════════════════════════════════════════
FormFieldValidator<String> _requiredValidator(String fieldName) {
  return (String? value) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  };
}