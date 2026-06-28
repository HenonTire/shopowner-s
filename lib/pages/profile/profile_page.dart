import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/dashboard_drawer_models.dart';
import 'package:shop_manager/pages/dashboard_drawer_navigation.dart';
import 'package:shop_manager/pages/profile/change_password.dart';
import 'package:shop_manager/pages/profile/profile_edit.dart';
import 'package:shop_manager/pages/profile/verify_account.dart';
import 'package:shop_manager/services/auth_service.dart';
import 'package:shop_manager/theme/app_themes.dart';
import 'package:shop_manager/widgets/shop_owner_dashboard_drawer.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({
    super.key,
    this.isDarkMode = false,
    this.onThemeChanged,
    this.onOpenMarketers,
  });

  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;
  final VoidCallback? onOpenMarketers;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final List<String> _languages = <String>['English', 'Amharic', 'Oromo'];
  final List<String> _currencies = <String>['ETB', 'USD', 'KES'];
  final List<String> _processingTimes = <String>[
    'Same day',
    '1 business day',
    '2 business days',
    '3 business days',
  ];

  String _language = 'English';
  String _currency = 'ETB';
  String _processingTime = '1 business day';
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _shopOpen = true;
  bool _pickupAvailable = true;

  // Saving states for inline sections
  bool _savingDelivery = false;
  bool _savingNotifications = false;
  bool _savingPreferences = false;

  AuthUser? get _user => AuthSessionStore.user;
  bool get _isSeller => (_user?.role.toLowerCase() ?? 'shop').contains('shop');
  String get _ownerName => _valueOrFallback(_user?.name, 'Lovely Shop');
  String get _shopName => _valueOrFallback(_user?.shopName, 'Shikela Shop');
  String get _email => _valueOrFallback(_user?.email, 'henon@shikela.com');

  String _valueOrFallback(String? value, String fallback) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }

  void _showSnack(String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      
      SnackBar(
        content: Text(
          message,
          style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onPrimary ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAction(String label) => _showSnack('$label is ready for integration.');

  Future<void> _saveDelivery() async {
    setState(() => _savingDelivery = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    // TODO: call your delivery settings API here
    if (!mounted) return;
    setState(() => _savingDelivery = false);
    _showSnack('Delivery settings saved.');
  }

  Future<void> _saveNotifications() async {
    setState(() => _savingNotifications = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    // TODO: call your notifications API here
    if (!mounted) return;
    setState(() => _savingNotifications = false);
    _showSnack('Notification preferences saved.');
  }

  Future<void> _savePreferences() async {
    setState(() => _savingPreferences = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    // TODO: call your preferences API here
    if (!mounted) return;
    setState(() => _savingPreferences = false);
    _showSnack('Preferences saved.');
  }

  void _navigateEdit(String section) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProfileEditPage(
          section: section,
          isDarkMode: widget.isDarkMode,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    return ShopOwnerDashboardDrawer(
      isDarkMode: widget.isDarkMode,
      onThemeChanged: widget.onThemeChanged,
      shopName: _shopName,
      ownerName: _ownerName,
      businessStatus: _shopOpen ? 'Business Active' : 'Business Closed',
      subscriptionLabel: 'VIP Pro',
      onClose: () => Navigator.of(context).pop(),
      onMenuItemSelected: (DashboardDrawerItemId itemId) {
        Navigator.of(context).pop();
        handleDashboardDrawerItemTap(context, itemId);
      },
      onQuickActionSelected: (DashboardQuickActionId quickActionId) {
        Navigator.of(context).pop();
        handleDashboardQuickActionTap(context, quickActionId);
      },
    );
  }

  Color _mutedTextColor(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.colorScheme.onSurface.withOpacity(
      theme.brightness == Brightness.dark ? 0.78 : 0.64,
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: AppThemes.poppins(
        context,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _mutedTextColor(context),
      ),
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
      endDrawer: _buildSideMenu(context),
      body: Builder(
        builder: (BuildContext scaffoldContext) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[bgTop, bgBottom, bgBottom],
                stops: const <double>[0.0, 0.22, 1.0],
              ),
            ),
            child: SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: <Widget>[
                  _Header(
                    title: 'Profile',
                    subtitle: 'Manage account.',
                    onMarketersPressed: widget.onOpenMarketers ?? () => _showAction('Marketers'),
                    onMenuPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
                  ),
                  const SizedBox(height: 14),
                  _ProfileHero(
                    name: _ownerName,
                    email: _email,
                    phone: '+251 911 234 567',
                    username: '@${_ownerName.toLowerCase().replaceAll(' ', '')}',
                    statusLabel: _shopOpen ? 'Seller account' : 'Shop closed',
                    onEdit: () => _showAction('Edit shop'),
                  ),
                  const SizedBox(height: 12),

                  // ── Personal Information ──
                  _SectionCard(
                    title: 'Personal Information',
                    icon: Icons.person_outline_rounded,
                    trailing: _CardAction(label: 'Edit', onTap: () => _navigateEdit('personal')),
                    children: <Widget>[
                      _InfoRow(icon: Icons.badge_outlined, label: 'Full name', value: _ownerName),
                      _InfoRow(icon: Icons.mail_outline_rounded, label: 'Email address', value: _email),
                      const _InfoRow(icon: Icons.phone_outlined, label: 'Phone number', value: '+251 911 234 567'),
                      _InfoRow(
                        icon: Icons.alternate_email_rounded,
                        label: 'Username',
                        value: '@${_ownerName.toLowerCase().replaceAll(' ', '')}',
                      ),
                    ],
                  ),

                  // ── Address ──
                  _SectionCard(
                    title: 'Address Management',
                    icon: Icons.location_on_outlined,
                    trailing: _CardAction(label: 'Add', onTap: () => _navigateEdit('address')),
                    children: <Widget>[
                      _AddressTile(
                        title: 'Default shipping address',
                        address: 'Bole Road, Addis Ababa, Ethiopia',
                        badge: 'Default',
                        onEdit: () => _navigateEdit('address'),
                        onDelete: () => _showAction('Delete shipping address'),
                      ),
                      const SizedBox(height: 10),
                      _AddressTile(
                        title: 'Billing address',
                        address: 'Kazanchis, Addis Ababa, Ethiopia',
                        badge: 'Billing',
                        onEdit: () => _navigateEdit('address'),
                        onDelete: () => _showAction('Delete billing address'),
                      ),
                    ],
                  ),

                  // ── Shop Settings ──
                  if (_isSeller)
                    _SectionCard(
                      title: 'Shop Settings',
                      icon: Icons.storefront_outlined,
                      trailing: _CardAction(label: 'Edit', onTap: () => _showAction('Edit shop information')),
                      children: <Widget>[
                        _ShopMediaRow(shopName: _shopName),
                        const SizedBox(height: 12),
                        _InfoRow(icon: Icons.store_mall_directory_outlined, label: 'Shop name', value: _shopName),
                        const _InfoRow(
                          icon: Icons.notes_rounded,
                          label: 'Description',
                          value: 'Daily essentials, fresh inventory, and reliable delivery.',
                        ),
                        const SizedBox(height: 8),
                        const _InfoRow(icon: Icons.palette_outlined, label: 'Theme', value: 'Main Theme'),
                      ],
                    ),

                  // ── Payment ──
                  _SectionCard(
                    title: 'Payment Methods',
                    icon: Icons.account_balance_wallet_outlined,
                    trailing: _CardAction(label: 'Add', onTap: () => _navigateEdit('payment')),
                    children: <Widget>[
                      _PaymentTile(
                        icon: Icons.credit_card_rounded,
                        title: 'Visa ending 4821',
                        subtitle: 'Default payment method',
                        isDefault: true,
                        onRemove: () => _showAction('Remove Visa ending 4821'),
                      ),
                      const SizedBox(height: 10),
                      _PaymentTile(
                        icon: Icons.phone_android_rounded,
                        title: 'Telebirr',
                        subtitle: '+251 911 234 567',
                        isDefault: false,
                        onRemove: () => _showAction('Remove Telebirr'),
                      ),
                      if (_isSeller) ...<Widget>[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        const _InfoRow(icon: Icons.payments_outlined, label: 'Payout account', value: 'Commercial Bank of Ethiopia'),
                        const _InfoRow(icon: Icons.account_balance_outlined, label: 'Bank account', value: '**** 7392'),
                        const _InfoRow(icon: Icons.mobile_friendly_rounded, label: 'Preferred payout', value: 'Bank transfer'),
                      ],
                    ],
                  ),

                  // ── Delivery & Shipping (inline save) ──
                  _SectionCard(
                    title: 'Delivery & Shipping',
                    icon: Icons.local_shipping_outlined,
                    children: <Widget>[
                      const _InfoRow(icon: Icons.map_outlined, label: 'Delivery regions', value: 'Addis Ababa, Adama, Bishoftu'),
                      const _InfoRow(icon: Icons.sell_outlined, label: 'Delivery fee', value: 'ETB 75.00'),
                      _SwitchRow(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Pickup availability',
                        subtitle: _pickupAvailable ? 'Customers can pick up orders' : 'Pickup is disabled',
                        value: _pickupAvailable,
                        onChanged: (bool value) => setState(() => _pickupAvailable = value),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _processingTime,
                        isExpanded: true,
                        decoration: _inputDecoration(context, 'Processing time'),
                        items: _processingTimes
                            .map((String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          if (value != null) setState(() => _processingTime = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      _SaveButton(saving: _savingDelivery, onSave: _saveDelivery),
                    ],
                  ),

                  // ── Notifications (inline save) ──
                  _SectionCard(
                    title: 'Notifications',
                    icon: Icons.notifications_none_rounded,
                    children: <Widget>[
                      _SwitchRow(
                        icon: Icons.notifications_active_outlined,
                        title: 'Push notifications',
                        subtitle: 'Alerts on this device',
                        value: _pushNotifications,
                        onChanged: (bool value) => setState(() => _pushNotifications = value),
                      ),
                      _SwitchRow(
                        icon: Icons.mark_email_unread_outlined,
                        title: 'Email notifications',
                        subtitle: 'Account and order emails',
                        value: _emailNotifications,
                        onChanged: (bool value) => setState(() => _emailNotifications = value),
                      ),
                      const SizedBox(height: 10),
                      _SaveButton(saving: _savingNotifications, onSave: _saveNotifications),
                    ],
                  ),

                  // ── Security ──
                  _SectionCard(
                    title: 'Security',
                    icon: Icons.lock_outline_rounded,
                    children: <Widget>[
                      _ActionRow(
                        icon: Icons.password_rounded,
                        title: 'Change password',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const ChangePasswordPage()),
                        ),
                      ),
                      _ActionRow(
                        icon: Icons.verified_user_outlined,
                        title: 'Verify account',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => VerifyAccountPage(userEmail: _email),
                          ),
                        ),
                      ),
                      _ActionRow(
                        icon: Icons.logout_rounded,
                        title: 'Logout from all devices',
                        onTap: () => _showAction('Logout from all devices'),
                      ),
                      _ActionRow(
                        icon: Icons.delete_outline_rounded,
                        title: 'Delete account',
                        isDestructive: true,
                        onTap: () => _showAction('Delete account'),
                      ),
                    ],
                  ),

                  // ── Preferences (inline save) ──
                  _SectionCard(
                    title: 'Preferences',
                    icon: Icons.tune_rounded,
                    children: <Widget>[
                      DropdownButtonFormField<String>(
                        initialValue: _language,
                        isExpanded: true,
                        decoration: _inputDecoration(context, 'Language'),
                        items: _languages
                            .map((String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          if (value != null) setState(() => _language = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _currency,
                        isExpanded: true,
                        decoration: _inputDecoration(context, 'Currency'),
                        items: _currencies
                            .map((String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          if (value != null) setState(() => _currency = value);
                        },
                      ),
                      const SizedBox(height: 4),
                      _SwitchRow(
                        icon: widget.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                        title: 'Dark mode',
                        subtitle: widget.isDarkMode ? 'Dark appearance enabled' : 'Light appearance enabled',
                        value: widget.isDarkMode,
                        onChanged: widget.onThemeChanged,
                      ),
                      const SizedBox(height: 10),
                      _SaveButton(saving: _savingPreferences, onSave: _savePreferences),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Inline Save Button
// ══════════════════════════════════════════════
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saving, required this.onSave});
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox(
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
                child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
              )
            : Text(
                'Save changes',
                style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimary),
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// All original private widgets below (unchanged)
// ══════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onMarketersPressed,
    required this.onMenuPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onMarketersPressed;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: AppThemes.poppins(context, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle, style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w500, color: scheme.onSurface.withOpacity(0.66))),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: scheme.onPrimary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.onSurface.withOpacity(0.12), width: 0.6),
          ),
          child: IconButton(tooltip: 'Open marketers', onPressed: onMarketersPressed, icon: Icon(Icons.campaign_rounded, color: scheme.primary)),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: scheme.onPrimary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.onSurface.withOpacity(0.12), width: 0.6),
          ),
          child: IconButton(tooltip: 'Open menu', onPressed: onMenuPressed, icon: Icon(Icons.tune_rounded, color: scheme.primary)),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.phone,
    required this.username,
    required this.statusLabel,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String phone;
  final String username;
  final String statusLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(color: scheme.primary.withOpacity(0.08)),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFF1B8F4D).withOpacity(0.14), borderRadius: BorderRadius.circular(999)),
                child: Text(statusLabel, style: AppThemes.poppins(context, fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF1B8F4D))),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -32),
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: scheme.surface, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: scheme.primary.withOpacity(0.10),
                    child: Text(_initials(name), style: AppThemes.poppins(context, fontSize: 19, fontWeight: FontWeight.w700, color: scheme.primary)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(name, style: AppThemes.poppins(context, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(email, style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.62), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('$phone  •  $username', style: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.50), fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text('Edit Shop', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'SM';
    if (parts.length == 1) {
      final String v = parts.first;
      return v.substring(0, v.length < 2 ? v.length : 2).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.children, this.trailing});
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 14, offset: const Offset(0, 7))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 34, width: 34,
                decoration: BoxDecoration(color: scheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: scheme.primary, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoRow extends StatefulWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  State<_InfoRow> createState() => _InfoRowState();
}

class _InfoRowState extends State<_InfoRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle valueStyle = AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(widget.icon, size: 18, color: scheme.onSurface.withOpacity(0.58)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.label, style: AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.normal, color: scheme.onSurface.withOpacity(0.58))),
                const SizedBox(height: 2),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final TextPainter painter = TextPainter(
                      text: TextSpan(text: widget.value, style: valueStyle),
                      maxLines: 1,
                      textDirection: TextDirection.ltr,
                    )..layout(maxWidth: constraints.maxWidth);
                    final bool isOverflowing = painter.didExceedMaxLines;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(widget.value, maxLines: _expanded ? null : 1, overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis, style: valueStyle),
                        if (isOverflowing)
                          GestureDetector(
                            onTap: () => setState(() => _expanded = !_expanded),
                            child: Text(_expanded ? 'Show less' : 'More', style: AppThemes.poppins(context, fontSize: 9, fontWeight: FontWeight.w700, color: scheme.primary)),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

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
                Text(subtitle, style: AppThemes.poppins(context, fontSize: 9, fontWeight: FontWeight.w500, color: scheme.onSurface.withOpacity(0.56))),
              ],
            ),
          ),
          Transform.scale(scale: 0.82, child: Switch(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, value: value, onChanged: onChanged)),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.title, required this.address, required this.badge, required this.onEdit, required this.onDelete});
  final String title;
  final String address;
  final String badge;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.location_on_outlined, color: scheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(children: <Widget>[
                  Expanded(child: Text(title, style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700))),
                  _StatusBadge(label: badge),
                ]),
                const SizedBox(height: 4),
                Text(address, style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSurface.withOpacity(0.64))),
                const SizedBox(height: 8),
                Row(children: <Widget>[
                  _InlineAction(label: 'Edit', onTap: onEdit),
                  const SizedBox(width: 8),
                  _InlineAction(label: 'Delete', onTap: onDelete, isDestructive: true),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.icon, required this.title, required this.subtitle, required this.isDefault, required this.onRemove});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDefault;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Container(height: 42, width: 42, decoration: BoxDecoration(color: scheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: scheme.primary, size: 21)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: <Widget>[
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700))),
                if (isDefault) const _StatusBadge(label: 'Default'),
              ]),
              Text(subtitle, style: AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.w500, color: scheme.onSurface.withOpacity(0.58))),
            ],
          ),
        ),
        IconButton(tooltip: 'Remove payment method', onPressed: onRemove, icon: const Icon(Icons.close_rounded, size: 19)),
      ],
    );
  }
}

class _ShopMediaRow extends StatelessWidget {
  const _ShopMediaRow({required this.shopName});
  final String shopName;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        CircleAvatar(radius: 25, backgroundColor: scheme.primary.withOpacity(0.10), child: Icon(Icons.storefront_rounded, color: scheme.primary, size: 25)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: scheme.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: scheme.primary.withOpacity(0.12))),
            alignment: Alignment.centerLeft,
            child: Text('$shopName banner', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700, color: scheme.primary)),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.title, required this.onTap, this.isDestructive = false});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = isDestructive ? const Color(0xFFC62828) : scheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 19, color: color.withOpacity(isDestructive ? 1 : 0.62)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: color))),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withOpacity(0.42)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({required this.label, required this.onTap, this.isDestructive = false});
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color color = isDestructive ? const Color(0xFFC62828) : Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Text(label, style: AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFF1B8F4D).withOpacity(0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: AppThemes.poppins(context, fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF1B8F4D))),
    );
  }
}