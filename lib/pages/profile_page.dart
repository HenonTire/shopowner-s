import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/dashboard_drawer_models.dart';
import 'package:shop_manager/models/marketer_models.dart';
import 'package:shop_manager/pages/dashboard_drawer_navigation.dart';
import 'package:shop_manager/pages/marketer_chats_page.dart';
import 'package:shop_manager/pages/marketer_contracts_page.dart';
import 'package:shop_manager/pages/marketer_detail_page.dart';
import 'package:shop_manager/providers/marketer_providers.dart';
import 'package:shop_manager/theme/app_themes.dart';
import 'package:shop_manager/widgets/shop_owner_dashboard_drawer.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({
    super.key,
    this.isDarkMode = false,
    this.onThemeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  void _openMarketerDetail(BuildContext context, MarketerSummary marketer) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarketerDetailPage(
          marketerId: marketer.id,
          name: marketer.name,
          specialization: marketer.specialization,
          tagline: marketer.tagline,
          rating: marketer.rating,
          totalOrders: marketer.totalOrders,
          conversionRate: marketer.conversionRate,
          revenueGenerated: marketer.revenueGenerated,
          avatarColor: marketer.avatarColor,
          badgeLabel: marketer.badgeLabel,
        ),
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    return ShopOwnerDashboardDrawer(
      isDarkMode: isDarkMode,
      onThemeChanged: onThemeChanged,
      shopName: 'Shikela Shop',
      ownerName: 'Henon Manager',
      businessStatus: 'Business Active',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MarketerOverviewData> overviewAsync =
        ref.watch(marketerOverviewProvider);
    final List<MarketerSummary> topPerformers =
        overviewAsync.asData?.value.topPerformers ?? const <MarketerSummary>[];
    final List<MarketerSummary> allMarketers =
        overviewAsync.asData?.value.allMarketers ?? const <MarketerSummary>[];
    final int unreadChats = overviewAsync.asData?.value.unreadChats ?? 0;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;

    return Scaffold(
      backgroundColor: bgBottom,
      endDrawer: _buildSideMenu(context),
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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Marketers',
                              style: AppThemes.poppins(
                                context,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const MarketerContractsPage(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              side: BorderSide(color: scheme.onSurface.withOpacity(0.18), width: 0.8),
                            ),
                            child: Text(
                              'Your Contracts',
                              style: AppThemes.poppins(
                                context,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                  color: scheme.onPrimary.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: scheme.onSurface.withOpacity(0.12),
                                    width: 0.6,
                                  ),
                                ),
                                child: IconButton(
                                  tooltip: 'Marketer chats',
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const MarketerChatsPage(),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.chat_bubble_rounded, color: scheme.primary),
                                ),
                              ),
                              if (unreadChats > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC62828),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: scheme.surface, width: 1.5),
                                    ),
                                    child: Text(
                                      unreadChats > 99 ? '99+' : '$unreadChats',
                                      style: AppThemes.poppins(
                                        context,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                    
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              decoration: InputDecoration(
                                fillColor: scheme.onPrimary.withOpacity(0.03),
                                hintText: 'Search marketers',
                                hintStyle: AppThemes.poppins(
                                  context,
                                  fontSize: 12,
                                  color: scheme.primary.withOpacity(0.5),
                                ),
                                prefixIcon: const Icon(Icons.search_rounded),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: scheme.onSurface.withOpacity(0.12),
                                    width: 0.6,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: scheme.onSurface.withOpacity(0.12),
                                    width: 0.6,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: scheme.onSurface.withOpacity(0.2),
                                    width: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: scheme.onSurface.withOpacity(0.12),
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: <Widget>[
                                    const Icon(Icons.tune_rounded, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Filter',
                                      style: AppThemes.poppins(
                                        context,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 20),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Top Performing Marketers',
                    subtitle: 'The highest converting marketers this month',
                  ),
                ),
                
              ),
            
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.separated(
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      final MarketerSummary marketer = topPerformers[index];
                      return _TopPerformerCard(
                        marketer: marketer,
                        onTap: () => _openMarketerDetail(context, marketer),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: topPerformers.length,
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 20),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'All Marketers',
                    subtitle: 'Compare by orders, conversion, and generated revenue',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      if (index.isOdd) {
                        return const SizedBox(height: 12);
                      }
                      final int marketerIndex = index ~/ 2;
                      final MarketerSummary marketer = allMarketers[marketerIndex];
                      return _AllMarketerCard(
                        marketer: marketer,
                        onViewProfile: () => _openMarketerDetail(context, marketer),
                        onHire: () => _openMarketerDetail(context, marketer),
                      );
                    },
                    childCount: allMarketers.isEmpty
                        ? 0
                        : (allMarketers.length * 2) - 1,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: AppThemes.poppins(
            context,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppThemes.poppins(
            context,
            fontSize: 12,
            color: scheme.onSurface.withOpacity(0.62),
          ),
        ),
      ],
    );
  }
}

class _TopPerformerCard extends StatelessWidget {
  const _TopPerformerCard({
    required this.marketer,
    required this.onTap,
  });

  final MarketerSummary marketer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          Row(
            children: <Widget>[
              _AvatarChip(marketer: marketer, radius: 22),
              const Spacer(),
              _PerformanceBadge(label: marketer.badgeLabel),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            marketer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.poppins(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            marketer.specialization,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.poppins(
              context,
              fontSize: 12,
              color: scheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(Icons.star_rounded, color: Color(0xFFFBC02D), size: 18),
              const SizedBox(width: 4),
              Text(
                marketer.rating.toStringAsFixed(1),
                style: AppThemes.poppins(
                  context,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${marketer.revenueGenerated} generated',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.poppins(
              context,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B8F4D),
            ),
          ),
          Text(
            'Revenue generated',
            style: AppThemes.poppins(
              context,
              fontSize: 11,
              color: scheme.onSurface.withOpacity(0.56),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _AllMarketerCard extends StatelessWidget {
  const _AllMarketerCard({
    required this.marketer,
    required this.onViewProfile,
    required this.onHire,
  });

  final MarketerSummary marketer;
  final VoidCallback onViewProfile;
  final VoidCallback onHire;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool strongPerformance = marketer.conversionRate >= 4.0;
    final Color conversionColor =
        strongPerformance ? const Color(0xFF1B8F4D) : const Color(0xFFC62828);
    const String viewProfileLabel = 'View Profile';
    const String hireLabel = 'Hire Now';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AvatarChip(marketer: marketer),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      marketer.name,
                      style: AppThemes.poppins(
                        context,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      marketer.tagline,
                      style: AppThemes.poppins(
                        context,
                        fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.62),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBC02D),
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          marketer.rating.toStringAsFixed(1),
                          style: AppThemes.poppins(
                            context,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricBlock(
                  label: 'Orders',
                  value: marketer.totalOrders.toString(),
                  valueColor: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBlock(
                  label: 'Conversion',
                  value: '${marketer.conversionRate.toStringAsFixed(1)}%',
                  valueColor: conversionColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBlock(
                  label: 'Revenue',
                  value: marketer.revenueGenerated,
                  valueColor: const Color(0xFF1B8F4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewProfile,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: scheme.onPrimary.withOpacity(0.03),
                    side: BorderSide(
                      color: scheme.onSurface.withOpacity(0.12),
                      width: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    viewProfileLabel,
                    style: AppThemes.poppins(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onHire,
                  style: OutlinedButton.styleFrom(
                    
                    backgroundColor: scheme.onPrimary,
                    side: BorderSide(
                      color: scheme.onSurface.withOpacity(0.16),
                      width: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    hireLabel,
                    style: AppThemes.poppins(
                      context,
                      fontSize: 12,
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.poppins(
              context,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppThemes.poppins(
              context,
              fontSize: 10,
              color: scheme.onSurface.withOpacity(0.56),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceBadge extends StatelessWidget {
  const _PerformanceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1B8F4D).withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppThemes.poppins(
          context,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1B8F4D),
        ),
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  const _AvatarChip({
    required this.marketer,
    this.radius = 20,
  });

  final MarketerSummary marketer;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: marketer.avatarColor.withOpacity(0.18),
      child: Text(
        marketer.initials,
        style: AppThemes.poppins(
          context,
          fontSize: radius * 0.45,
          fontWeight: FontWeight.w700,
          color: marketer.avatarColor,
        ),
      ),
    );
  }
}
