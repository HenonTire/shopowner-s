import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/dashboard_drawer_models.dart';
import 'package:shop_manager/models/product.dart';
import 'package:shop_manager/models/weekly_report.dart';
import 'package:shop_manager/pages/dashboard_drawer_navigation.dart';
import 'package:shop_manager/providers/product_providers.dart';
import 'package:shop_manager/providers/weekly_report_providers.dart';
import 'package:shop_manager/theme/app_themes.dart';
import 'package:shop_manager/widgets/shop_owner_dashboard_drawer.dart';

enum _ReportRange {
  daily,
  weekly,
  monthly,
  yearly,
}

extension _ReportRangeLabel on _ReportRange {
  String get label {
    switch (this) {
      case _ReportRange.daily:
        return 'Daily';
      case _ReportRange.weekly:
        return 'Weekly';
      case _ReportRange.monthly:
        return 'Monthly';
      case _ReportRange.yearly:
        return 'Yearly';
    }
  }

  String get periodHeader {
    switch (this) {
      case _ReportRange.daily:
        return 'Day';
      case _ReportRange.weekly:
        return 'Week';
      case _ReportRange.monthly:
        return 'Month';
      case _ReportRange.yearly:
        return 'Year';
    }
  }
}

class _SalesReportRow {
  const _SalesReportRow({
    required this.period,
    required this.sales,
    required this.orders,
  });

  final String period;
  final double sales;
  final int orders;

  double get averageBasket => orders == 0 ? 0 : sales / orders;
}

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({
    super.key,
    this.isDarkMode = false,
    this.onThemeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  static const List<String> _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  _ReportRange _selectedRange = _ReportRange.daily;

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
    final double percent = value * 100;
    final String sign = percent > 0 ? '+' : percent < 0 ? '-' : '';
    return '$sign${percent.abs().toStringAsFixed(1)}%';
  }

  Future<void> _refresh() async {
    ref.invalidate(weeklyReportProvider);
    ref.invalidate(productsProvider);
    await Future.wait<void>(<Future<void>>[
      ref.read(weeklyReportProvider.future).then((_) {}),
      ref.read(productsProvider.future).then((_) {}),
    ]);
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
        handleDashboardDrawerItemTap(context, itemId);
      },
      onQuickActionSelected: (DashboardQuickActionId quickActionId) {
        Navigator.of(context).pop();
        handleDashboardQuickActionTap(context, quickActionId);
      },
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: scheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.poppins(
                    context,
                    fontSize: 10,
                    color: scheme.onSurface.withOpacity(0.66),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.poppins(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required Widget child}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withOpacity(0.14)),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppThemes.poppins(
        context,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  DateTime _monthOffset(DateTime base, int offset) {
    final int monthIndex = (base.month - 1) + offset;
    final int year = base.year + (monthIndex ~/ 12);
    final int month = (monthIndex % 12 + 12) % 12 + 1;
    return DateTime(year, month, 1);
  }

  double _trendFactor({
    required int index,
    required int total,
    required double growthRate,
  }) {
    if (total <= 1) {
      return 1;
    }
    final double midpoint = (total - 1) / 2;
    final double normalized = (index - midpoint) / midpoint;
    return (1 + (normalized * growthRate)).clamp(0.55, 1.65).toDouble();
  }

  List<_SalesReportRow> _dailyRows(WeeklyReport report) {
    return report.points
        .map(
          (WeeklyReportPoint point) => _SalesReportRow(
            period: point.dayLabel,
            sales: point.sales,
            orders: point.orders,
          ),
        )
        .toList(growable: false);
  }

  List<_SalesReportRow> _weeklyRows(WeeklyReport report) {
    const int count = 8;
    final DateTime now = DateTime.now();
    final double baseSales = report.totalSales;
    final int baseOrders = report.totalOrders;

    return List<_SalesReportRow>.generate(count, (int i) {
      final DateTime weekDate = now.subtract(Duration(days: (count - 1 - i) * 7));
      final double factor = _trendFactor(index: i, total: count, growthRate: report.growthRate);
      return _SalesReportRow(
        period: 'Wk of ${weekDate.day}/${weekDate.month}',
        sales: baseSales * factor,
        orders: (baseOrders * factor).round(),
      );
    });
  }

  List<_SalesReportRow> _monthlyRows(WeeklyReport report) {
    const int count = 12;
    final DateTime now = DateTime.now();
    final double baseMonthlySales = report.totalSales * 4.3;
    final int baseMonthlyOrders = (report.totalOrders * 4.3).round();

    return List<_SalesReportRow>.generate(count, (int i) {
      final DateTime monthDate = _monthOffset(now, -(count - 1 - i));
      final double factor = _trendFactor(index: i, total: count, growthRate: report.growthRate * 1.4);
      return _SalesReportRow(
        period: '${_monthNames[monthDate.month - 1]} ${monthDate.year}',
        sales: baseMonthlySales * factor,
        orders: (baseMonthlyOrders * factor).round(),
      );
    });
  }

  List<_SalesReportRow> _yearlyRows(WeeklyReport report) {
    const int count = 5;
    final DateTime now = DateTime.now();
    final double baseYearSales = report.totalSales * 52;
    final int baseYearOrders = report.totalOrders * 52;

    return List<_SalesReportRow>.generate(count, (int i) {
      final int year = now.year - (count - 1 - i);
      final double factor = _trendFactor(index: i, total: count, growthRate: report.growthRate * 2);
      return _SalesReportRow(
        period: '$year',
        sales: baseYearSales * factor,
        orders: (baseYearOrders * factor).round(),
      );
    });
  }

  List<_SalesReportRow> _rowsForRange(WeeklyReport report) {
    switch (_selectedRange) {
      case _ReportRange.daily:
        return _dailyRows(report);
      case _ReportRange.weekly:
        return _weeklyRows(report);
      case _ReportRange.monthly:
        return _monthlyRows(report);
      case _ReportRange.yearly:
        return _yearlyRows(report);
    }
  }

  Widget _rangeSelector(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    const double spacing = 6;
    return Row(
      children: List<Widget>.generate(_ReportRange.values.length, (int index) {
        final _ReportRange range = _ReportRange.values[index];
        final bool selected = _selectedRange == range;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == _ReportRange.values.length - 1 ? 0 : spacing),
            child: ChoiceChip(
              label: Center(
                child: Text(
                  range.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.poppins(
                    context,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected ? scheme.onPrimary : scheme.onSurface.withOpacity(0.75),
                  ),
                ),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              selected: selected,
              onSelected: (_) {
                if (!selected) {
                  setState(() {
                    _selectedRange = range;
                  });
                }
              },
              selectedColor: scheme.primary,
              backgroundColor: scheme.surface,
              side: BorderSide(color: scheme.primary.withOpacity(0.24)),
            ),
          ),
        );
      }),
    );
  }

  Widget _salesTable(BuildContext context, List<_SalesReportRow> rows) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withOpacity(0.14)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 42,
          dataRowMinHeight: 46,
          dataRowMaxHeight: 56,
          headingRowColor: WidgetStatePropertyAll(scheme.primary.withOpacity(0.08)),
          columns: <DataColumn>[
            DataColumn(
              label: Text(
                _selectedRange.periodHeader,
                style: AppThemes.poppins(
                  context,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Orders',
                style: AppThemes.poppins(
                  context,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Sales',
                style: AppThemes.poppins(
                  context,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Avg Basket',
                style: AppThemes.poppins(
                  context,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          rows: rows
              .map(
                (_SalesReportRow row) => DataRow(
                  cells: <DataCell>[
                    DataCell(
                      SizedBox(
                        width: 96,
                        child: Text(
                          row.period,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppThemes.poppins(
                            context,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatInteger(row.orders),
                        style: AppThemes.poppins(
                          context,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatCurrency(row.sales),
                        style: AppThemes.poppins(
                          context,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatCurrency(row.averageBasket),
                        style: AppThemes.poppins(
                          context,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: _sectionCard(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off_rounded, size: 34, color: scheme.primary),
            const SizedBox(height: 8),
            Text(
              'Could not load reports.',
              style: AppThemes.poppins(
                context,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;
    final AsyncValue<WeeklyReport> weeklyAsync = ref.watch(weeklyReportProvider);
    final AsyncValue<List<Product>> productsAsync = ref.watch(productsProvider);

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
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: weeklyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stackTrace) => _errorView(context),
              data: (WeeklyReport report) {
                return productsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (Object error, StackTrace stackTrace) => _errorView(context),
                  data: (List<Product> products) {
                    final double stockValue =
                        products.fold<double>(0, (double sum, Product p) => sum + (p.price * p.stock));
                    final List<_SalesReportRow> tableRows = _rowsForRange(report);

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      'Reports',
                                      style: AppThemes.poppins(
                                        context,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _refresh,
                                    icon: Icon(Icons.refresh_rounded, color: scheme.primary),
                                  ),
                                  Builder(
                                    builder: (BuildContext innerContext) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: scheme.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: IconButton(
                                          tooltip: 'Open menu',
                                          onPressed: () => Scaffold.of(innerContext).openEndDrawer(),
                                          icon: Icon(Icons.tune_rounded, color: scheme.primary),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                'Sales report table by day, week, month, and year.',
                                style: AppThemes.poppins(
                                  context,
                                  fontSize: 13,
                                  color: scheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 18),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 2.25,
                                children: <Widget>[
                                  _summaryCard(
                                    context,
                                    label: 'Total sales',
                                    value: _formatCurrency(report.totalSales),
                                    icon: Icons.payments_rounded,
                                  ),
                                  _summaryCard(
                                    context,
                                    label: 'Total orders',
                                    value: _formatInteger(report.totalOrders),
                                    icon: Icons.receipt_long_rounded,
                                  ),
                                  _summaryCard(
                                    context,
                                    label: 'Growth rate',
                                    value: _formatPercent(report.growthRate),
                                    icon: Icons.trending_up_rounded,
                                  ),
                                  _summaryCard(
                                    context,
                                    label: 'Inventory value',
                                    value: _formatCurrency(stockValue),
                                    icon: Icons.inventory_rounded,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _sectionCard(
                                context,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _sectionTitle(context, 'Sales Report Table'),
                                    const SizedBox(height: 1),
                                    _rangeSelector(context),
                                    const SizedBox(height: 18),
                                    Text(
                                      'Daily rows use direct report points. Weekly, monthly, and yearly rows are trend projections.',
                                      style: AppThemes.poppins(
                                        context,
                                        fontSize: 10,
                                        color: scheme.onSurface.withOpacity(0.65),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    _salesTable(context, tableRows),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
