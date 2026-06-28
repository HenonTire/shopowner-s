import 'package:flutter/material.dart';
import 'package:shop_manager/pages/add_product_page.dart';
import 'package:shop_manager/pages/home.dart';
import 'package:shop_manager/pages/inventory_page.dart';
import 'package:shop_manager/pages/marketers_page.dart';
import 'package:shop_manager/pages/profile/profile_page.dart';
import 'package:shop_manager/pages/report_page.dart';
import 'package:shop_manager/theme/app_themes.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({
    super.key,
    this.initialIndex = 0,
    this.isDarkMode = false,
    this.onThemeChanged,
  });

  final int initialIndex;
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  static const List<_MainNavItem> _items = <_MainNavItem>[
    _MainNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _MainNavItem(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
    ),
    _MainNavItem(
      label: 'Add',
      icon: Icons.add_outlined,
      activeIcon: Icons.add_rounded,
      isPrimaryAction: true,
    ),
    _MainNavItem(
      label: 'Reports',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
    ),
    _MainNavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  List<Widget> _buildPages() {
    return <Widget>[
      HomePage(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        onOpenMarketers: _openMarketersPage,
      ),
      InventoryPage(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
      const AddProductPage(),
      ReportPage(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
      ProfilePage(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        onOpenMarketers: _openMarketersPage,
      ),
      MarketersPage(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];
  }

  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _openMarketersPage() {
    const int marketersPageIndex = 5;
    if (_currentIndex == marketersPageIndex) {
      return;
    }

    setState(() {
      _currentIndex = marketersPageIndex;
    });
    _pageController.animateToPage(
      marketersPageIndex,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (int index) {
          if (!mounted || index == _currentIndex) {
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
        children: _buildPages(),
      ),
      bottomNavigationBar: _AdvancedBottomNavBar(
        items: _items,
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

class _AdvancedBottomNavBar extends StatelessWidget {
  const _AdvancedBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_MainNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.primary.withOpacity(0.15)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.primary.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List<Widget>.generate(items.length, (int index) {
            final _MainNavItem item = items[index];
            final bool isSelected = index == currentIndex;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: item.isPrimaryAction ? 4 : 8,
                      ),
                      decoration: item.isPrimaryAction
                          ? null
                          : BoxDecoration(
                              color: isSelected
                                  ? scheme.primary.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                      child: item.isPrimaryAction
                          ? _PrimaryNavAction(
                              item: item,
                              isSelected: isSelected,
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  size: 22,
                                  color: isSelected
                                      ? scheme.primary
                                      : scheme.onSurface.withOpacity(0.62),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppThemes.poppins(
                                    context,
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? scheme.primary
                                        : scheme.onSurface.withOpacity(0.62),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PrimaryNavAction extends StatelessWidget {
  const _PrimaryNavAction({
    required this.item,
    required this.isSelected,
  });

  final _MainNavItem item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Transform.translate(
          offset: const Offset(0, -6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary,
              border: Border.all(
                color: scheme.primary.withOpacity(isSelected ? 0.85 : 0.5),
                width: isSelected ? 1.8 : 1.2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: scheme.primary.withOpacity(isSelected ? 0.3 : 0.16),
                  blurRadius: isSelected ? 16 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              item.activeIcon,
              size: 24,
              color: scheme.onPrimary,
            ),
          ),
        ),
        Text(
          item.label,
          style: AppThemes.poppins(
            context,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}

class _MainNavItem {
  const _MainNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.isPrimaryAction = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isPrimaryAction;
}
