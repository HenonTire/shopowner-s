import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/earnings.dart';
import 'package:shop_manager/providers/earnings_providers.dart';
import 'package:shop_manager/services/earnings_repository.dart';
import 'package:shop_manager/theme/app_themes.dart';

class EarningsPayoutsPage extends ConsumerStatefulWidget {
  const EarningsPayoutsPage({
    super.key,
    this.isDarkMode = false,
    this.onThemeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  @override
  ConsumerState<EarningsPayoutsPage> createState() =>
      _EarningsPayoutsPageState();
}

class _EarningsPayoutsPageState extends ConsumerState<EarningsPayoutsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  EarningStatus? _statusFilter;
  DateTimeRange? _dateRange;
  String _ordering = '-date';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(earningsDashboardProvider);
    ref.invalidate(payoutsProvider);
    await Future.wait<void>(<Future<void>>[
      ref.read(earningsDashboardProvider.future).then((_) {}),
      ref.read(payoutsProvider.future).then((_) {}),
    ]);
  }

  void _applyQuery({int? page}) {
    final EarningsQuery current = ref.read(earningsQueryProvider);
    ref.read(earningsQueryProvider.notifier).state = EarningsQuery(
      page: page ?? 1,
      pageSize: current.pageSize,
      search: _searchController.text,
      status: _statusFilter,
      from: _dateRange?.start,
      to: _dateRange?.end,
      ordering: _ordering,
    );
  }

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _dateRange = selected;
    });
    _applyQuery();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _statusFilter = null;
      _dateRange = null;
      _ordering = '-date';
    });
    _applyQuery();
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
    final String sign = value < 0 ? '-' : '';
    return 'ETB $sign${_formatInteger(whole)}.${parts.last}';
  }

  String _formatDate(DateTime value) {
    const List<String> months = <String>[
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
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  Color _muted(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.colorScheme.onSurface.withOpacity(
      theme.brightness == Brightness.dark ? 0.76 : 0.64,
    );
  }

  Color _statusColor(Object status) {
    if (status == EarningStatus.available ||
        status == PayoutStatus.paid ||
        status == PayoutStatus.approved) {
      return const Color(0xFF1B8F4D);
    }
    if (status == EarningStatus.pending ||
        status == PayoutStatus.pending ||
        status == PayoutStatus.processing) {
      return const Color(0xFFB7791F);
    }
    if (status == EarningStatus.withdrawn) {
      return const Color(0xFF2563EB);
    }
    return const Color(0xFFB42318);
  }

  Widget _statusBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppThemes.poppins(
          context,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, {required Widget child}) {
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

  Widget _summaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.poppins(
                    context,
                    fontSize: 10,
                    color: _muted(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
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

  Widget _loadingView() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _errorView(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _panel(
          context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.cloud_off_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                'Could not load payment data.',
                textAlign: TextAlign.center,
                style: AppThemes.poppins(
                  context,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppThemes.poppins(
                  context,
                  fontSize: 11,
                  color: _muted(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _filters(BuildContext context, PaginatedEarnings history) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final bool hasActiveFilters = _statusFilter != null ||
      _dateRange != null ||
      _searchController.text.isNotEmpty ||
      _ordering != '-date';

  return _panel(
    context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ── Search bar ──────────────────────────────────────────
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _applyQuery(),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search orders or customers',
            hintStyle: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withOpacity(0.38),
            ),
            filled: true,
            fillColor: scheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: scheme.onSurface.withOpacity(0.38),
            ),
            suffixIcon: IconButton(
              tooltip: 'Search',
              onPressed: _applyQuery,
              icon: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: scheme.primary.withOpacity(0.7),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.outline.withOpacity(0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.outline.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Status + Sort ────────────────────────────────────────
        Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<EarningStatus?>(
                value: _statusFilter,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface,
                ),
                // Sort dropdown decoration — same, no prefixIcon
decoration: InputDecoration(
  filled: true,
  fillColor: scheme.surface,
  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
  isDense: true,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: scheme.outline.withOpacity(0.25)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: scheme.outline.withOpacity(0.25)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: scheme.primary, width: 1.5),
  ),
),
                items: <DropdownMenuItem<EarningStatus?>>[
                  const DropdownMenuItem<EarningStatus?>(
                    value: null,
                    child: Text('All statuses',
                        style: TextStyle(fontSize: 12)),
                  ),
                  ...EarningStatus.values.map(
                    (EarningStatus s) => DropdownMenuItem<EarningStatus?>(
                      value: s,
                      child: Text(s.label,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
                onChanged: (EarningStatus? value) {
                  setState(() => _statusFilter = value);
                  _applyQuery();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _ordering,
                isExpanded: true,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface,
                ),
               // Sort dropdown decoration — same, no prefixIcon
decoration: InputDecoration(
  filled: true,
  fillColor: scheme.surface,
  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
  isDense: true,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: scheme.outline.withOpacity(0.25)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: scheme.outline.withOpacity(0.25)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: scheme.primary, width: 1.5),
  ),
),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: '-date',
                    child: Text('Newest first',
                        style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem<String>(
                    value: 'date',
                    child: Text('Oldest first',
                        style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem<String>(
                    value: '-net_earnings',
                    child: Text('Highest earnings',
                        style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem<String>(
                    value: 'net_earnings',
                    child: Text('Lowest earnings',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => _ordering = value);
                  _applyQuery();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Date range + action buttons ──────────────────────────
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDateRange,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  side: BorderSide(
                    color: _dateRange != null
                        ? scheme.primary
                        : scheme.outline.withOpacity(0.3),
                    width: _dateRange != null ? 1.5 : 0.5,
                  ),
                  backgroundColor: _dateRange != null
                      ? scheme.primary.withOpacity(0.07)
                      : null,
                  foregroundColor: _dateRange != null
                      ? scheme.primary
                      : scheme.onSurface.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(Icons.date_range_rounded, size: 16),
                label: Text(
                  _dateRange == null
                      ? 'Date range'
                      : '${_formatDate(_dateRange!.start)} – ${_formatDate(_dateRange!.end)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _actionIconBtn(
              context,
              icon: Icons.close_rounded,
              tooltip: 'Clear filters',
              onTap: _clearFilters,
              danger: true,
            ),
            const SizedBox(width: 6),
            _actionIconBtn(
              context,
              icon: Icons.file_download_outlined,
              tooltip: 'Export',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Export is ready when the backend endpoint is enabled.'),
                ),
              ),
            ),
          ],
        ),

        // ── Active filter chips ──────────────────────────────────
        if (hasActiveFilters) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              if (_searchController.text.isNotEmpty)
                _filterChip(
                  context,
                  label: _searchController.text,
                  icon: Icons.search_rounded,
                  onRemove: () {
                    setState(() => _searchController.clear());
                    _applyQuery();
                  },
                ),
              if (_statusFilter != null)
                _filterChip(
                  context,
                  label: _statusFilter!.label,
                  icon: Icons.filter_alt_rounded,
                  onRemove: () {
                    setState(() => _statusFilter = null);
                    _applyQuery();
                  },
                ),
              if (_dateRange != null)
                _filterChip(
                  context,
                  label:
                      '${_formatDate(_dateRange!.start)} – ${_formatDate(_dateRange!.end)}',
                  icon: Icons.date_range_rounded,
                  onRemove: () {
                    setState(() => _dateRange = null);
                    _applyQuery();
                  },
                ),
              if (_ordering != '-date')
                _filterChip(
                  context,
                  label: _orderingLabel(_ordering),
                  icon: Icons.sort_rounded,
                  onRemove: () {
                    setState(() => _ordering = '-date');
                    _applyQuery();
                  },
                ),
            ],
          ),
        ],

        // ── Record count ─────────────────────────────────────────
        const SizedBox(height: 10),
        Text(
          '${history.total} records',
          style: AppThemes.poppins(
            context,
            fontSize: 11,
            color: scheme.onSurface.withOpacity(0.45),
          ),
        ),
      ],
    ),
  );
}

// ── Small helpers (add these to your state class) ──────────────────

String _orderingLabel(String ordering) {
  const Map<String, String> labels = <String, String>{
    'date': 'Oldest first',
    '-net_earnings': 'Highest earnings',
    'net_earnings': 'Lowest earnings',
  };
  return labels[ordering] ?? ordering;
}

Widget _actionIconBtn(
  BuildContext context, {
  required IconData icon,
  required String tooltip,
  required VoidCallback onTap,
  bool danger = false,
}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  return Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: danger
                ? scheme.error.withOpacity(0.3)
                : scheme.outline.withOpacity(0.25),
          ),
          color: danger
              ? scheme.error.withOpacity(0.06)
              : scheme.surfaceVariant.withOpacity(0.4),
        ),
        child: Icon(
          icon,
          size: 18,
          color: danger
              ? scheme.error
              : scheme.onSurface.withOpacity(0.55),
        ),
      ),
    ),
  );
}

Widget _filterChip(
  BuildContext context, {
  required String label,
  required IconData icon,
  required VoidCallback onRemove,
}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  return GestureDetector(
    onTap: onRemove,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: scheme.primary),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemes.poppins(
                context,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.surface,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.close_rounded, size: 10, color: scheme.primary),
        ],
      ),
    ),
  );
}

  Widget _earningsTable(BuildContext context, PaginatedEarnings history) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (history.items.isEmpty) {
      return _emptyState(
        context,
        'No earnings found',
        Icons.receipt_long_outlined,
      );
    }
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
          dataRowMinHeight: 54,
          dataRowMaxHeight: 64,
          headingRowColor: WidgetStatePropertyAll(
            scheme.primary.withOpacity(0.08),
          ),
          columns: const <DataColumn>[
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Order')),
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Commission')),
            DataColumn(label: Text('Gross')),
            DataColumn(label: Text('Platform Fee')),
            DataColumn(label: Text('Net')),
            DataColumn(label: Text('Status')),
          ],
          rows: history.items
              .map((EarningRecord row) {
                final Color statusColor = _statusColor(row.status);
                return DataRow(
                  cells: <DataCell>[
                    DataCell(Text(_formatDate(row.date))),
                    DataCell(Text(row.sourceOrder)),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(
                          row.customer,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(_formatCurrency(row.commission))),
                    DataCell(Text(_formatCurrency(row.grossAmount))),
                    DataCell(Text(_formatCurrency(row.platformFee))),
                    DataCell(Text(_formatCurrency(row.netEarnings))),
                    DataCell(
                      _statusBadge(context, row.status.label, statusColor),
                    ),
                  ],
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _pagination(BuildContext context, PaginatedEarnings history) {
    final int totalPages = history.pageSize == 0
        ? 1
        : math.max(1, (history.total / history.pageSize).ceil());
    return Row(
      children: <Widget>[
        Text(
          'Page ${history.page} of $totalPages',
          style: AppThemes.poppins(
            context,
            fontSize: 12,
            color: _muted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton.filledTonal(
          tooltip: 'Previous page',
          onPressed: history.page <= 1
              ? null
              : () => _applyQuery(page: history.page - 1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Next page',
          onPressed: history.hasMore
              ? () => _applyQuery(page: history.page + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _earningsTab(BuildContext context, EarningsDashboard dashboard) {
    final EarningsSummary s = dashboard.summary;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: <Widget>[
              _summaryCard(
                context,
                label: 'Total Earnings',
                value: _formatCurrency(s.totalEarnings),
                icon: Icons.payments_rounded,
              ),
              _summaryCard(
                context,
                label: 'Available Balance',
                value: _formatCurrency(s.availableBalance),
                icon: Icons.account_balance_wallet_rounded,
              ),
              _summaryCard(
                context,
                label: 'Pending Earnings',
                value: _formatCurrency(s.pendingEarnings),
                icon: Icons.hourglass_top_rounded,
              ),
              _summaryCard(
                context,
                label: 'Withdrawn Amount',
                value: _formatCurrency(s.withdrawnAmount),
                icon: Icons.outbox_rounded,
              ),
              _summaryCard(
                context,
                label: 'Processing Payouts',
                value: _formatCurrency(s.processingPayouts),
                icon: Icons.sync_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _panel(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Earnings Chart',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: CustomPaint(
                    painter: _EarningsChartPainter(
                      points: dashboard.chart,
                      colorScheme: Theme.of(context).colorScheme,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _filters(context, dashboard.history),
          const SizedBox(height: 14),
          _earningsTable(context, dashboard.history),
          const SizedBox(height: 10),
          _pagination(context, dashboard.history),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _balanceCard(BuildContext context, EarningsDashboard dashboard) {
    final EarningsSummary s = dashboard.summary;
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Current Balance',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showPayoutSheet(dashboard),
                icon: const Icon(Icons.add_card_rounded, size: 18),
                label: const Text('Request'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _balancePill(
                context,
                'Available',
                _formatCurrency(s.availableBalance),
              ),
              _balancePill(
                context,
                'Pending',
                _formatCurrency(s.pendingEarnings),
              ),
              _balancePill(
                context,
                'Minimum',
                _formatCurrency(dashboard.minimumWithdrawal),
              ),
              _balancePill(
                context,
                'Processing',
                _formatCurrency(s.processingPayouts),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balancePill(BuildContext context, String label, String value) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppThemes.poppins(
              context,
              fontSize: 10,
              color: _muted(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.poppins(
              context,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _payoutsTable(BuildContext context, PaginatedPayouts payouts) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (payouts.items.isEmpty) {
      return _emptyState(
        context,
        'No payout requests yet',
        Icons.account_balance_outlined,
      );
    }
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
          dataRowMinHeight: 54,
          dataRowMaxHeight: 64,
          headingRowColor: WidgetStatePropertyAll(
            scheme.primary.withOpacity(0.08),
          ),
          columns: const <DataColumn>[
            DataColumn(label: Text('Request Date')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Fees')),
            DataColumn(label: Text('Net Amount')),
            DataColumn(label: Text('Method')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Reference')),
            DataColumn(label: Text('Processed')),
          ],
          rows: payouts.items
              .map((PayoutRecord row) {
                final Color statusColor = _statusColor(row.status);
                return DataRow(
                  cells: <DataCell>[
                    DataCell(Text(_formatDate(row.requestDate))),
                    DataCell(Text(_formatCurrency(row.amount))),
                    DataCell(Text(_formatCurrency(row.fees))),
                    DataCell(Text(_formatCurrency(row.netAmount))),
                    DataCell(Text(row.method)),
                    DataCell(
                      _statusBadge(context, row.status.label, statusColor),
                    ),
                    DataCell(
                      Text(
                        row.transactionReference.isEmpty
                            ? '-'
                            : row.transactionReference,
                      ),
                    ),
                    DataCell(
                      Text(
                        row.processedDate == null
                            ? '-'
                            : _formatDate(row.processedDate!),
                      ),
                    ),
                  ],
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _payoutsTab(
    BuildContext context,
    EarningsDashboard dashboard,
    PaginatedPayouts payouts,
  ) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _balanceCard(context, dashboard),
          const SizedBox(height: 14),
          Text(
            'Payout History',
            style: AppThemes.poppins(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _payoutsTable(context, payouts),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, String title, IconData icon) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return _panel(
      context,
      child: Column(
        children: <Widget>[
          Icon(icon, size: 34, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppThemes.poppins(
              context,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPayoutSheet(EarningsDashboard dashboard) async {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final PayoutAccount? initialAccount = dashboard.payoutAccounts
        .where((PayoutAccount a) => a.isVerified)
        .firstOrNull;
    final TextEditingController amountController = TextEditingController();
    PayoutAccount? selectedAccount = initialAccount;
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            Future<void> submit() async {
              final double amount =
                  double.tryParse(amountController.text.trim()) ?? 0;
              if (selectedAccount == null) {
                setSheetState(
                  () => errorText = 'Choose a verified payout account.',
                );
                return;
              }
              if (amount < dashboard.minimumWithdrawal) {
                setSheetState(
                  () => errorText =
                      'Minimum withdrawal is ${_formatCurrency(dashboard.minimumWithdrawal)}.',
                );
                return;
              }
              if (amount > dashboard.maximumWithdrawal) {
                setSheetState(
                  () => errorText =
                      'Maximum withdrawal is ${_formatCurrency(dashboard.maximumWithdrawal)}.',
                );
                return;
              }
              if (amount > dashboard.summary.availableBalance) {
                setSheetState(
                  () => errorText = 'Amount exceeds available balance.',
                );
                return;
              }
              if (dashboard.summary.processingPayouts > 0) {
                setSheetState(
                  () => errorText = 'A payout is already processing.',
                );
                return;
              }

              final NavigatorState navigator = Navigator.of(sheetContext);
              final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                context,
              );
              final EarningsRepository repository = ref.read(
                earningsRepositoryProvider,
              );
              await repository.requestPayout(
                PayoutRequestPayload(
                  amount: amount,
                  method: selectedAccount!.method,
                  accountId: selectedAccount!.id,
                ),
              );
              if (!mounted) {
                return;
              }
              navigator.pop();
              await _refresh();
              if (!mounted) {
                return;
              }
              messenger.showSnackBar(
                const SnackBar(content: Text('Payout request submitted.')),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Request Payout',
                    style: AppThemes.poppins(
                      context,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.outline.withOpacity(0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.outline.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.primary, width: 1.5),
            ),
                      fillColor: scheme.surface,
                      labelText: 'Withdrawal amount',
                      labelStyle: TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.payments_rounded),
                      helperText:
                          'Available: ${_formatCurrency(dashboard.summary.availableBalance)}',
                    ), style: TextStyle(fontSize: 10),
                    
                    onChanged: (_) => setSheetState(() => errorText = null),
                  ),

                  const SizedBox(height: 28),
                  DropdownButtonFormField<PayoutAccount>(
                    value: selectedAccount,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.outline.withOpacity(0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.outline.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: scheme.primary, width: 1.5),
            ),
                      fillColor:  scheme.surface,
                      labelText: 'Payout account',
                      prefixIcon: const Icon(Icons.account_balance_rounded),
                    ),
                    items: dashboard.payoutAccounts
                        .map(
                          (PayoutAccount account) =>
                              DropdownMenuItem<PayoutAccount>(
                                value: account,
                                enabled: account.isVerified,
                                child: Text(
                                  '${account.label} - ${account.maskedAccount}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                        )
                        .toList(growable: false),
                    onChanged: (PayoutAccount? account) {
                      setSheetState(() {
                        selectedAccount = account;
                        errorText = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _panel(
                    context,
                    child: Text(
                    'A processing fee is deducted from your earnings before payout — '
                    '3% for Telebirr and 1% for bank transfers. Review your payout '
                    'account before submitting, as fees vary by method. Payouts '
                    'typically arrive within 1–3 business days.',
                    style: AppThemes.poppins(
                      context,
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),),
                  
                  if (errorText != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: AppThemes.poppins(
                        context,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: submit,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Submit Request'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark
        ? const Color(0xFF172026)
        : const Color(0xFFEAF5EE);
    final AsyncValue<EarningsDashboard> dashboardAsync = ref.watch(
      earningsDashboardProvider,
    );
    final AsyncValue<PaginatedPayouts> payoutsAsync = ref.watch(
      payoutsProvider,
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Earnings & Payouts',
          style: AppThemes.poppins(
            context,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.insights_rounded), text: 'Earnings'),
            Tab(
              icon: Icon(Icons.account_balance_wallet_rounded),
              text: 'Payouts',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[bgTop, scheme.surface, scheme.surface],
            stops: const <double>[0.0, 0.24, 1.0],
          ),
        ),
        child: dashboardAsync.when(
          loading: _loadingView,
          error: (Object error, StackTrace stackTrace) =>
              _errorView(context, error),
          data: (EarningsDashboard dashboard) {
            return payoutsAsync.when(
              loading: _loadingView,
              error: (Object error, StackTrace stackTrace) =>
                  _errorView(context, error),
              data: (PaginatedPayouts payouts) {
                return TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _earningsTab(context, dashboard),
                    _payoutsTab(context, dashboard, payouts),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EarningsChartPainter extends CustomPainter {
  const _EarningsChartPainter({
    required this.points,
    required this.colorScheme,
  });

  final List<EarningsChartPoint> points;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }
    final Paint gridPaint = Paint()
      ..color = colorScheme.onSurface.withOpacity(0.08)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final double y = (size.height * i) / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double maxAmount = points.fold<double>(
      0,
      (double maxValue, EarningsChartPoint point) =>
          math.max(maxValue, point.amount),
    );
    final double upperBound = maxAmount <= 0 ? 1 : maxAmount * 1.2;
    final double step = points.length == 1
        ? size.width
        : size.width / (points.length - 1);
    final List<Offset> offsets = List<Offset>.generate(points.length, (
      int index,
    ) {
      final double x = points.length == 1 ? size.width / 2 : step * index;
      final double y =
          size.height -
          ((points[index].amount / upperBound).clamp(0.0, 1.0) * size.height);
      return Offset(x, y);
    });

    final Path linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      linePath.lineTo(offsets[i].dx, offsets[i].dy);
    }
    final Path areaPath = Path.from(linePath)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            colorScheme.primary.withOpacity(0.26),
            colorScheme.primary.withOpacity(0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (final Offset offset in offsets) {
      canvas.drawCircle(offset, 4.5, Paint()..color = colorScheme.primary);
      canvas.drawCircle(offset, 1.8, Paint()..color = colorScheme.onPrimary);
    }
  }

  @override
  bool shouldRepaint(covariant _EarningsChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.colorScheme != colorScheme;
  }
}
