import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/dashboard_drawer_models.dart';
import 'package:shop_manager/providers/dashboard_drawer_provider.dart';
import 'package:shop_manager/theme/app_themes.dart';

class ShopOwnerDashboardDrawer extends ConsumerWidget {
  const ShopOwnerDashboardDrawer({
    super.key,
    required this.onMenuItemSelected,
    required this.onQuickActionSelected,
    required this.onClose,
    this.isDarkMode = false,
    this.onThemeChanged,
    this.shopName = 'Shikela Shop',
    this.ownerName = 'Shop Owner',
    this.businessStatus = 'Business Active',
    this.subscriptionLabel = 'VIP Pro',
  });

  final ValueChanged<DashboardDrawerItemId> onMenuItemSelected;
  final ValueChanged<DashboardQuickActionId> onQuickActionSelected;
  final VoidCallback onClose;
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;
  final String shopName;
  final String ownerName;
  final String businessStatus;
  final String subscriptionLabel;

  static final List<DashboardDrawerSectionData> _sections = <DashboardDrawerSectionData>[
    DashboardDrawerSectionData(
      id: DashboardDrawerSectionId.businessManagement,
      title: 'Main',
      items: const <DashboardDrawerItemData>[
        DashboardDrawerItemData(id: DashboardDrawerItemId.dashboard, label: 'Dashboard', icon: Icons.dashboard_rounded),
        DashboardDrawerItemData(id: DashboardDrawerItemId.products, label: 'Products', icon: Icons.inventory_2_rounded),
        DashboardDrawerItemData(id: DashboardDrawerItemId.orders, label: 'Orders', icon: Icons.receipt_long_rounded),
        DashboardDrawerItemData(id: DashboardDrawerItemId.customers, label: 'Customers', icon: Icons.groups_rounded),
        DashboardDrawerItemData(id: DashboardDrawerItemId.shop, label: 'Shop', icon: Icons.storefront_rounded),
        DashboardDrawerItemData(id: DashboardDrawerItemId.analytics, label: 'Analytics', icon: Icons.insights_rounded),
        DashboardDrawerItemData(id: DashboardDrawerItemId.profileSettings, label: 'Profile', icon: Icons.manage_accounts_rounded),
      ],
    ),
    DashboardDrawerSectionData(
      id: DashboardDrawerSectionId.settingsAndAccount,
      title: 'Settings',
      items: const <DashboardDrawerItemData>[
        DashboardDrawerItemData(id: DashboardDrawerItemId.settings, label: 'Settings', icon: Icons.settings_rounded),
        DashboardDrawerItemData(id: DashboardDrawerItemId.paymentMethods, label: 'Payment Methods', icon: Icons.credit_card_rounded),
        DashboardDrawerItemData(id: DashboardDrawerItemId.language, label: 'Language', icon: Icons.language_rounded),
        DashboardDrawerItemData(id: DashboardDrawerItemId.darkMode, label: 'Dark Mode', icon: Icons.dark_mode_rounded, supportsPin: false),
        DashboardDrawerItemData(id: DashboardDrawerItemId.security, label: 'Security', icon: Icons.security_rounded),
        DashboardDrawerItemData(id: DashboardDrawerItemId.logout, label: 'Logout', icon: Icons.logout_rounded, supportsPin: false, isDestructive: true),
      ],
    ),
  ];

  static const List<DashboardQuickActionData> _quickActions = <DashboardQuickActionData>[
    DashboardQuickActionData(id: DashboardQuickActionId.addProduct, label: 'Add Product', icon: Icons.add_box_rounded),
    DashboardQuickActionData(id: DashboardQuickActionId.startCampaign, label: 'Start Campaign', icon: Icons.rocket_launch_rounded),
    DashboardQuickActionData(id: DashboardQuickActionId.addSupplier, label: 'Add Supplier', icon: Icons.storefront_rounded),
  ];

  static final Map<DashboardDrawerItemId, DashboardDrawerItemData> _itemById =
      <DashboardDrawerItemId, DashboardDrawerItemData>{
    for (final DashboardDrawerSectionData section in _sections)
      for (final DashboardDrawerItemData item in section.items) item.id: item,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final DashboardDrawerState state = ref.watch(dashboardDrawerProvider);
    final DashboardDrawerController controller = ref.read(dashboardDrawerProvider.notifier);

    final List<DashboardDrawerItemData> pinnedItems = state.pinnedItems
        .map((DashboardDrawerItemId id) => _itemById[id])
        .whereType<DashboardDrawerItemData>()
        .toList(growable: false);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: math.min(MediaQuery.of(context).size.width * 0.9, 380),
        margin: const EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Drawer(
            elevation: 12,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(color: scheme.primary.withOpacity(0.12)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color.alphaBlend(
                      scheme.primary.withOpacity(isDark ? 0.08 : 0.05),
                      scheme.surface,
                    ),
                    scheme.surface,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: <Widget>[
                    _HeaderCard(
                      onClose: onClose,
                      shopName: shopName,
                      ownerName: ownerName,
                      businessStatus: businessStatus,
                      subscriptionLabel: subscriptionLabel,
                    ),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                        children: <Widget>[
                          if (pinnedItems.isNotEmpty)
                            _SectionCard(
                              title: 'Pinned Shortcuts',
                              isExpanded: state.expandedSections.contains(DashboardDrawerSectionId.pinnedShortcuts),
                              onToggle: () => controller.toggleSection(DashboardDrawerSectionId.pinnedShortcuts),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: pinnedItems
                                    .map(
                                      (DashboardDrawerItemData item) => _PinnedShortcutChip(
                                        item: item,
                                        isSelected: state.selectedItem == item.id,
                                        badgeCount: state.badges[item.id] ?? 0,
                                        onTap: () {
                                          controller.selectItem(item.id);
                                          onMenuItemSelected(item.id);
                                        },
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                          if (pinnedItems.isNotEmpty) const SizedBox(height: 10),
                          _QuickActionsSection(
                            actions: _quickActions,
                            onTap: onQuickActionSelected,
                          ),
                          const SizedBox(height: 12),
                          for (int i = 0; i < _sections.length; i++) ...<Widget>[
                            _SectionCard(
                              title: _sections[i].title,
                              isExpanded: state.expandedSections.contains(_sections[i].id),
                              onToggle: () => controller.toggleSection(_sections[i].id),
                              child: Column(
                                children: _sections[i].items
                                    .map(
                                      (DashboardDrawerItemData item) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: _MenuItemTile(
                                          item: item,
                                          isSelected: state.selectedItem == item.id,
                                          badgeCount: state.badges[item.id] ?? 0,
                                          isPinned: state.pinnedItems.contains(item.id),
                                          onPinTap: item.supportsPin
                                              ? () => controller.togglePin(item.id)
                                              : null,
                                          trailing: item.id == DashboardDrawerItemId.darkMode
                                              ? Switch.adaptive(
                                                  value: isDarkMode,
                                                  onChanged: onThemeChanged == null
                                                      ? null
                                                      : (bool value) {
                                                          onThemeChanged!(value);
                                                        },
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                )
                                              : null,
                                          onTap: () {
                                            if (item.id == DashboardDrawerItemId.darkMode) {
                                              if (onThemeChanged != null) {
                                                onThemeChanged!(!isDarkMode);
                                              }
                                              return;
                                            }
                                            controller.selectItem(item.id);
                                            onMenuItemSelected(item.id);
                                          },
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                            if (i < _sections.length - 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                  color: scheme.primary.withOpacity(0.15),
                                  height: 1,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.onClose,
    required this.shopName,
    required this.ownerName,
    required this.businessStatus,
    required this.subscriptionLabel,
  });

  final VoidCallback onClose;
  final String shopName;
  final String ownerName;
  final String businessStatus;
  final String subscriptionLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.primary.withOpacity(0.15)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              scheme.primary.withOpacity(0.14),
              scheme.primary.withOpacity(0.04),
            ],
          ),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primary.withOpacity(0.16),
                  child: Icon(Icons.store_rounded, color: scheme.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppThemes.poppins(
                          context,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ownerName,
                        style: AppThemes.poppins(
                          context,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                _MiniBadge(
                  label: businessStatus,
                  color: const Color(0xFF1B8F4D),
                  icon: Icons.verified_rounded,
                ),
                const SizedBox(width: 8),
                _MiniBadge(
                  label: subscriptionLabel,
                  color: const Color(0xFF1565C0),
                  icon: Icons.workspace_premium_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppThemes.poppins(
              context,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(isExpanded ? 0.06 : 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: AppThemes.poppins(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 220),
                    turns: isExpanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: child,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 260),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.item,
    required this.isSelected,
    required this.badgeCount,
    required this.isPinned,
    required this.onTap,
    this.onPinTap,
    this.trailing,
  });

  final DashboardDrawerItemData item;
  final bool isSelected;
  final int badgeCount;
  final bool isPinned;
  final VoidCallback onTap;
  final VoidCallback? onPinTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color accent = item.isDestructive ? const Color(0xFFC62828) : scheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accent.withOpacity(0.14) : scheme.surface.withOpacity(0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accent.withOpacity(0.3) : scheme.primary.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(item.icon, size: 18, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.poppins(
                    context,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: item.isDestructive ? const Color(0xFFC62828) : null,
                  ),
                ),
              ),
              if (badgeCount > 0) ...<Widget>[
                _NumberBadge(count: badgeCount),
                const SizedBox(width: 6),
              ],
              if (trailing != null) trailing!,
              if (trailing == null && onPinTap != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onPinTap,
                  icon: Icon(
                    isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    size: 18,
                    color: isPinned ? accent : scheme.onSurface.withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppThemes.poppins(
          context,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimary,
        ),
      ),
    );
  }
}

class _PinnedShortcutChip extends StatelessWidget {
  const _PinnedShortcutChip({
    required this.item,
    required this.badgeCount,
    required this.isSelected,
    required this.onTap,
  });

  final DashboardDrawerItemData item;
  final int badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary.withOpacity(0.14) : scheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.primary.withOpacity(0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(item.icon, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: AppThemes.poppins(
                  context,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (badgeCount > 0) ...<Widget>[
                const SizedBox(width: 6),
                _NumberBadge(count: badgeCount),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.actions,
    required this.onTap,
  });

  final List<DashboardQuickActionData> actions;
  final ValueChanged<DashboardQuickActionId> onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withOpacity(0.16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary.withOpacity(0.1),
            scheme.primary.withOpacity(0.04),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Quick Actions',
            style: AppThemes.poppins(
              context,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: actions.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.8,
            ),
            itemBuilder: (BuildContext context, int index) {
              final DashboardQuickActionData action = actions[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTap(action.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: scheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.primary.withOpacity(0.18)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(action.icon, size: 17, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            action.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemes.poppins(
                              context,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
