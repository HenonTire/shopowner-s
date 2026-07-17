import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/dashboard_drawer_models.dart';
import 'package:shop_manager/models/shop.dart';
import 'package:shop_manager/pages/dashboard_drawer_navigation.dart';
import 'package:shop_manager/pages/profile/change_password.dart';
import 'package:shop_manager/pages/profile/edit_shop.dart';
import 'package:shop_manager/services/notification_repository.dart';
import 'package:shop_manager/services/payment_repository.dart';
import 'package:shop_manager/services/shop_repository.dart';
import 'package:shop_manager/pages/profile/profile_edit.dart';
import 'package:shop_manager/pages/profile/verify_account.dart';
import 'package:shop_manager/services/auth_service.dart';
import 'package:shop_manager/theme/app_themes.dart';
import 'package:shop_manager/widgets/shop_owner_dashboard_drawer.dart';
import 'package:shop_manager/services/address_repository.dart';
import 'package:shop_manager/services/delivery_repository.dart';
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
  Future<Shop>? _shopFuture;
  Future<DeliverySettings>? _deliveryFuture;
  final List<String> _languages = <String>['English', 'Amharic'];
  final List<String> _currencies = <String>['ETB', 'USD', 'KES'];
  String _language = 'English';
  String _currency = 'ETB';
  final bool _shopOpen = true;


  // Saving states for inline sections


  bool _savingPreferences = false;

  AuthUser? get _user => AuthSessionStore.user;
  bool get _isSeller => (_user?.role.toLowerCase() ?? 'shop').contains('shop');

  String get _ownerName => _valueOrFallback(_user?.name, 'Unknown User');
  String get _email => _valueOrFallback(_user?.email, 'No email');
  // Fallback only — AuthUser.shopName comes from the login response and is
  // often empty. The real shop name comes from _shopFuture (Shop.name).
  String get _shopName => _valueOrFallback(_user?.shopName, 'Shikela Shop');
  String get _username => _email.contains('@')
      ? '@${_email.split('@').first}'
      : '@${_ownerName.toLowerCase().replaceAll(' ', '')}';
  String get _phone => _valueOrFallback(_user?.phone, 'No phone number');

  @override
  void initState() {
    super.initState();
    _loadShop();
    _loadProfile();
    _loadAddresses();
    _loadDelivery();
     _loadNotifications();
  }
  void _loadDelivery() {
    setState(() {
      _deliveryFuture = DeliveryRepository().fetchMyDeliverySettings();
    });
  }
  Future<NotificationSettings>? _notificationFuture;
  void _loadNotifications() {
    setState(() {
      _notificationFuture = NotificationRepository().fetchMyNotificationSettings();
    });
  }
  void _loadProfile() {
    BackendAuthService().fetchMyProfile().then((_) {
      if (mounted) setState(() {});
    }).catchError((Object e) {
      print('DEBUG profile fetch failed: $e');
    });
  }
  Future<AddressPair>? _addressFuture;
  void _loadAddresses() {
    setState(() {
      _addressFuture = AddressRepository().fetchMyAddresses();
    });
  }

  void _loadShop() {
    setState(() {
      _shopFuture = BackendShopRepository().fetchMyShop();
    });
  }

  Future<void> _refreshAll() async {
    
    _loadShop();
    _loadAddresses();
    _loadDelivery();
    _loadNotifications();
    try {
      await BackendAuthService().fetchMyProfile();
    } catch (_) {
      // silently ignore — page just keeps showing whatever data it already has
    }
    if (mounted) setState(() {});
  }

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
          style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onPrimary),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAction(String label) => _showSnack('$label is ready for integration.');

  Future<void> _navigateToEditShop(Shop? cachedShop) async {
    Shop shop;
    if (cachedShop != null) {
      shop = cachedShop;
    } else {
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      try {
        shop = await BackendShopRepository().fetchMyShop();
        if (!context.mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          messenger.showSnackBar(SnackBar(content: Text('Failed to load shop: $e')));
        });
        return;
      }
    }

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => EditShopPage(shop: shop)),
    );

    // Refresh Shop Settings section in case something changed.
    _loadShop();
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
              child: RefreshIndicator(
                onRefresh: _refreshAll,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  children: <Widget>[
                    _Header(
                      title: 'Profile',
                      subtitle: 'Manage account.',
                      onMarketersPressed: widget.onOpenMarketers ?? () => _showAction('Marketers'),
                      onMenuPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
                    ),
                    const SizedBox(height: 14),

                    // ── Hero: renders instantly from AuthUser, fills in shop name/logo/banner once shop loads ──
                    FutureBuilder<Shop>(
                      future: _isSeller ? _shopFuture : null,
                      builder: (BuildContext context, AsyncSnapshot<Shop> snapshot) {
                        final Shop? shop = snapshot.data;
                        final String heroName = (shop != null && shop.name.trim().isNotEmpty)
                            ? shop.name
                            : _shopName;
                        return _ProfileHero(
                          name: heroName,
                          email: _email,
                          phone: _phone,
                          username: _username,
                          statusLabel: _shopOpen ? 'Seller account' : 'Shop closed',
                          logoUrl: shop?.themeSettings.logo,
                          bannerUrl: shop?.themeSettings.bannerImage,
                          onEdit: () => _navigateToEditShop(shop),
                        );
                      },
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
                        _InfoRow(icon: Icons.phone_outlined, label: 'Phone number', value: _phone),
                        _InfoRow(
                          icon: Icons.alternate_email_rounded,
                          label: 'Username',
                          value: _username,
                        ),
                      ],
                    ),

                    // ── Address ──
                   FutureBuilder<AddressPair>(
                      future: _addressFuture,
                      builder: (BuildContext context, AsyncSnapshot<AddressPair> snapshot) {
                        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                        final AddressPair? pair = snapshot.data;
                        final String? shipping = pair?.shipping;
                        final String? billing = pair?.billing;

                        return _SectionCard(
                          title: 'Address Management',
                          icon: Icons.location_on_outlined,
                          trailing: _CardAction(label: 'Edit', onTap: () => _navigateEdit('address')),
                          children: <Widget>[
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(minHeight: 3),
                              )
                            else ...<Widget>[
                              if (shipping != null && shipping.isNotEmpty)
                                _AddressTile(
                                  title: 'Default shipping address',
                                  address: shipping,
                                  badge: 'Default',
                                  onEdit: () => _navigateEdit('address'),
                                  onDelete: () async {
                                    await AddressRepository().deleteAddress('shipping');
                                    _loadAddresses();
                                  },
                                )
                              else
                                _EmptyAddressRow(label: 'No shipping address set.', onAdd: () => _navigateEdit('address')),
                              const SizedBox(height: 10),
                              if (billing != null && billing.isNotEmpty)
                                _AddressTile(
                                  title: 'Billing address',
                                  address: billing,
                                  badge: 'Billing',
                                  onEdit: () => _navigateEdit('address'),
                                  onDelete: () async {
                                    await AddressRepository().deleteAddress('billing');
                                    _loadAddresses();
                                  },
                                )
                              else
                                _EmptyAddressRow(label: 'No billing address set.', onAdd: () => _navigateEdit('address')),
                            ],
                          ],
                        );
                      },
                    ),
                    // ── Shop Settings ──
                    if (_isSeller)
                      FutureBuilder<Shop>(
                        future: _shopFuture,
                        builder: (BuildContext context, AsyncSnapshot<Shop> snapshot) {
                          final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                          final bool hasError = snapshot.hasError;
                          final Shop? shop = snapshot.data;

                          return _SectionCard(
                            title: 'Shop Settings',
                            icon: Icons.storefront_outlined,
                            trailing: _CardAction(
                              label: 'Edit',
                              onTap: () => _navigateToEditShop(shop),
                            ),
                            children: <Widget>[
                              if (isLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: LinearProgressIndicator(minHeight: 3),
                                )
                              else if (hasError)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          'Could not load shop details.',
                                          style: AppThemes.poppins(context,
                                              fontSize: 11,
                                              color: _mutedTextColor(context),
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _loadShop,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              else if (shop != null) ...<Widget>[
                                _ShopMediaRow(
                                  shopName: shop.name,
                                  logoUrl: shop.themeSettings.logo,
                                  bannerUrl: shop.themeSettings.bannerImage,
                                ),
                                const SizedBox(height: 12),
                                _InfoRow(
                                  icon: Icons.store_mall_directory_outlined,
                                  label: 'Shop name',
                                  value: shop.name,
                                ),
                                _InfoRow(
                                  icon: Icons.notes_rounded,
                                  label: 'Description',
                                  value: shop.description.isEmpty
                                      ? 'No description added yet.'
                                      : shop.description,
                                ),
                                if (shop.domain != null && shop.domain!.isNotEmpty)
                                  _InfoRow(
                                    icon: Icons.link_rounded,
                                    label: 'Domain',
                                    value: shop.domain!,
                                  ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  icon: Icons.palette_outlined,
                                  label: 'Theme',
                                  value: shop.theme?.name ?? 'No theme selected',
                                ),
                              ],
                            ],
                          );
                        },
                      ),

                    // ── Payment ──
                   FutureBuilder<PaymentMethods>(
                      future: PaymentRepository().fetchMyPaymentMethods(),
                      builder: (BuildContext context, AsyncSnapshot<PaymentMethods> snapshot) {
                        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                        final PaymentMethods? methods = snapshot.data;

                        return _SectionCard(
                          title: 'Payment Methods',
                          icon: Icons.account_balance_wallet_outlined,
                          trailing: _CardAction(label: 'Edit', onTap: () => _navigateEdit('payment')),
                          children: <Widget>[
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(minHeight: 3),
                              )
                            else ...<Widget>[
                              if (methods?.telebirr != null)
                                Row(
                                  
                                  children: <Widget>[
                                    Expanded(
                                      child: _PaymentTile(
                                        icon: Icons.phone_android_rounded,
                                        title: 'Telebirr',
                                        subtitle: methods!.telebirr!.phoneNumber,
                                        isDefault: false,
                                        onRemove: () async {
                                          try {
                                            await PaymentRepository().deletePaymentMethod('telebirr');
                                            if (mounted) setState(() {});
                                            _showSnack('Telebirr removed.');
                                          } catch (e) {
                                            _showSnack(e.toString());
                                          }
                                        },
                                      ),
                                    ),
                                    _VerificationBadge(isVerified: methods.telebirr!.isVerified),
                                  ],
                                )
                              else
                                _EmptyAddressRow(label: 'No mobile money set.', onAdd: () => _navigateEdit('payment')),
                              if (_isSeller) ...<Widget>[
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                if (methods?.bank != null) ...<Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(child: _InfoRow(icon: Icons.payments_outlined, label: 'Payout account', value: methods!.bank!.providerName)),
                                      _VerificationBadge(isVerified: methods.bank!.isVerified),
                                    ],
                                  ),
                                  _InfoRow(icon: Icons.account_balance_outlined, label: 'Bank account', value: methods.bank!.accountNumber),
                                ] else
                                  _EmptyAddressRow(label: 'No payout bank set.', onAdd: () => _navigateEdit('payment')),
                              ],
                            
                              ],
                            
                          ],
                        );
                      },
                    ),

                    // ── Delivery & Shipping (inline save) ──
                    FutureBuilder<DeliverySettings>(
                      future: _deliveryFuture,
                      builder: (BuildContext context, AsyncSnapshot<DeliverySettings> snapshot) {
                        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                        final DeliverySettings? settings = snapshot.data;

                        return _SectionCard(
                          title: 'Delivery & Shipping',
                          icon: Icons.local_shipping_outlined,
                          trailing: _CardAction(label: 'Edit', onTap: () => _navigateEdit('delivery')),
                          children: <Widget>[
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(minHeight: 3),
                              )
                            else if (settings != null) ...<Widget>[
                              _InfoRow(
                                icon: Icons.map_outlined,
                                label: 'Delivery regions',
                                value: settings.regions.isEmpty ? 'Not set' : settings.regions,
                              ),
                              _InfoRow(
                                icon: Icons.sell_outlined,
                                label: 'Delivery fee',
                                value: 'ETB ${settings.fee.toStringAsFixed(2)}',
                              ),
                              _InfoRow(
                                icon: Icons.shopping_bag_outlined,
                                label: 'Pickup availability',
                                value: settings.pickupAvailable ? 'Enabled' : 'Disabled',
                              ),
                              _InfoRow(
                                icon: Icons.timelapse_rounded,
                                label: 'Processing time',
                                value: settings.processingTime,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    // ── Notifications ──
                    FutureBuilder<NotificationSettings>(
                      future: _notificationFuture,
                      builder: (BuildContext context, AsyncSnapshot<NotificationSettings> snapshot) {
                        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                        final NotificationSettings? settings = snapshot.data;

                        return _SectionCard(
                          title: 'Notifications',
                          icon: Icons.notifications_none_rounded,
                          trailing: _CardAction(label: 'Edit', onTap: () => _navigateEdit('notifications')),
                          children: <Widget>[
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(minHeight: 3),
                              )
                            else if (settings != null) ...<Widget>[
                              _InfoRow(
                                icon: Icons.notifications_active_outlined,
                                label: 'Push notifications',
                                value: settings.pushEnabled ? 'Enabled' : 'Disabled',
                              ),
                              _InfoRow(
                                icon: Icons.mark_email_unread_outlined,
                                label: 'Email notifications',
                                value: settings.emailEnabled ? 'Enabled' : 'Disabled',
                              ),
                            ],
                          ],
                        );
                      },
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
// All original private widgets below
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
    this.logoUrl,
    this.bannerUrl,
  });

  final String name;
  final String email;
  final String phone;
  final String username;
  final String statusLabel;
  final VoidCallback onEdit;
  final String? logoUrl;
  final String? bannerUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool hasLogo = logoUrl != null && logoUrl!.isNotEmpty;
    final bool hasBanner = bannerUrl != null && bannerUrl!.isNotEmpty;
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
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (hasBanner)
                  Image.network(
                    bannerUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                Padding(
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
              ],
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
                    child: ClipOval(
                      child: hasLogo
                          ? Image.network(
                              logoUrl!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                _initials(name),
                                style: AppThemes.poppins(context, fontSize: 19, fontWeight: FontWeight.w700, color: scheme.primary),
                              ),
                            )
                          : Text(
                              _initials(name),
                              style: AppThemes.poppins(context, fontSize: 19, fontWeight: FontWeight.w700, color: scheme.primary),
                            ),
                    ),
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
class _EmptyAddressRow extends StatelessWidget {
  const _EmptyAddressRow({required this.label, required this.onAdd});
  final String label;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.add_location_alt_outlined, color: scheme.onSurface.withOpacity(0.45), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSurface.withOpacity(0.55))),
          ),
          _InlineAction(label: 'Add', onTap: onAdd),
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
  const _ShopMediaRow({required this.shopName, this.logoUrl, this.bannerUrl});
  final String shopName;
  final String? logoUrl;
  final String? bannerUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildLogo(context, scheme),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.primary.withOpacity(0.12)),
            ),
            clipBehavior: Clip.antiAlias,
            child: (bannerUrl != null && bannerUrl!.isNotEmpty)
                ? Image.network(
                    bannerUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => _bannerFallback(context, scheme),
                  )
                : _bannerFallback(context, scheme),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(BuildContext context, ColorScheme scheme) {
    final bool hasLogo = logoUrl != null && logoUrl!.isNotEmpty;
    return ClipOval(
      child: Container(
        height: 56,
        width: 56,
        color: scheme.primary.withOpacity(0.10),
        child: hasLogo
            ? Image.network(
                logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    _initials(shopName),
                    style: AppThemes.poppins(context, fontSize: 16, fontWeight: FontWeight.w700, color: scheme.primary),
                  ),
                ),
              )
            : Center(
                child: Text(
                  _initials(shopName),
                  style: AppThemes.poppins(context, fontSize: 16, fontWeight: FontWeight.w700, color: scheme.primary),
                ),
              ),
      ),
    );
  }

  Widget _bannerFallback(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$shopName banner',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700, color: scheme.primary),
        ),
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'S';
    if (parts.length == 1) {
      final String v = parts.first;
      return v.substring(0, v.length < 2 ? v.length : 2).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.isVerified});
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final Color color = isVerified ? const Color(0xFF1B8F4D) : const Color(0xFFB8860B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(isVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            isVerified ? 'Verified' : 'Pending',
            style: AppThemes.poppins(context, fontSize: 9, fontWeight: FontWeight.w700, color: color),
          ),
        ],
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