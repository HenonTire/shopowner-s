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
    ref.read(earningsQueryProvider.notifier).state = current.copyWith(
      page: page ?? 1,
      search: _searchController.text,
      status: _statusFilter,
      clearStatus: _statusFilter == null,
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _statusFilter = null;
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

  String _shortId(String? id) {
    if (id == null || id.isEmpty) {
      return '-';
    }
    return id.length <= 8 ? id : id.substring(0, 8);
  }

  Color _muted(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.colorScheme.onSurface.withOpacity(
      theme.brightness == Brightness.dark ? 0.76 : 0.64,
    );
  }

  Color _statusColor(Object status) {
    if (status == EarningStatus.available ||
        status == PayoutStatus.completed) {
      return const Color(0xFF1B8F4D);
    }
    if (status == EarningStatus.pendingPayout ||
        status == PayoutStatus.requested ||
        status == PayoutStatus.processing) {
      return const Color(0xFFB7791F);
    }
    if (status == EarningStatus.paidOut) {
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
    final bool hasActiveFilters =
        _statusFilter != null || _searchController.text.isNotEmpty;

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
              hintText: 'Search by role',
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
                borderSide: BorderSide(color: scheme.outline.withOpacity(0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outline.withOpacity(0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Status filter + Clear ────────────────────────────────
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<EarningStatus?>(
                  initialValue: _statusFilter,
                  style: TextStyle(fontSize: 12, color: scheme.onSurface),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: scheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 0, horizontal: 10),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: scheme.outline.withOpacity(0.25)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: scheme.outline.withOpacity(0.25)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                  ),
                  items: <DropdownMenuItem<EarningStatus?>>[
                    const DropdownMenuItem<EarningStatus?>(
                      value: null,
                      child: Text('All statuses', style: TextStyle(fontSize: 12)),
                    ),
                    ...EarningStatus.values.map(
                      (EarningStatus s) => DropdownMenuItem<EarningStatus?>(
                        value: s,
                        child: Text(s.label, style: const TextStyle(fontSize: 12)),
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
              _actionIconBtn(
                context,
                icon: Icons.close_rounded,
                tooltip: 'Clear filters',
                onTap: _clearFilters,
                danger: true,
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
                : scheme.surfaceContainerHighest.withOpacity(0.4),
          ),
          child: Icon(
            icon,
            size: 18,
            color: danger ? scheme.error : scheme.onSurface.withOpacity(0.55),
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
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Status')),
          ],
          rows: history.items
              .map((EarningRecord row) {
                final Color statusColor = _statusColor(row.status);
                return DataRow(
                  cells: <DataCell>[
                    DataCell(Text(_formatDate(row.date))),
                    DataCell(Text(_shortId(row.orderId))),
                    DataCell(Text(row.role.isEmpty ? '-' : row.role)),
                    DataCell(Text(_formatCurrency(row.amount))),
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

  Widget _pagination(
    BuildContext context, {
    required int page,
    required int pageSize,
    required int total,
    required bool hasMore,
    required ValueChanged<int> onPageChange,
  }) {
    final int totalPages =
        pageSize == 0 ? 1 : (total / pageSize).ceil().clamp(1, 1 << 30);
    return Row(
      children: <Widget>[
        Text(
          'Page $page of $totalPages',
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
          onPressed: page <= 1 ? null : () => onPageChange(page - 1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Next page',
          onPressed: hasMore ? () => onPageChange(page + 1) : null,
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
                label: 'Pending Payout',
                value: _formatCurrency(s.pendingEarnings),
                icon: Icons.hourglass_top_rounded,
              ),
              _summaryCard(
                context,
                label: 'Withdrawn Amount',
                value: _formatCurrency(s.withdrawnAmount),
                icon: Icons.outbox_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _filters(context, dashboard.history),
          const SizedBox(height: 14),
          _earningsTable(context, dashboard.history),
          const SizedBox(height: 10),
          _pagination(
            context,
            page: dashboard.history.page,
            pageSize: dashboard.history.pageSize,
            total: dashboard.history.total,
            hasMore: dashboard.history.hasMore,
            onPageChange: (int page) => _applyQuery(page: page),
          ),
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
                onPressed: s.availableBalance > 0
                    ? () => _showPayoutSheet(dashboard)
                    : null,
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
                'Withdrawn',
                _formatCurrency(s.withdrawnAmount),
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
            DataColumn(label: Text('Method')),
            DataColumn(label: Text('Account')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Reference')),
          ],
          rows: payouts.items
              .map((PayoutRecord row) {
                final Color statusColor = _statusColor(row.status);
                return DataRow(
                  cells: <DataCell>[
                    DataCell(Text(_formatDate(row.requestDate))),
                    DataCell(Text(_formatCurrency(row.amount))),
                    DataCell(Text(row.payoutMethod.isEmpty ? '-' : row.payoutMethod)),
                    DataCell(Text(row.payoutAccount.isEmpty ? '-' : row.payoutAccount)),
                    DataCell(
                      _statusBadge(context, row.status.label, statusColor),
                    ),
                    DataCell(
                      Text(row.providerReference?.isNotEmpty == true
                          ? row.providerReference!
                          : '-'),
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
    final TextEditingController amountController = TextEditingController();
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            bool submitting = false;

            Future<void> submit() async {
              if (submitting) {
                return;
              }
              final String rawAmount = amountController.text.trim();
              final double? amount =
                  rawAmount.isEmpty ? null : double.tryParse(rawAmount);

              if (rawAmount.isNotEmpty && amount == null) {
                setSheetState(() => errorText = 'Enter a valid amount.');
                return;
              }
              if (amount != null && amount <= 0) {
                setSheetState(
                  () => errorText = 'Amount must be greater than 0.',
                );
                return;
              }
              if (amount != null && amount > dashboard.summary.availableBalance) {
                setSheetState(
                  () => errorText = 'Amount exceeds available balance.',
                );
                return;
              }

              setSheetState(() {
                submitting = true;
                errorText = null;
              });

              final NavigatorState navigator = Navigator.of(sheetContext);
              final ScaffoldMessengerState messenger =
                  ScaffoldMessenger.of(context);
              final EarningsRepository repository =
                  ref.read(earningsRepositoryProvider);

              try {
                await repository.requestPayout(
                  PayoutRequestPayload(amount: amount),
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
              } catch (e) {
                setSheetState(() {
                  submitting = false;
                  errorText = e.toString();
                });
              }
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
                  const SizedBox(height: 6),
                  Text(
                    'Leave the amount blank to withdraw your full available '
                    'balance. Your saved payout account is used automatically.',
                    style: AppThemes.poppins(
                      context,
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                        borderSide: BorderSide(color: scheme.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: scheme.surface,
                      labelText: 'Withdrawal amount (optional)',
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.payments_rounded),
                      helperText:
                          'Available: ${_formatCurrency(dashboard.summary.availableBalance)}',
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) => setSheetState(() => errorText = null),
                  ),
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
                      onPressed: submitting ? null : submit,
                      icon: submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                          submitting ? 'Submitting...' : 'Submit Request'),
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
    final Color bgTop = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final AsyncValue<EarningsDashboard> dashboardAsync =
        ref.watch(earningsDashboardProvider);
    final AsyncValue<PaginatedPayouts> payoutsAsync = ref.watch(payoutsProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Earnings & Payouts',
          style: AppThemes.poppins(context, fontSize: 18, fontWeight: FontWeight.w700),
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
            Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Payouts'),
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
          error: (Object error, StackTrace stackTrace) => _errorView(context, error),
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