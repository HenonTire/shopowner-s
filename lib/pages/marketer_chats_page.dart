import 'package:flutter/material.dart';
import 'package:shop_manager/pages/marketer_chat_page.dart';
import 'package:shop_manager/pages/marketer_detail_page.dart';
import 'package:shop_manager/theme/app_themes.dart';

class MarketerChatsPage extends StatelessWidget {
  const MarketerChatsPage({super.key});

  static const List<_ChatThread> _threads = <_ChatThread>[
    _ChatThread(
      marketerId: 'alem-genet',
      marketerName: 'Alem Genet',
      specialization: 'Facebook Ads Expert',
      tagline: 'Scales local campaigns into profitable ad funnels.',
      rating: 4.9,
      totalOrders: 842,
      conversionRate: 5.6,
      revenueGenerated: 'ETB 120,000',
      badgeLabel: 'Top Performer',
      lastMessage: 'I have shared this week\'s ad set performance report.',
      sentAt: '09:45',
      unreadCount: 2,
      avatarColor: Color(0xFF1E88E5),
      online: true,
    ),
    _ChatThread(
      marketerId: 'samuel-taye',
      marketerName: 'Samuel Taye',
      specialization: 'TikTok Growth Strategist',
      tagline: 'Builds short-form campaigns with measurable checkout lift.',
      rating: 4.8,
      totalOrders: 730,
      conversionRate: 5.2,
      revenueGenerated: 'ETB 104,500',
      badgeLabel: 'Top Performer',
      lastMessage: 'Let us test two creatives before we scale budget.',
      sentAt: '08:12',
      unreadCount: 1,
      avatarColor: Color(0xFF43A047),
      online: true,
    ),
    _ChatThread(
      marketerId: 'mimi-haile',
      marketerName: 'Mimi Haile',
      specialization: 'Content Creator',
      tagline: 'Product-first storytelling that improves conversion quality.',
      rating: 4.7,
      totalOrders: 668,
      conversionRate: 4.9,
      revenueGenerated: 'ETB 96,200',
      badgeLabel: 'Top Performer',
      lastMessage: 'Can you review tomorrow\'s posting schedule?',
      sentAt: 'Yesterday',
      unreadCount: 0,
      avatarColor: Color(0xFFF4511E),
      online: false,
    ),
    _ChatThread(
      marketerId: 'nati-birhanu',
      marketerName: 'Nati Birhanu',
      specialization: 'Google Ads Specialist',
      tagline: 'High-intent search strategy for ready-to-buy shoppers.',
      rating: 4.2,
      totalOrders: 391,
      conversionRate: 3.1,
      revenueGenerated: 'ETB 54,900',
      badgeLabel: 'Growing',
      lastMessage: 'Search campaign CPC dropped by 11% this week.',
      sentAt: 'Yesterday',
      unreadCount: 0,
      avatarColor: Color(0xFF8E24AA),
      online: false,
    ),
  ];

  String _initials(String name) {
    final List<String> parts = name
        .split(' ')
        .where((String p) => p.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'M';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  void _openThread(BuildContext context, _ChatThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarketerChatPage(
          marketerId: thread.marketerId,
          marketerName: thread.marketerName,
          specialization: thread.specialization,
          avatarColor: thread.avatarColor,
          tagline: thread.tagline,
          rating: thread.rating,
          totalOrders: thread.totalOrders,
          conversionRate: thread.conversionRate,
          revenueGenerated: thread.revenueGenerated,
          badgeLabel: thread.badgeLabel,
        ),
      ),
    );
  }

  void _openMarketerDetail(BuildContext context, _ChatThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarketerDetailPage(
          marketerId: thread.marketerId,
          name: thread.marketerName,
          specialization: thread.specialization,
          tagline: thread.tagline,
          rating: thread.rating,
          totalOrders: thread.totalOrders,
          conversionRate: thread.conversionRate,
          revenueGenerated: thread.revenueGenerated,
          avatarColor: thread.avatarColor,
          badgeLabel: thread.badgeLabel,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Marketer Chats',
                        style: AppThemes.poppins(
                          context,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                child: Text(
                  'Open a conversation to discuss campaign updates and performance.',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.68),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final _ChatThread thread = _threads[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openThread(context, thread),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: scheme.onSurface.withOpacity(0.1)),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: <Widget>[
                              Stack(
                                clipBehavior: Clip.none,
                                children: <Widget>[
                                  InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () => _openMarketerDetail(context, thread),
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: thread.avatarColor.withOpacity(0.2),
                                      child: Text(
                                        _initials(thread.marketerName),
                                        style: AppThemes.poppins(
                                          context,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: thread.avatarColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (thread.online)
                                    Positioned(
                                      right: -1,
                                      bottom: -1,
                                      child: Container(
                                        width: 11,
                                        height: 11,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF1B8F4D),
                                          border: Border.all(color: scheme.surface, width: 1.6),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(6),
                                            onTap: () => _openMarketerDetail(context, thread),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: Text(
                                                thread.marketerName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppThemes.poppins(
                                                  context,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          thread.sentAt,
                                          style: AppThemes.poppins(
                                            context,
                                            fontSize: 10,
                                            color: scheme.onSurface.withOpacity(0.62),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      thread.specialization,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppThemes.poppins(
                                        context,
                                        fontSize: 11,
                                        color: scheme.onSurface.withOpacity(0.62),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            thread.lastMessage,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppThemes.poppins(
                                              context,
                                              fontSize: 12,
                                              color: scheme.onSurface.withOpacity(0.74),
                                            ),
                                          ),
                                        ),
                                        if (thread.unreadCount > 0) ...<Widget>[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: scheme.primary,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              thread.unreadCount > 99
                                                  ? '99+'
                                                  : '${thread.unreadCount}',
                                              style: AppThemes.poppins(
                                                context,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: scheme.onPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatThread {
  const _ChatThread({
    required this.marketerId,
    required this.marketerName,
    required this.specialization,
    required this.tagline,
    required this.rating,
    required this.totalOrders,
    required this.conversionRate,
    required this.revenueGenerated,
    required this.badgeLabel,
    required this.lastMessage,
    required this.sentAt,
    required this.unreadCount,
    required this.avatarColor,
    required this.online,
  });

  final String marketerId;
  final String marketerName;
  final String specialization;
  final String tagline;
  final double rating;
  final int totalOrders;
  final double conversionRate;
  final String revenueGenerated;
  final String badgeLabel;
  final String lastMessage;
  final String sentAt;
  final int unreadCount;
  final Color avatarColor;
  final bool online;
}
