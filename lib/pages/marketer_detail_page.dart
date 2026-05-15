import 'package:flutter/material.dart';
import 'package:shop_manager/pages/add_marketer_contract_page.dart';
import 'package:shop_manager/pages/marketer_chat_page.dart';
import 'package:shop_manager/theme/app_themes.dart';

class MarketerDetailPage extends StatefulWidget {
  const MarketerDetailPage({
    super.key,
    required this.marketerId,
    required this.name,
    required this.specialization,
    required this.tagline,
    required this.rating,
    required this.totalOrders,
    required this.conversionRate,
    required this.revenueGenerated,
    required this.avatarColor,
    required this.badgeLabel,
  });

  final String marketerId;
  final String name;
  final String specialization;
  final String tagline;
  final double rating;
  final int totalOrders;
  final double conversionRate;
  final String revenueGenerated;
  final Color avatarColor;
  final String badgeLabel;

  @override
  State<MarketerDetailPage> createState() => _MarketerDetailPageState();
}

class _MarketerDetailPageState extends State<MarketerDetailPage> {
  Future<void> _openChat() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MarketerChatPage(
          marketerId: widget.marketerId,
          marketerName: widget.name,
          specialization: widget.specialization,
          avatarColor: widget.avatarColor,
          tagline: widget.tagline,
          rating: widget.rating,
          totalOrders: widget.totalOrders,
          conversionRate: widget.conversionRate,
          revenueGenerated: widget.revenueGenerated,
          badgeLabel: widget.badgeLabel,
        ),
      ),
    );
  }

  Future<void> _hireWithContract() async {
    final MarketerContractDraft? draft = await Navigator.of(context).push<MarketerContractDraft>(
      MaterialPageRoute<MarketerContractDraft>(
        builder: (_) => AddMarketerContractPage(
          initialName: widget.name,
          initialSpecialization: widget.specialization,
          initialChannel: _channelFromSpecialization(widget.specialization),
        ),
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Contract with ${widget.name} is created. Start planning in chat.',
          style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );

    await _openChat();
  }

  String _channelFromSpecialization(String specialization) {
    final String text = specialization.toLowerCase();
    if (text.contains('facebook')) return 'Facebook Ads';
    if (text.contains('tiktok')) return 'TikTok';
    if (text.contains('google')) return 'Google Ads';
    if (text.contains('email')) return 'Email';
    return 'Marketplace';
  }

  String _initials(String name) {
    final List<String> parts = name.split(' ').where((String p) => p.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Marketer Profile',
                      style: AppThemes.poppins(context, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: widget.avatarColor.withOpacity(0.18),
                          child: Text(
                            _initials(widget.name),
                            style: AppThemes.poppins(
                              context,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: widget.avatarColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.name,
                                style: AppThemes.poppins(context, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.specialization,
                                style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.68)),
                              ),
                              const SizedBox(height: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  widget.badgeLabel,
                                  style: AppThemes.poppins(
                                    context,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.tagline,
                      style: AppThemes.poppins(context, fontSize: 12, color: scheme.onSurface.withOpacity(0.72), height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _StatTile(
                            label: 'Rating',
                            value: widget.rating.toStringAsFixed(1),
                            valueColor: const Color(0xFFFBC02D),
                            icon: Icons.star_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            label: 'Orders',
                            value: widget.totalOrders.toString(),
                            valueColor: scheme.onSurface,
                            icon: Icons.shopping_bag_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _StatTile(
                            label: 'Conversion',
                            value: '${widget.conversionRate.toStringAsFixed(1)}%',
                            valueColor: widget.conversionRate >= 4 ? const Color(0xFF1B8F4D) : const Color(0xFFC62828),
                            icon: Icons.trending_up_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            label: 'Revenue',
                            value: widget.revenueGenerated,
                            valueColor: const Color(0xFF1B8F4D),
                            icon: Icons.payments_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Collaboration Flow',
                      style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Review profile and expected outcomes\n2. Hire with contract terms and timeline\n3. Use chat for day-to-day campaign updates',
                      style: AppThemes.poppins(context, fontSize: 11, height: 1.45, color: scheme.onSurface.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _hireWithContract,
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: Text(
                  'Hire',
                  style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onPrimary),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                label: Text(
                  'Open Chat',
                  style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
  });

  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: <Widget>[
              Icon(icon, size: 14, color: scheme.onSurface.withOpacity(0.58)),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppThemes.poppins(context, fontSize: 10, color: scheme.onSurface.withOpacity(0.62), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700, color: valueColor),
          ),
        ],
      ),
    );
  }
}
