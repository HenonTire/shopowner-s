import 'package:flutter/material.dart';
import 'package:shop_manager/pages/marketer_detail_page.dart';
import 'package:shop_manager/theme/app_themes.dart';

class MarketerChatPage extends StatefulWidget {
  const MarketerChatPage({
    super.key,
    required this.marketerId,
    required this.marketerName,
    required this.specialization,
    required this.avatarColor,
    this.tagline = 'Performance-focused marketer with measurable campaign execution.',
    this.rating = 4.5,
    this.totalOrders = 0,
    this.conversionRate = 0,
    this.revenueGenerated = 'ETB 0',
    this.badgeLabel = 'Marketer',
  });

  final String marketerId;
  final String marketerName;
  final String specialization;
  final Color avatarColor;
  final String tagline;
  final double rating;
  final int totalOrders;
  final double conversionRate;
  final String revenueGenerated;
  final String badgeLabel;

  @override
  State<MarketerChatPage> createState() => _MarketerChatPageState();
}

class _MarketerChatPageState extends State<MarketerChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    _ChatMessage(
      text: 'Hi, I reviewed your shop and I can help improve conversion with better campaign structure.',
      fromMarketer: true,
      sentAt: '09:18',
    ),
    _ChatMessage(
      text: 'Great, I want to hire you on contract. Let us align on weekly goals and budget pacing.',
      fromMarketer: false,
      sentAt: '09:20',
    ),
  ];

  bool _isComposerFocused = false;

  @override
  void initState() {
    super.initState();
    _composerFocusNode.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isComposerFocused = _composerFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _composerFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final String text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          fromMarketer: false,
          sentAt: _nowLabel(),
        ),
      );
      _messageController.clear();
    });
  }

  String _nowLabel() {
    final DateTime now = DateTime.now();
    final String hour = now.hour.toString().padLeft(2, '0');
    final String minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _initials(String name) {
    final List<String> parts = name.split(' ').where((String p) => p.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _openMarketerDetail() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MarketerDetailPage(
          marketerId: widget.marketerId,
          name: widget.marketerName,
          specialization: widget.specialization,
          tagline: widget.tagline,
          rating: widget.rating,
          totalOrders: widget.totalOrders,
          conversionRate: widget.conversionRate,
          revenueGenerated: widget.revenueGenerated,
          avatarColor: widget.avatarColor,
          badgeLabel: widget.badgeLabel,
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
    final Color composerFill = isDark
        ? scheme.primary.withOpacity(0.08)
        : scheme.onPrimary.withOpacity(0.03);
    final Color composerBorder = isDark
        ? scheme.primary.withOpacity(0.24)
        : scheme.onSurface.withOpacity(0.12);
    final Color composerFocusedBorder = scheme.primary.withOpacity(
      isDark ? 0.55 : 0.32,
    );

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
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _openMarketerDetail,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: widget.avatarColor.withOpacity(0.2),
                                child: Text(
                                  _initials(widget.marketerName),
                                  style: AppThemes.poppins(
                                    context,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: widget.avatarColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      widget.marketerName,
                                      style: AppThemes.poppins(context, fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      widget.specialization,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.65)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  itemCount: _messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final _ChatMessage message = _messages[index];
                    final Alignment alignment = message.fromMarketer ? Alignment.centerLeft : Alignment.centerRight;
                    final Color bubbleColor = message.fromMarketer ? scheme.primary : scheme.onPrimary;
                    final Color textColor = message.fromMarketer ? scheme.onPrimary : scheme.onSurface;
                    return Align(
                      alignment: alignment,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        constraints: const BoxConstraints(maxWidth: 280),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.onSurface.withOpacity(message.fromMarketer ? 0.12 : 0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: message.fromMarketer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              message.text,
                              style: AppThemes.poppins(context, fontSize: 12, color: textColor, height: 1.32),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.sentAt,
                              style: AppThemes.poppins(context, fontSize: 9, color: textColor.withOpacity(0.72), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: scheme.onSurface.withOpacity(0.09))),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: composerFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isComposerFocused
                                ? composerFocusedBorder
                                : composerBorder,
                            width: _isComposerFocused ? 1 : 0.6,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _composerFocusNode,
                          cursorColor: scheme.primary,
                          
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            fillColor: scheme.onPrimary.withOpacity(0.03),
                            hintText: 'Type your message',
                            hintStyle: AppThemes.poppins(
                              context,
                              fontSize: 12,
                              color: scheme.onSurface.withOpacity(
                                isDark ? 0.62 : 0.52,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: _isComposerFocused
                                  ? scheme.primary
                                  : scheme.onSurface.withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _sendMessage,
                        child: Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: composerFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: composerBorder,
                              width: 0.6,
                            ),
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            size: 19,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.fromMarketer,
    required this.sentAt,
  });

  final String text;
  final bool fromMarketer;
  final String sentAt;
}
