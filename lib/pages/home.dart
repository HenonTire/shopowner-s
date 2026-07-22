import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/dashboard_drawer_models.dart';
import 'package:shop_manager/models/product.dart';
import 'package:shop_manager/models/weekly_report.dart';
import 'package:shop_manager/pages/dashboard_drawer_navigation.dart';
import 'package:shop_manager/pages/earnings_payouts_page.dart';
import 'package:shop_manager/pages/profile/product_detail_page.dart';
import 'package:shop_manager/providers/product_providers.dart';
import 'package:shop_manager/services/auth_service.dart';
import 'package:shop_manager/services/weekly_report_repository.dart';
import 'package:shop_manager/theme/app_themes.dart';
import 'package:shop_manager/widgets/shop_owner_dashboard_drawer.dart';

class HomePage extends ConsumerStatefulWidget {
  HomePage({
    super.key,
    WeeklyReportRepository? reportRepository,
    this.isDarkMode = false,
    this.onThemeChanged,
    this.onOpenMarketers,
  }) : reportRepository = reportRepository ?? BackendWeeklyReportRepository();

  final WeeklyReportRepository reportRepository;
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;
  final VoidCallback? onOpenMarketers;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedPointIndex = 0;
  late Future<WeeklyReport> _weeklyReportFuture;

  @override
  void initState() {
    super.initState();
    _weeklyReportFuture = widget.reportRepository.fetchWeeklyReport();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportRepository != widget.reportRepository) {
      _loadWeeklyReport();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadWeeklyReport() {
    setState(() {
      _weeklyReportFuture = widget.reportRepository.fetchWeeklyReport();
    });
  }

  void _openSideMenu() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _openMarketersPage() {
    widget.onOpenMarketers?.call();
  }

  void _openEarningsPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EarningsPayoutsPage(
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
      shopName: 'Shikela Shop',
      ownerName: 'Henon Manager',
      businessStatus: 'Business Active',
      subscriptionLabel: 'VIP Pro',
      onClose: () => Navigator.of(context).pop(),
      onMenuItemSelected: (DashboardDrawerItemId itemId) {
        Navigator.of(context).pop();
        if (itemId == DashboardDrawerItemId.activityLogs) {
          ref.invalidate(productsProvider);
          _loadWeeklyReport();
        }
        handleDashboardDrawerItemTap(
          context,
          itemId,
          onThemeChanged: widget.onThemeChanged,
          isDarkMode: widget.isDarkMode,
        );
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
      theme.brightness == Brightness.dark ? 0.78 : 0.68,
    );
  }

  int _clampIndex(int value, int length) {
    if (length <= 0) {
      return 0;
    }
    if (value < 0) {
      return 0;
    }
    if (value > length - 1) {
      return length - 1;
    }
    return value;
  }

  String _formatInteger(int value) {
    final String raw = value.abs().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final int indexFromEnd = raw.length - i;
      buffer.write(raw[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return value < 0 ? '-${buffer.toString()}' : buffer.toString();
  }

  String _formatCurrency(double value) {
    final String fixed = value.abs().toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final int whole = int.tryParse(parts.first) ?? 0;
    final String formattedWhole = _formatInteger(whole);
    final String sign = value < 0 ? '-' : '';
    return 'ETB $sign$formattedWhole.${parts.last}';
  }

  String _formatPercent(double value) {
    return '${(value.abs() * 100).toStringAsFixed(1)}%';
  }

  Widget _metricChip(
    BuildContext context, {
    required String label,
    required String value,
    double labelFontSize = 11,
    double valueFontSize = 14,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedTextColor = _mutedTextColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppThemes.poppins(
              context,
              fontSize: labelFontSize,
              color: mutedTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppThemes.poppins(
              context,
              fontSize: valueFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockStatusCard(
    BuildContext context, {
    required String value,
    required String label,
    required Color statusColor,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.primary.withOpacity(0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppThemes.poppins(
                context,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppThemes.poppins(
                context,
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _stockColor(int stock) {
    if (stock <= 0) {
      return Colors.redAccent;
    }
    if (stock <= 5) {
      return Colors.orange.shade700;
    }
    return Colors.green.shade700;
  }

  Widget _productImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 54,
        height: 54,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.08),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
        ),
      ),
    );
  }

  Widget _productItem(BuildContext context, Product product) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedTextColor = _mutedTextColor(context);
    final Color stockColor = _stockColor(product.availableStock);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailPage(product: product),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withOpacity(0.14)),
          ),
          child: Row(
            children: [
              _productImage(product.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemes.poppins(
                        context,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(product.price),
                      style: AppThemes.poppins(
                        context,
                        fontSize: 12,
                        color: mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: stockColor.withOpacity(0.35)),
                ),
                child: Text(
                  '${product.availableStock} stock',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: stockColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productsSection(
    BuildContext context,
    AsyncValue<List<Product>> productsAsync,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedTextColor = _mutedTextColor(context);

    return productsAsync.when(
      loading: () {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withOpacity(0.14)),
          ),
          child: Row(
            children: [
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading products...',
                style: AppThemes.poppins(
                  context,
                  fontSize: 13,
                  color: mutedTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      error: (Object error, StackTrace stackTrace) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withOpacity(0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Failed to load products',
                style: AppThemes.poppins(
                  context,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please check backend connectivity and retry.',
                style: AppThemes.poppins(
                  context,
                  fontSize: 12,
                  color: mutedTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => ref.invalidate(productsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      },
      data: (List<Product> products) {
        if (products.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.primary.withOpacity(0.14)),
            ),
            child: Text(
              'No products found.',
              style: AppThemes.poppins(
                context,
                fontSize: 13,
                color: mutedTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return Column(
          children: products
              .map((Product product) => _productItem(context, product))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _weeklyReportSection(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor = _mutedTextColor(context);
    final Color weeklyCardColor = Color.alphaBlend(
      scheme.primary.withOpacity(isDark ? 0.05 : 0.035),
      scheme.surface,
    );
    final Color weeklyCardBorder = scheme.primary.withOpacity(
      isDark ? 0.14 : 0.12,
    );
    final Color weeklyCardShadow = scheme.primary.withOpacity(
      isDark ? 0.06 : 0.045,
    );

    return FutureBuilder<WeeklyReport>(
      future: _weeklyReportFuture,
      builder: (BuildContext context, AsyncSnapshot<WeeklyReport> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: weeklyCardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: weeklyCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loading weekly analytics...',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 13,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 5),
                const SizedBox(height: 12),
                Text(
                  'Preparing chart points',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 12,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: weeklyCardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: weeklyCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load weekly report',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Check your API connectivity and try again.',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 12,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _loadWeeklyReport,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            ),
          );
        }

        final WeeklyReport? report = snapshot.data;
        if (report == null || report.points.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: weeklyCardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: weeklyCardBorder),
            ),
            child: Text(
              'No weekly data available yet.',
              style: AppThemes.poppins(
                context,
                fontSize: 13,
                color: mutedTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final int safeIndex = _clampIndex(
          _selectedPointIndex,
          report.points.length,
        );
        final WeeklyReportPoint selectedPoint = report.points[safeIndex];
        final bool isPositiveTrend = report.growthRate >= 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: weeklyCardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: weeklyCardBorder),
            boxShadow: [
              BoxShadow(
                color: weeklyCardShadow,
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revenue Trend',
                          style: AppThemes.poppins(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isPositiveTrend ? Colors.green : Colors.red)
                          .withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isPositiveTrend ? Colors.green : Colors.red)
                            .withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPositiveTrend
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 16,
                          color: isPositiveTrend
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatPercent(report.growthRate),
                          style: AppThemes.poppins(
                            context,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isPositiveTrend
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadWeeklyReport,
                    icon: Icon(Icons.refresh_rounded, color: scheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InteractiveWeeklyChart(
                points: report.points,
                selectedIndex: safeIndex,
                onSelectIndex: (int index) {
                  setState(() {
                    _selectedPointIndex = index;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _metricChip(
                      context,
                      label: 'Selected day',
                      labelFontSize: 10,
                      valueFontSize: 10,
                      value:
                          '${selectedPoint.dayLabel} - ${_formatCurrency(selectedPoint.sales)}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricChip(
                      context,
                      label: 'Orders',
                      value: '${selectedPoint.orders}',
                      valueFontSize: 12,
                      labelFontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _metricChip(
                      context,
                      label: 'Week total',
                      labelFontSize: 12,
                      value: _formatCurrency(report.totalSales),
                      valueFontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricChip(
                      context,
                      label: 'Avg. Basket',
                      value: _formatCurrency(report.averageBasket),
                      valueFontSize: 12,
                      labelFontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark
        ? const Color(0xFF172026)
        : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;
    final Color mutedTextColor = _mutedTextColor(context);
    final Color topCardStart = Color.alphaBlend(
      scheme.primary.withOpacity(isDark ? 0.07 : 0.05),
      scheme.surface,
    );
    final Color topCardEnd = Color.alphaBlend(
      scheme.primary.withOpacity(isDark ? 0.03 : 0.02),
      scheme.surface,
    );
    final Color topCardBorder = scheme.primary.withOpacity(
      isDark ? 0.16 : 0.12,
    );
    final Color topCardShadow = scheme.primary.withOpacity(
      isDark ? 0.10 : 0.06,
    );
    final AsyncValue<List<Product>> productsAsync = ref.watch(productsProvider);
    final List<Product> availableProducts = productsAsync.maybeWhen(
      data: (List<Product> products) => products,
      orElse: () => const <Product>[],
    );
    final int totalStockUnits = availableProducts.fold<int>(
      0,
      (int sum, Product product) => sum + product.availableStock,
    );
    final int lowStockCount = availableProducts
        .where((Product product) => product.availableStock > 0 && product.availableStock <= 5)
        .length;
    final int outOfStockCount = availableProducts
        .where((Product product) => product.availableStock <= 0)
        .length;

    return Scaffold(
      key: _scaffoldKey,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: AppThemes.poppins(
                              context,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                    Material(
                      color: scheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _openMarketersPage,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          child: Icon(
                            Icons.campaign_rounded,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        tooltip: 'Open menu',
                        onPressed: _openSideMenu,
                        icon: Icon(Icons.tune_rounded, color: scheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Total Sales card (backend-integrated) ────────────────────
                FutureBuilder<WeeklyReport>(
                  future: _weeklyReportFuture,
                  builder: (BuildContext context, AsyncSnapshot<WeeklyReport> snapshot) {
                    final AuthUser? user = AuthSessionStore.user;
                    final String shopNameRaw = user?.shopName.trim() ?? '';
                    final String shopName = shopNameRaw.isEmpty ? 'Your Shop' : shopNameRaw;

                    final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                    final bool hasError = snapshot.hasError;
                    final WeeklyReport? report = snapshot.data;

                    final double totalSales = report?.totalSales ?? 0;
                    final int totalOrders = report?.totalOrders ?? 0;
                    final double averageBasket = report?.averageBasket ?? 0;
                    final double growthRate = report?.growthRate ?? 0;
                    final bool isPositiveTrend = growthRate >= 0;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [topCardStart, topCardEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: topCardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: topCardShadow,
                            blurRadius: 18,
                            spreadRadius: 0.2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.insights_rounded,
                                  size: 20,
                                  color: scheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Total Sales',
                                style: AppThemes.poppins(
                                  context,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (hasError)
                                IconButton(
                                  tooltip: 'Retry',
                                  onPressed: _loadWeeklyReport,
                                  icon: Icon(Icons.refresh_rounded, color: scheme.primary),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (isLoading)
                            const LinearProgressIndicator(minHeight: 5)
                          else if (hasError)
                            Text(
                              'Could not load sales data.',
                              style: AppThemes.poppins(
                                context,
                                fontSize: 13,
                                color: mutedTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatCurrency(totalSales),
                                        style: AppThemes.poppins(
                                          context,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        shopName,
                                        style: AppThemes.poppins(
                                          context,
                                          fontSize: 13,
                                          color: mutedTextColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 4, 0, 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isPositiveTrend ? Colors.green : Colors.red)
                                          .withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: (isPositiveTrend ? Colors.green : Colors.red)
                                            .withOpacity(0.35),
                                      ),
                                    ),
                                    child: Text(
                                      _formatPercent(growthRate),
                                      style: AppThemes.poppins(
                                        context,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isPositiveTrend
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _metricChip(
                                    context,
                                    label: 'Orders',
                                    value: '$totalOrders',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _metricChip(
                                    context,
                                    label: 'Avg. Basket',
                                    value: _formatCurrency(averageBasket),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                onPressed: _openEarningsPage,
                                icon: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 18,
                                ),
                                label: const Text('Earnings'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                Text(
                  'Stocks Status',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _stockStatusCard(
                      context,
                      value: '$totalStockUnits units',
                      label: 'Total stock',
                      statusColor: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _stockStatusCard(
                      context,
                      value: '$lowStockCount items',
                      label: 'Low stock',
                      statusColor: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    _stockStatusCard(
                      context,
                      value: '$outOfStockCount items',
                      label: 'Stocked out',
                      statusColor: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Weekly Report',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _weeklyReportSection(context),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Products',
                        style: AppThemes.poppins(
                          context,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.invalidate(productsProvider),
                      icon: Icon(Icons.refresh_rounded, color: scheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _productsSection(context, productsAsync),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveWeeklyChart extends StatelessWidget {
  const _InteractiveWeeklyChart({
    required this.points,
    required this.selectedIndex,
    required this.onSelectIndex,
  });

  final List<WeeklyReportPoint> points;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;

  int _closestIndexForPosition(double dx, double width) {
    if (points.length <= 1 || width <= 0) {
      return 0;
    }

    final double clampedDx = dx.clamp(0.0, width).toDouble();
    final double step = width / (points.length - 1);
    final int guess = (clampedDx / step).round();

    if (guess < 0) {
      return 0;
    }
    if (guess > points.length - 1) {
      return points.length - 1;
    }
    return guess;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (BuildContext context, double animationValue, Widget? child) {
        return Column(
          children: [
            SizedBox(
              height: 190,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double width = constraints.maxWidth;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (TapDownDetails details) {
                      onSelectIndex(
                        _closestIndexForPosition(
                          details.localPosition.dx,
                          width,
                        ),
                      );
                    },
                    onHorizontalDragUpdate: (DragUpdateDetails details) {
                      onSelectIndex(
                        _closestIndexForPosition(
                          details.localPosition.dx,
                          width,
                        ),
                      );
                    },
                    child: CustomPaint(
                      size: Size(width, 190),
                      painter: _WeeklyChartPainter(
                        points: points,
                        selectedIndex: selectedIndex,
                        colorScheme: scheme,
                        animationValue: animationValue,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List<Widget>.generate(points.length, (int index) {
                final bool isSelected = index == selectedIndex;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primary.withOpacity(0.15)
                          : scheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? scheme.primary.withOpacity(0.30)
                            : scheme.primary.withOpacity(0.12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        points[index].dayLabel,
                        style: AppThemes.poppins(
                          context,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? scheme.primary
                              : scheme.onSurface.withOpacity(0.72),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _WeeklyChartPainter extends CustomPainter {
  const _WeeklyChartPainter({
    required this.points,
    required this.selectedIndex,
    required this.colorScheme,
    required this.animationValue,
  });

  final List<WeeklyReportPoint> points;
  final int selectedIndex;
  final ColorScheme colorScheme;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final int pointCount = points.length;
    final Paint gridPaint = Paint()
      ..color = colorScheme.onSurface.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const int gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final double y = (size.height * i) / gridLines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double maxSales = points.fold<double>(
      0,
      (double maxValue, WeeklyReportPoint point) =>
          math.max(maxValue, point.sales),
    );
    final double upperBound = maxSales <= 0 ? 1 : maxSales * 1.2;

    final List<Offset> chartPoints = List<Offset>.generate(pointCount, (
      int index,
    ) {
      final double x = pointCount == 1
          ? size.width / 2
          : (index * size.width) / (pointCount - 1);
      final double normalized = (points[index].sales / upperBound)
          .clamp(0.0, 1.0)
          .toDouble();
      final double y =
          size.height - (normalized * size.height * animationValue);
      return Offset(x, y);
    });

    final Path linePath = Path()
      ..moveTo(chartPoints.first.dx, chartPoints.first.dy);
    if (chartPoints.length > 1) {
      for (int i = 0; i < chartPoints.length - 1; i++) {
        final Offset current = chartPoints[i];
        final Offset next = chartPoints[i + 1];
        final Offset midpoint = Offset(
          (current.dx + next.dx) / 2,
          (current.dy + next.dy) / 2,
        );
        linePath.quadraticBezierTo(
          current.dx,
          current.dy,
          midpoint.dx,
          midpoint.dy,
        );
        if (i == chartPoints.length - 2) {
          linePath.quadraticBezierTo(next.dx, next.dy, next.dx, next.dy);
        }
      }
    }

    final Path areaPath = Path.from(linePath)
      ..lineTo(chartPoints.last.dx, size.height)
      ..lineTo(chartPoints.first.dx, size.height)
      ..close();

    final Paint areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colorScheme.primary.withOpacity(0.3),
          colorScheme.primary.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, areaPaint);

    final Paint linePaint = Paint()
      ..shader = LinearGradient(
        colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final int safeIndex = selectedIndex.clamp(0, pointCount - 1).toInt();
    final Offset selectedPoint = chartPoints[safeIndex];

    final Paint guidePaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.3)
      ..strokeWidth = 1.2;
    const double dashHeight = 6;
    const double dashGap = 4;
    for (double y = 0; y < size.height; y += dashHeight + dashGap) {
      canvas.drawLine(
        Offset(selectedPoint.dx, y),
        Offset(selectedPoint.dx, math.min(y + dashHeight, size.height)),
        guidePaint,
      );
    }

    for (int i = 0; i < chartPoints.length; i++) {
      final bool isSelected = i == safeIndex;
      final Offset point = chartPoints[i];

      if (isSelected) {
        canvas.drawCircle(
          point,
          10,
          Paint()..color = colorScheme.primary.withOpacity(0.2),
        );
      }

      canvas.drawCircle(
        point,
        isSelected ? 5.4 : 3.8,
        Paint()
          ..color = isSelected
              ? colorScheme.primary
              : colorScheme.primary.withOpacity(0.72),
      );

      canvas.drawCircle(
        point,
        isSelected ? 2.2 : 1.6,
        Paint()..color = colorScheme.onPrimary,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.animationValue != animationValue;
  }
}