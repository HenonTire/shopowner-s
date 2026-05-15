import 'package:flutter/material.dart';
import 'package:shop_manager/pages/add_marketer_contract_page.dart';
import 'package:shop_manager/pages/marketer_chat_page.dart';
import 'package:shop_manager/pages/marketer_detail_page.dart';

import 'package:shop_manager/theme/app_themes.dart';

enum _ContractsTab { active, past }
enum _Health { good, warning, bad }
enum _InsightView { overview, efficiency, risks }

class MarketerContractsPage extends StatefulWidget {
  const MarketerContractsPage({super.key});

  @override
  State<MarketerContractsPage> createState() => _MarketerContractsPageState();
}

class _MarketerContractsPageState extends State<MarketerContractsPage> {
  _ContractsTab _tab = _ContractsTab.active;
  _InsightView _insightView = _InsightView.overview;
  bool _includePastInInsights = false;
  int? _expandedActiveIndex;
  int? _focusedActiveIndex;

  final List<_ActiveContract> _activeContracts = <_ActiveContract>[
    _ActiveContract(
      marketerId: 'alem-genet',
      name: 'Alem Genet',
      specialization: 'Facebook Ads Expert',
      contractStatus: 'Active',
      startDate: DateTime(2026, 4, 10),
      endDate: DateTime(2026, 6, 8),
      campaignProgress: 0.74,
      budgetUsed: 51200,
      budgetTotal: 70000,
      revenue: 154300,
      orders: 911,
      conversionRate: 5.8,
      trendPercent: 7.4,
      avatarColor: const Color(0xFF1E88E5),
    ),
    _ActiveContract(
      marketerId: 'samuel-taye',
      name: 'Samuel Taye',
      specialization: 'TikTok Growth Strategist',
      contractStatus: 'Expiring Soon',
      startDate: DateTime(2026, 3, 20),
      endDate: DateTime(2026, 5, 10),
      campaignProgress: 0.89,
      budgetUsed: 87500,
      budgetTotal: 92000,
      revenue: 131600,
      orders: 754,
      conversionRate: 3.1,
      trendPercent: -3.6,
      avatarColor: const Color(0xFF43A047),
    ),
    _ActiveContract(
      marketerId: 'mimi-haile',
      name: 'Mimi Haile',
      specialization: 'Content Creator',
      contractStatus: 'Pending',
      startDate: DateTime(2026, 5, 6),
      endDate: DateTime(2026, 7, 5),
      campaignProgress: 0.22,
      budgetUsed: 13800,
      budgetTotal: 64000,
      revenue: 22600,
      orders: 128,
      conversionRate: 2.3,
      trendPercent: -1.8,
      avatarColor: const Color(0xFFF4511E),
    ),
  ];

  final List<_PastContract> _pastContracts = <_PastContract>[
    _PastContract(
      marketerId: 'nati-birhanu',
      name: 'Nati Birhanu',
      specialization: 'Google Ads Specialist',
      finalStatus: 'Completed',
      totalRevenue: 187400,
      totalOrders: 1092,
      finalConversionRate: 4.4,
      spent: 92000,
      rating: 4,
      review: 'Strong at high-intent traffic and consistent reporting.',
      avatarColor: const Color(0xFF8E24AA),
    ),
    _PastContract(
      marketerId: 'ruth-solomon',
      name: 'Ruth Solomon',
      specialization: 'Email & Retention Marketer',
      finalStatus: 'Completed',
      totalRevenue: 68400,
      totalOrders: 351,
      finalConversionRate: 2.6,
      spent: 54000,
      rating: 3,
      review: 'Decent recovery campaigns, but growth flattened later.',
      avatarColor: const Color(0xFF6D4C41),
    ),
    _PastContract(
      marketerId: 'dawit-mamo',
      name: 'Dawit Mamo',
      specialization: 'Marketplace Promotions Lead',
      finalStatus: 'Cancelled',
      totalRevenue: 30100,
      totalOrders: 184,
      finalConversionRate: 1.7,
      spent: 46000,
      rating: 2,
      review: 'Paused due to weak conversion and channel mismatch.',
      avatarColor: const Color(0xFF00897B),
    ),
  ];

  String _money(double value) => 'ETB ${value.toStringAsFixed(2)}';
  int _daysRemaining(DateTime endDate) => endDate.difference(DateTime.now()).inDays;
  String _initials(String name) => name.split(' ').map((String s) => s.isEmpty ? '' : s[0]).take(2).join().toUpperCase();

  _Health _performanceHealth(double conversion) {
    if (conversion < 2.2) return _Health.bad;
    if (conversion < 3.5) return _Health.warning;
    return _Health.good;
  }

  _Health _statusHealth(String status) {
    if (status == 'Active' || status == 'Completed') return _Health.good;
    if (status == 'Pending' || status == 'Expiring Soon') return _Health.warning;
    return _Health.bad;
  }

  Color _healthColor(_Health health) {
    switch (health) {
      case _Health.good:
        return const Color(0xFF1B8F4D);
      case _Health.warning:
        return const Color(0xFFE09B18);
      case _Health.bad:
        return const Color(0xFFC62828);
    }
  }

  String _outcome(_PastContract c) {
    final double roi = c.spent <= 0 ? 0 : ((c.totalRevenue - c.spent) / c.spent) * 100;
    if (roi >= 60 && c.finalConversionRate >= 4.0) return 'Successful';
    if (roi >= 20 && c.finalConversionRate >= 2.6) return 'Average';
    return 'Underperformed';
  }

  String _channelFromSpecialization(String specialization) {
    final String text = specialization.toLowerCase();
    if (text.contains('facebook')) return 'Facebook Ads';
    if (text.contains('tiktok')) return 'TikTok';
    if (text.contains('google')) return 'Google Ads';
    if (text.contains('email')) return 'Email';
    return 'Marketplace';
  }

  void _insertDraftAsActiveContract(MarketerContractDraft draft, {Color? avatarColorOverride}) {
    const List<Color> palette = <Color>[
      Color(0xFF1E88E5),
      Color(0xFF43A047),
      Color(0xFFF4511E),
      Color(0xFF8E24AA),
      Color(0xFF00897B),
    ];
    final String marketerId = draft.name
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');
    final Color avatarColor = avatarColorOverride ?? palette[_activeContracts.length % palette.length];
    final double budgetUsed = (draft.budgetTotal * (draft.initialProgress * 0.7)).clamp(0, draft.budgetTotal).toDouble();
    final double revenue = budgetUsed * (1.6 + (draft.conversionTarget / 10));
    final int orders = (draft.initialProgress * 9).round();
    final double trendPercent = draft.status == 'Active' ? 0.8 : draft.status == 'Expiring Soon' ? -0.6 : 0;

    setState(() {
      _activeContracts.insert(
        0,
        _ActiveContract(
          marketerId: marketerId,
          name: draft.name,
          specialization: '${draft.specialization} | ${draft.channel}',
          contractStatus: draft.status,
          startDate: draft.startDate,
          endDate: draft.endDate,
          campaignProgress: draft.initialProgress,
          budgetUsed: budgetUsed,
          budgetTotal: draft.budgetTotal,
          revenue: revenue,
          orders: orders,
          conversionRate: draft.conversionTarget,
          trendPercent: trendPercent,
          avatarColor: avatarColor,
        ),
      );
      _tab = _ContractsTab.active;
      _expandedActiveIndex = 0;
      _focusedActiveIndex = 0;
    });
  }

  Future<void> _openAddContract() async {
    final MarketerContractDraft? draft = await Navigator.of(context).push<MarketerContractDraft>(
      MaterialPageRoute<MarketerContractDraft>(
        builder: (_) => const AddMarketerContractPage(),
      ),
    );
    if (!mounted || draft == null) {
      return;
    }

    _insertDraftAsActiveContract(draft);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Contract for ${draft.name} created',
          style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _openRehireContract(_PastContract c) async {
    final MarketerContractDraft? draft = await Navigator.of(context).push<MarketerContractDraft>(
      MaterialPageRoute<MarketerContractDraft>(
        builder: (_) => AddMarketerContractPage(
          initialName: c.name,
          initialSpecialization: c.specialization,
          initialChannel: _channelFromSpecialization(c.specialization),
        ),
      ),
    );
    if (!mounted || draft == null) {
      return;
    }
    _insertDraftAsActiveContract(draft, avatarColorOverride: c.avatarColor);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rehired ${c.name} with a new contract',
          style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _signedPercent(double value) => '${value >= 0 ? '+' : '-'}${value.abs().toStringAsFixed(1)}%';

  _InsightStats _buildInsightStats() {
    double spent = 0;
    double revenue = 0;
    double conversionSum = 0;
    int conversionCount = 0;
    int orders = 0;
    int expiringSoon = 0;
    int atRisk = 0;
    int onTrack = 0;
    double activeBudgetUsed = 0;
    double activeBudgetTotal = 0;
    String topPerformer = '-';
    double topRevenue = -1;

    for (final _ActiveContract c in _activeContracts) {
      spent += c.budgetUsed;
      revenue += c.revenue;
      orders += c.orders;
      conversionSum += c.conversionRate;
      conversionCount++;
      activeBudgetUsed += c.budgetUsed;
      activeBudgetTotal += c.budgetTotal;
      final double budgetRatio = c.budgetTotal <= 0 ? 0 : c.budgetUsed / c.budgetTotal;
      final bool risky = c.conversionRate < 2.8 || c.trendPercent < -2.0 || budgetRatio >= 0.9;
      final bool improving = c.trendPercent >= 0;
      if (risky) atRisk++;
      if (improving && c.conversionRate >= 2.8) onTrack++;
      if (_daysRemaining(c.endDate) <= 7) expiringSoon++;
      if (c.revenue > topRevenue) {
        topRevenue = c.revenue;
        topPerformer = c.name;
      }
    }

    if (_includePastInInsights) {
      for (final _PastContract c in _pastContracts) {
        spent += c.spent;
        revenue += c.totalRevenue;
        orders += c.totalOrders;
        conversionSum += c.finalConversionRate;
        conversionCount++;
        final String outcome = _outcome(c);
        if (outcome == 'Underperformed') {
          atRisk++;
        } else {
          onTrack++;
        }
        if (c.totalRevenue > topRevenue) {
          topRevenue = c.totalRevenue;
          topPerformer = c.name;
        }
      }
    }

    final int totalContracts = _activeContracts.length + (_includePastInInsights ? _pastContracts.length : 0);
    final double net = revenue - spent;
    final double roiPercent = spent <= 0 ? 0 : (net / spent) * 100;
    final double avgConversion = conversionCount == 0 ? 0 : conversionSum / conversionCount;
    final double budgetUsageRatio = activeBudgetTotal <= 0 ? 0 : activeBudgetUsed / activeBudgetTotal;
    final double roas = spent <= 0 ? 0 : revenue / spent;

    return _InsightStats(
      spent: spent,
      revenue: revenue,
      net: net,
      roiPercent: roiPercent,
      orders: orders,
      totalContracts: totalContracts,
      avgConversion: avgConversion,
      expiringSoon: expiringSoon,
      atRisk: atRisk,
      onTrack: onTrack,
      budgetUsageRatio: budgetUsageRatio,
      roas: roas,
      topPerformer: topPerformer,
      topRevenue: topRevenue < 0 ? 0 : topRevenue,
    );
  }

  Widget _chip(BuildContext context, String text, _Health health) {
    final Color color = _healthColor(health);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Text(text, style: AppThemes.poppins(context, fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _insightsCard(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final _InsightStats stats = _buildInsightStats();
    final bool positiveRoi = stats.net >= 0;
    final Color roiColor = positiveRoi ? const Color(0xFF1B8F4D) : const Color(0xFFC62828);
    final double onTrackRatio = stats.totalContracts <= 0 ? 0 : stats.onTrack / stats.totalContracts;
    final double riskRatio = stats.totalContracts <= 0 ? 0 : stats.atRisk / stats.totalContracts;
    final double revenueShare = stats.revenue <= 0 ? 0 : (stats.revenue / (stats.revenue + stats.spent));
    final String selectedModeLabel = _includePastInInsights ? 'All contracts' : 'Active only';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text('Contract Insights', style: AppThemes.poppins(context, fontSize: 14, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  selectedModeLabel,
                  style: AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.w700, color: scheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(child: _insightScopeChip(context, label: 'Active contracts', includePast: false, isLeft: true)),
                Container(width: 1, height: 20, color: scheme.onSurface.withOpacity(0.08)),
                Expanded(child: _insightScopeChip(context, label: 'All contracts', includePast: true, isLeft: false)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _insightViewChip(context, 'Overview', _InsightView.overview),
              _insightViewChip(context, 'Efficiency', _InsightView.efficiency),
              _insightViewChip(context, 'Risks', _InsightView.risks),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _insightMetricTile(
                  context,
                  label: 'Spent',
                  value: _money(stats.spent),
                  subtitle: '${stats.totalContracts} contracts',
                  valueColor: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _insightMetricTile(
                  context,
                  label: 'Revenue',
                  value: _money(stats.revenue),
                  subtitle: '${stats.orders} orders',
                  valueColor: const Color(0xFF1B8F4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _insightMetricTile(
            context,
            label: 'Net ROI',
            value: '${_money(stats.net)} (${_signedPercent(stats.roiPercent)})',
            subtitle: 'ROAS ${stats.roas.toStringAsFixed(2)}x',
            valueColor: roiColor,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: revenueShare.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFC62828).withOpacity(0.16),
              color: const Color(0xFF1B8F4D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Revenue-to-spend balance',
            style: AppThemes.poppins(context, fontSize: 10, color: scheme.onSurface.withOpacity(0.62)),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _insightDetailPanel(
              context,
              stats: stats,
              onTrackRatio: onTrackRatio,
              riskRatio: riskRatio,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightViewChip(BuildContext context, String label, _InsightView value) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool selected = _insightView == value;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _insightView = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? scheme.primary : scheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: AppThemes.poppins(
            context,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? scheme.onPrimary : scheme.onSurface.withOpacity(0.74),
          ),
        ),
      ),
    );
  }

  Widget _insightScopeChip(
    BuildContext context, {
    required String label,
    required bool includePast,
    required bool isLeft,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool selected = _includePastInInsights == includePast;
    return InkWell(
      borderRadius: BorderRadius.horizontal(
        left: isLeft ? const Radius.circular(9) : Radius.zero,
        right: isLeft ? Radius.zero : const Radius.circular(9),
      ),
      onTap: () => setState(() => _includePastInInsights = includePast),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(9) : Radius.zero,
            right: isLeft ? Radius.zero : const Radius.circular(9),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppThemes.poppins(
              context,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: selected ? scheme.primary : scheme.onSurface.withOpacity(0.72),
            ),
          ),
        ),
      ),
    );
  }

  Widget _insightMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required String subtitle,
    required Color valueColor,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppThemes.poppins(context, fontSize: 10, color: scheme.onSurface.withOpacity(0.62), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: AppThemes.poppins(context, fontSize: 12, color: valueColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 1),
          Text(subtitle, style: AppThemes.poppins(context, fontSize: 10, color: scheme.onSurface.withOpacity(0.56), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _insightDetailPanel(
    BuildContext context, {
    required _InsightStats stats,
    required double onTrackRatio,
    required double riskRatio,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    switch (_insightView) {
      case _InsightView.overview:
        return Container(
          key: const ValueKey<String>('overview'),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.onSurface.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Top performer', style: AppThemes.poppins(context, fontSize: 10, color: scheme.onSurface.withOpacity(0.62), fontWeight: FontWeight.w600)),
                    Text(stats.topPerformer, style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700)),
                    Text(_money(stats.topRevenue), style: AppThemes.poppins(context, fontSize: 11, color: const Color(0xFF1B8F4D), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Contract health', style: AppThemes.poppins(context, fontSize: 10, color: scheme.onSurface.withOpacity(0.62), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: onTrackRatio.clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: scheme.onSurface.withOpacity(0.08),
                        color: const Color(0xFF1B8F4D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(onTrackRatio * 100).toStringAsFixed(0)}% on-track',
                      style: AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF1B8F4D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case _InsightView.efficiency:
        return Container(
          key: const ValueKey<String>('efficiency'),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.onSurface.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _insightMiniStat(
                  context,
                  label: 'Avg conversion',
                  value: '${stats.avgConversion.toStringAsFixed(1)}%',
                  color: _healthColor(_performanceHealth(stats.avgConversion)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _insightMiniStat(
                  context,
                  label: 'Budget used',
                  value: '${(stats.budgetUsageRatio * 100).toStringAsFixed(0)}%',
                  color: const Color(0xFFE09B18),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _insightMiniStat(
                  context,
                  label: 'ROAS',
                  value: '${stats.roas.toStringAsFixed(2)}x',
                  color: stats.roas >= 1 ? const Color(0xFF1B8F4D) : const Color(0xFFC62828),
                ),
              ),
            ],
          ),
        );
      case _InsightView.risks:
        return Container(
          key: const ValueKey<String>('risks'),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.onSurface.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _riskRow(context, label: 'At-risk contracts', value: '${stats.atRisk}/${stats.totalContracts}', ratio: riskRatio, color: const Color(0xFFC62828)),
              const SizedBox(height: 6),
              _riskRow(
                context,
                label: 'Expiring in 7 days',
                value: '${stats.expiringSoon}/${_activeContracts.length}',
                ratio: _activeContracts.isEmpty ? 0 : stats.expiringSoon / _activeContracts.length,
                color: const Color(0xFFE09B18),
              ),
              const SizedBox(height: 6),
              _riskRow(context, label: 'On-track contracts', value: '${stats.onTrack}/${stats.totalContracts}', ratio: onTrackRatio, color: const Color(0xFF1B8F4D)),
            ],
          ),
        );
    }
  }

  Widget _insightMiniStat(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppThemes.poppins(context, fontSize: 8, color: scheme.onSurface.withOpacity(0.58), fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: AppThemes.poppins(context, fontSize: 10, color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _riskRow(
    BuildContext context, {
    required String label,
    required String value,
    required double ratio,
    required Color color,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.w600))),
            Text(value, style: AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: scheme.onSurface.withOpacity(0.08),
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _openContractChat(_ActiveContract c) async {
    final double rating = (c.conversionRate / 1.2).clamp(1.0, 5.0).toDouble();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MarketerChatPage(
          marketerId: c.marketerId,
          marketerName: c.name,
          specialization: c.specialization,
          avatarColor: c.avatarColor,
          tagline: '${c.specialization} focused on measurable order growth and ROI.',
          rating: rating,
          totalOrders: c.orders,
          conversionRate: c.conversionRate,
          revenueGenerated: _money(c.revenue),
          badgeLabel: c.contractStatus,
        ),
      ),
    );
  }

  Future<void> _openActiveContractDetail(_ActiveContract c) async {
    final double rating = (c.conversionRate / 1.2).clamp(1.0, 5.0).toDouble();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MarketerDetailPage(
          marketerId: c.marketerId,
          name: c.name,
          specialization: c.specialization,
          tagline: '${c.specialization} focused on measurable order growth and ROI.',
          rating: rating,
          totalOrders: c.orders,
          conversionRate: c.conversionRate,
          revenueGenerated: _money(c.revenue),
          avatarColor: c.avatarColor,
          badgeLabel: c.contractStatus,
        ),
      ),
    );
  }

  Future<void> _openPastContractDetail(_PastContract c) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MarketerDetailPage(
          marketerId: c.marketerId,
          name: c.name,
          specialization: c.specialization,
          tagline: c.review,
          rating: c.rating.toDouble(),
          totalOrders: c.totalOrders,
          conversionRate: c.finalConversionRate,
          revenueGenerated: _money(c.totalRevenue),
          avatarColor: c.avatarColor,
          badgeLabel: c.finalStatus,
        ),
      ),
    );
  }

  void _showContractAction(String label, _ActiveContract c) {
    if (label == 'Message') {
      _openContractChat(c);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 900),
        content: Text('$label for ${c.name}', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _activeQuickAction(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: scheme.onSurface.withOpacity(0.72)),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppThemes.poppins(
                context,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withOpacity(0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeMiniMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: AppThemes.poppins(
              context,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          Text(
            label,
            style: AppThemes.poppins(
              context,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withOpacity(0.58),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeCard(BuildContext context, _ActiveContract c, int index) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int daysLeft = _daysRemaining(c.endDate);
    final bool improving = c.trendPercent >= 0;
    final bool expanded = _expandedActiveIndex == index;
    final bool focused = _focusedActiveIndex == index;
    final double budgetRatio = c.budgetTotal <= 0 ? 0 : c.budgetUsed / c.budgetTotal;
    final List<String> alerts = <String>[
      if (c.conversionRate < 2.8 || c.trendPercent < -2.0) 'Low performance',
      if (budgetRatio >= 0.9) 'Budget almost finished',
      if (daysLeft <= 7) 'Contract about to expire',
    ];
    final Color trendColor = improving ? const Color(0xFF1B8F4D) : const Color(0xFFC62828);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: focused ? scheme.primary.withOpacity(0.05) : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused ? scheme.primary.withOpacity(0.34) : scheme.onSurface.withOpacity(0.10),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: focused ? scheme.primary.withOpacity(0.10) : Colors.black.withOpacity(0.03),
            blurRadius: focused ? 14 : 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expandedActiveIndex = expanded ? null : index),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openActiveContractDetail(c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(
                                backgroundColor: c.avatarColor.withOpacity(0.2),
                                child: Text(
                                  _initials(c.name),
                                  style: AppThemes.poppins(
                                    context,
                                    fontWeight: FontWeight.w700,
                                    color: c.avatarColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(c.name, style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700)),
                                    Text(c.specialization, style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.65))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: focused ? 'Unfocus' : 'Focus',
                      onPressed: () {
                        setState(() => _focusedActiveIndex = focused ? null : index);
                      },
                      icon: Icon(
                        focused ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 20,
                        color: focused ? scheme.primary : scheme.onSurface.withOpacity(0.56),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: scheme.onSurface.withOpacity(0.62)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    _chip(context, c.contractStatus, _statusHealth(c.contractStatus)),
                    const SizedBox(width: 8),
                    _chip(context, '${c.trendPercent >= 0 ? '+' : '-'} ${c.trendPercent.abs().toStringAsFixed(1)}%', improving ? _Health.good : _Health.bad),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _activeMiniMetric(
                        context,
                        label: 'Progress',
                        value: '${(c.campaignProgress * 100).toStringAsFixed(0)}%',
                        valueColor: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _activeMiniMetric(
                        context,
                        label: 'Budget used',
                        value: '${(budgetRatio * 100).toStringAsFixed(0)}%',
                        valueColor: budgetRatio >= 0.9 ? const Color(0xFFC62828) : const Color(0xFFE09B18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _activeMiniMetric(
                        context,
                        label: 'Conversion',
                        value: '${c.conversionRate.toStringAsFixed(1)}%',
                        valueColor: _healthColor(_performanceHealth(c.conversionRate)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _activeQuickAction(
                        context,
                        label: 'Message',
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: () => _showContractAction('Message', c),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _activeQuickAction(
                        context,
                        label: 'Meeting',
                        icon: Icons.event_available_rounded,
                        onTap: () => _showContractAction('Schedule meeting', c),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _activeQuickAction(
                        context,
                        label: 'Report',
                        icon: Icons.assessment_outlined,
                        onTap: () => _showContractAction('Open report', c),
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Tap card to expand full contract details',
                      style: AppThemes.poppins(
                        context,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withOpacity(0.58),
                      ),
                    ),
                  ),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 10),
                      Text('Start Date: ${c.startDate.day}/${c.startDate.month}/${c.startDate.year}', style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600)),
                      Text('Days Remaining: ${daysLeft >= 0 ? daysLeft : 0}', style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Campaign progress ${(c.campaignProgress * 100).toStringAsFixed(0)}%', style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: c.campaignProgress, minHeight: 8)),
                      const SizedBox(height: 8),
                      Text('Budget usage: ${_money(c.budgetUsed)} / ${_money(c.budgetTotal)}', style: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Revenue: ${_money(c.revenue)} | Orders: ${c.orders} | Conversion: ${c.conversionRate.toStringAsFixed(1)}%', style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600, color: _healthColor(_performanceHealth(c.conversionRate)))),
                      Text(improving ? 'Performance is improving' : 'Performance is dropping', style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w700, color: trendColor)),
                      if (alerts.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        ...alerts.map((String alert) => Text('! $alert', style: AppThemes.poppins(context, fontSize: 10, color: const Color(0xFFE09B18), fontWeight: FontWeight.w700))),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showContractAction('Pause contract', c),
                              child: Text('Pause Contract', style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showContractAction('Extend contract', c),
                                  child: Center(
                                    child: Text(
                                      'Extend Contract',
                                      style: AppThemes.poppins(
                                        context,
                                        fontSize: 12,
                                        color: scheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 240),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pastCard(BuildContext context, _PastContract c) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String outcome = _outcome(c);
    final _Health health = outcome == 'Successful' ? _Health.good : outcome == 'Average' ? _Health.warning : _Health.bad;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.onSurface.withOpacity(0.10))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openPastContractDetail(c),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: <Widget>[
              CircleAvatar(backgroundColor: c.avatarColor.withOpacity(0.2), child: Text(_initials(c.name), style: AppThemes.poppins(context, fontWeight: FontWeight.w700, color: c.avatarColor))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(c.name, style: AppThemes.poppins(context, fontSize: 15, fontWeight: FontWeight.w700)),
                Text(c.specialization, style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.65))),
              ])),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: <Widget>[_chip(context, c.finalStatus, _statusHealth(c.finalStatus)), const SizedBox(width: 8), _chip(context, outcome, health)]),
        const SizedBox(height: 8),
        Text('Total revenue generated: ${_money(c.totalRevenue)}', style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600)),
        Text('Total orders: ${c.totalOrders}', style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600)),
        Text('Final conversion rate: ${c.finalConversionRate.toStringAsFixed(1)}%', style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: List<Widget>.generate(5, (int i) => Icon(i < c.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 18, color: i < c.rating ? const Color(0xFFFBC02D) : scheme.onSurface.withOpacity(0.3)))),
        const SizedBox(height: 4),
        Text(c.review, style: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.68))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _openRehireContract(c), child: Text('Rehire', style: AppThemes.poppins(context, fontWeight: FontWeight.w700, color: scheme.onPrimary)))),
      ]),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Your Marketers', style: AppThemes.poppins(context, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  
                  Container(
                    width: 50,
                    child: ElevatedButton(
                      onPressed: _openAddContract,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.person_add_alt_1_rounded, size: 16),
                         
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _insightsCard(context),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = _ContractsTab.active),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: _tab == _ContractsTab.active ? scheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text('Active', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700, color: _tab == _ContractsTab.active ? scheme.onPrimary : scheme.onSurface.withOpacity(0.68)))),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = _ContractsTab.past),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: _tab == _ContractsTab.past ? scheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text('Past', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700, color: _tab == _ContractsTab.past ? scheme.onPrimary : scheme.onSurface.withOpacity(0.68)))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...(_tab == _ContractsTab.active
                  ? _activeContracts.asMap().entries.map((MapEntry<int, _ActiveContract> entry) => _activeCard(context, entry.value, entry.key))
                  : _pastContracts.map((_PastContract c) => _pastCard(context, c))),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightStats {
  const _InsightStats({
    required this.spent,
    required this.revenue,
    required this.net,
    required this.roiPercent,
    required this.orders,
    required this.totalContracts,
    required this.avgConversion,
    required this.expiringSoon,
    required this.atRisk,
    required this.onTrack,
    required this.budgetUsageRatio,
    required this.roas,
    required this.topPerformer,
    required this.topRevenue,
  });

  final double spent;
  final double revenue;
  final double net;
  final double roiPercent;
  final int orders;
  final int totalContracts;
  final double avgConversion;
  final int expiringSoon;
  final int atRisk;
  final int onTrack;
  final double budgetUsageRatio;
  final double roas;
  final String topPerformer;
  final double topRevenue;
}

class _ActiveContract {
  const _ActiveContract({
    required this.marketerId,
    required this.name,
    required this.specialization,
    required this.contractStatus,
    required this.startDate,
    required this.endDate,
    required this.campaignProgress,
    required this.budgetUsed,
    required this.budgetTotal,
    required this.revenue,
    required this.orders,
    required this.conversionRate,
    required this.trendPercent,
    required this.avatarColor,
  });

  final String marketerId;
  final String name;
  final String specialization;
  final String contractStatus;
  final DateTime startDate;
  final DateTime endDate;
  final double campaignProgress;
  final double budgetUsed;
  final double budgetTotal;
  final double revenue;
  final int orders;
  final double conversionRate;
  final double trendPercent;
  final Color avatarColor;
}

class _PastContract {
  const _PastContract({
    required this.marketerId,
    required this.name,
    required this.specialization,
    required this.finalStatus,
    required this.totalRevenue,
    required this.totalOrders,
    required this.finalConversionRate,
    required this.spent,
    required this.rating,
    required this.review,
    required this.avatarColor,
  });

  final String name;
  final String specialization;
  final String finalStatus;
  final double totalRevenue;
  final int totalOrders;
  final double finalConversionRate;
  final double spent;
  final int rating;
  final String review;
  final Color avatarColor;
  final String marketerId;
}
