import 'package:flutter/material.dart';
import 'package:shop_manager/pages/profile/profile_edit_cards.dart';
import 'package:shop_manager/services/address_repository.dart';
import 'package:shop_manager/services/notification_repository.dart';
import 'package:shop_manager/services/payment_repository.dart';
import 'package:shop_manager/services/auth_service.dart';
import 'package:shop_manager/theme/app_themes.dart';
import 'package:shop_manager/services/delivery_repository.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
    this.section = 'personal',
    this.isDarkMode = false,
    this.onThemeChanged,
  });

  final String section;
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  AuthUser? get _user => AuthSessionStore.user;
  bool get _isSeller => (_user?.role.toLowerCase() ?? 'shop').contains('shop');

  String get _ownerName {
    final String v = (_user?.name ?? '').trim();
    return v.isEmpty ? 'Lovely Shop' : v;
  }

  String get _email {
    final String v = (_user?.email ?? '').trim();
    return v.isEmpty ? 'henon@shikela.com' : v;
  }

  // AuthUser.phone can be null or empty ('') if the backend has no value set.
  String get _phone {
    final String v = (_user?.phone ?? '').trim();
    return v;
  }

  String get _sectionTitle {
    switch (widget.section) {
      case 'personal':
        return 'Personal Info';
      case 'address':
        return 'Address';
      case 'payment':
        return 'Payment Methods';
      case 'delivery':
        return 'Delivery & Shipping';
      case 'notifications':
        return 'Notifications';
      case 'security':
        return 'Security';
      case 'preferences':
        return 'Preferences';
      default:
        return 'Edit';
    }
  }

  void _onSaved() {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$_sectionTitle updated successfully.',
          style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onPrimary),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
 Future<AddressPair>? _addressFuture;

  Future<PaymentMethods>? _paymentFuture;

  Future<DeliverySettings>? _deliveryFuture;
  
  Future<NotificationSettings>? _notificationFuture;

  @override
  void initState() {
    super.initState();
    if (widget.section == 'address') {
      _addressFuture = AddressRepository().fetchMyAddresses();
    }
    if (widget.section == 'payment') {
      _paymentFuture = PaymentRepository().fetchMyPaymentMethods();
    }
    if (widget.section == 'delivery') {
      _deliveryFuture = DeliveryRepository().fetchMyDeliverySettings();
    }
    if (widget.section == 'notifications') {
      _notificationFuture = NotificationRepository().fetchMyNotificationSettings();
    }
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
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.onPrimary.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.onSurface.withOpacity(0.12), width: 0.6),
                      ),
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: scheme.primary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _sectionTitle,
                            style: AppThemes.poppins(context, fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Update your details below.',
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
              const SizedBox(height: 14),
              // ── Content ──
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: <Widget>[
                    if (widget.section == 'personal')
                      PersonalInfoEditCard(
                        initialName: _ownerName,
                        initialEmail: _email,
                        initialPhone: _phone,
                        initialUsername: '@${_ownerName.toLowerCase().replaceAll(' ', '')}',
                        onSave: ({
                          required String name,
                          required String email,
                          required String phone,
                          required String username,
                        }) async {
                          final List<String> parts = name.trim().split(RegExp(r'\s+'));
                          final String firstName = parts.isNotEmpty ? parts.first : '';
                          final String lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

                          await BackendAuthService().updateMyProfile(<String, dynamic>{
                            'first_name': firstName,
                            'last_name': lastName,
                            'email': email,
                            'phone_number': phone,
                          });

                          if (!mounted) return;
                          setState(() {});
                          _onSaved();
                        },
                      ),

                    if (widget.section == 'address')
                      FutureBuilder<AddressPair>(
                        future: _addressFuture,
                        builder: (BuildContext context, AsyncSnapshot<AddressPair> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final AddressPair pair = snapshot.data ?? const AddressPair();
                          return AddressEditCard(
                            initialShipping: pair.shipping ?? '',
                            initialBilling: pair.billing ?? '',
                            onSave: ({
                              required String shipping,
                              required String billing,
                            }) async {
                              await AddressRepository().updateAddress(type: 'shipping', fullAddress: shipping);
                              await AddressRepository().updateAddress(type: 'billing', fullAddress: billing);
                              _onSaved();
                            },
                          );
                        },
                      ),

                   if (widget.section == 'payment')
                      FutureBuilder<PaymentMethods>(
                        future: _paymentFuture,
                        builder: (BuildContext context, AsyncSnapshot<PaymentMethods> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final PaymentMethods methods = snapshot.data ?? const PaymentMethods();
                          return PaymentEditCard(
                            initialMobile: methods.telebirr?.phoneNumber ?? '',
                            initialPayoutBank: methods.bank?.providerName ?? '',
                            initialBankAccount: methods.bank?.accountNumber ?? '',
                            isSeller: _isSeller,
                            onSave: ({
                              required String mobile,
                              required String payoutBank,
                              required String bankAccount,
                            }) async {
                              await PaymentRepository().updateTelebirr(phoneNumber: mobile);
                              if (_isSeller && payoutBank.isNotEmpty && bankAccount.isNotEmpty) {
                                await PaymentRepository().updateBank(
                                  providerName: payoutBank,
                                  accountNumber: bankAccount,
                                );
                              }
                              _onSaved();
                            },
                          );
                        },
                      ),

                    if (widget.section == 'delivery')
                      FutureBuilder<DeliverySettings>(
                        future: _deliveryFuture,
                        builder: (BuildContext context, AsyncSnapshot<DeliverySettings> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final DeliverySettings settings = snapshot.data ??
                              const DeliverySettings(
                                regions: '',
                                fee: 0,
                                pickupAvailable: true,
                                processingTime: '1 business day',
                              );
                          return DeliveryEditCard(
                            initialRegions: settings.regions,
                            initialFee: settings.fee.toStringAsFixed(2),
                            initialPickup: settings.pickupAvailable,
                            initialProcessingTime: settings.processingTime,
                            processingTimes: const <String>[
                              'Same day',
                              '1 business day',
                              '2 business days',
                              '3 business days',
                            ],
                            onSave: ({
                              required String regions,
                              required String fee,
                              required bool pickup,
                              required String processingTime,
                            }) async {
                              await DeliveryRepository().updateDeliverySettings(
                                regions: regions,
                                fee: double.tryParse(fee) ?? 0.0,
                                pickupAvailable: pickup,
                                processingTimeLabel: processingTime,
                              );
                              _onSaved();
                            },
                          );
                        },
                      ),

                    if (widget.section == 'notifications')
                      FutureBuilder<NotificationSettings>(
                        future: _notificationFuture,
                        builder: (BuildContext context, AsyncSnapshot<NotificationSettings> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final NotificationSettings settings =
                              snapshot.data ?? const NotificationSettings(pushEnabled: true, emailEnabled: true);
                          return NotificationsEditCard(
                            initialPush: settings.pushEnabled,
                            initialEmail: settings.emailEnabled,
                            onSave: ({
                              required bool push,
                              required bool email,
                            }) async {
                              await NotificationRepository().updateNotificationSettings(
                                pushEnabled: push,
                                emailEnabled: email,
                              );
                              _onSaved();
                            },
                          );
                        },
                      ),

                    if (widget.section == 'security')
                      SecurityEditCard(
                        onSave: ({
                          required String currentPassword,
                          required String newPassword,
                        }) {
                          // TODO: call your change-password API
                          _onSaved();
                        },
                        onLogoutAll: () {
                          // TODO: invalidate all sessions
                          Navigator.of(context).pop();
                        },
                        onDeleteAccount: () {
                          // TODO: show confirmation dialog then delete
                          showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              title: Text(
                                'Delete account?',
                                style: AppThemes.poppins(context, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              content: Text(
                                'This action is permanent and cannot be undone.',
                                style: AppThemes.poppins(context, fontSize: 12),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Cancel', style: AppThemes.poppins(context, fontSize: 12)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    // TODO: call delete account API
                                  },
                                  child: Text(
                                    'Delete',
                                    style: AppThemes.poppins(
                                      context,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFC62828),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    if (widget.section == 'preferences')
                      PreferencesEditCard(
                        initialLanguage: 'English',
                        initialCurrency: 'ETB',
                        initialDarkMode: widget.isDarkMode,
                        languages: const <String>['English', 'Amharic', 'Oromo'],
                        currencies: const <String>['ETB', 'USD', 'KES'],
                        onThemeChanged: widget.onThemeChanged,
                        onSave: ({
                          required String language,
                          required String currency,
                          required bool darkMode,
                        }) {
                          // TODO: persist preferences
                          _onSaved();
                        },
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