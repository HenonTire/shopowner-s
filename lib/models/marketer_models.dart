import 'package:flutter/material.dart';

class MarketerSummary {
  const MarketerSummary({
    required this.id,
    required this.name,
    required this.specialization,
    required this.tagline,
    required this.rating,
    required this.totalOrders,
    required this.conversionRate,
    required this.revenueGenerated,
    required this.badgeLabel,
    required this.avatarColorHex,
  });

  final String id;
  final String name;
  final String specialization;
  final String tagline;
  final double rating;
  final int totalOrders;
  final double conversionRate;
  final String revenueGenerated;
  final String badgeLabel;
  final String avatarColorHex;

  Color get avatarColor => colorFromHex(avatarColorHex);

  String get initials {
    final List<String> parts = name
        .split(' ')
        .where((String p) => p.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'M';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  factory MarketerSummary.fromJson(Map<String, dynamic> json) {
    return MarketerSummary(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0,
      revenueGenerated: json['revenue_generated'] as String? ?? 'ETB 0',
      badgeLabel: json['badge_label'] as String? ?? 'Marketer',
      avatarColorHex: json['avatar_color'] as String? ?? '#1E88E5',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'specialization': specialization,
      'tagline': tagline,
      'rating': rating,
      'total_orders': totalOrders,
      'conversion_rate': conversionRate,
      'revenue_generated': revenueGenerated,
      'badge_label': badgeLabel,
      'avatar_color': avatarColorHex,
    };
  }
}

class MarketerChatThread {
  const MarketerChatThread({
    required this.marketer,
    required this.lastMessage,
    required this.sentAt,
    required this.unreadCount,
    required this.online,
  });

  final MarketerSummary marketer;
  final String lastMessage;
  final String sentAt;
  final int unreadCount;
  final bool online;

  factory MarketerChatThread.fromJson(Map<String, dynamic> json) {
    return MarketerChatThread(
      marketer: MarketerSummary.fromJson(
        json['marketer'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      lastMessage: json['last_message'] as String? ?? '',
      sentAt: json['sent_at'] as String? ?? '',
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      online: json['online'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'marketer': marketer.toJson(),
      'last_message': lastMessage,
      'sent_at': sentAt,
      'unread_count': unreadCount,
      'online': online,
    };
  }
}

class MarketerChatMessage {
  const MarketerChatMessage({
    required this.id,
    required this.marketerId,
    required this.text,
    required this.fromMarketer,
    required this.sentAt,
  });

  final String id;
  final String marketerId;
  final String text;
  final bool fromMarketer;
  final String sentAt;

  factory MarketerChatMessage.fromJson(Map<String, dynamic> json) {
    return MarketerChatMessage(
      id: json['id']?.toString() ?? '',
      marketerId: json['marketer_id']?.toString() ?? '',
      text: json['text'] as String? ?? '',
      fromMarketer: json['from_marketer'] as bool? ?? false,
      sentAt: json['sent_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'marketer_id': marketerId,
      'text': text,
      'from_marketer': fromMarketer,
      'sent_at': sentAt,
    };
  }
}

class ActiveMarketerContract {
  const ActiveMarketerContract({
    required this.id,
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
    required this.avatarColorHex,
  });

  final String id;
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
  final String avatarColorHex;

  Color get avatarColor => colorFromHex(avatarColorHex);

  factory ActiveMarketerContract.fromJson(Map<String, dynamic> json) {
    return ActiveMarketerContract(
      id: json['id']?.toString() ?? '',
      marketerId: json['marketer_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      contractStatus: json['contract_status'] as String? ?? 'Pending',
      startDate: DateTime.tryParse(json['start_date'] as String? ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['end_date'] as String? ?? '') ?? DateTime.now(),
      campaignProgress: (json['campaign_progress'] as num?)?.toDouble() ?? 0,
      budgetUsed: (json['budget_used'] as num?)?.toDouble() ?? 0,
      budgetTotal: (json['budget_total'] as num?)?.toDouble() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0,
      trendPercent: (json['trend_percent'] as num?)?.toDouble() ?? 0,
      avatarColorHex: json['avatar_color'] as String? ?? '#1E88E5',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'marketer_id': marketerId,
      'name': name,
      'specialization': specialization,
      'contract_status': contractStatus,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'campaign_progress': campaignProgress,
      'budget_used': budgetUsed,
      'budget_total': budgetTotal,
      'revenue': revenue,
      'orders': orders,
      'conversion_rate': conversionRate,
      'trend_percent': trendPercent,
      'avatar_color': avatarColorHex,
    };
  }
}

class PastMarketerContract {
  const PastMarketerContract({
    required this.id,
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
    required this.avatarColorHex,
  });

  final String id;
  final String marketerId;
  final String name;
  final String specialization;
  final String finalStatus;
  final double totalRevenue;
  final int totalOrders;
  final double finalConversionRate;
  final double spent;
  final int rating;
  final String review;
  final String avatarColorHex;

  Color get avatarColor => colorFromHex(avatarColorHex);

  factory PastMarketerContract.fromJson(Map<String, dynamic> json) {
    return PastMarketerContract(
      id: json['id']?.toString() ?? '',
      marketerId: json['marketer_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      finalStatus: json['final_status'] as String? ?? 'Completed',
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      finalConversionRate:
          (json['final_conversion_rate'] as num?)?.toDouble() ?? 0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      review: json['review'] as String? ?? '',
      avatarColorHex: json['avatar_color'] as String? ?? '#1E88E5',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'marketer_id': marketerId,
      'name': name,
      'specialization': specialization,
      'final_status': finalStatus,
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'final_conversion_rate': finalConversionRate,
      'spent': spent,
      'rating': rating,
      'review': review,
      'avatar_color': avatarColorHex,
    };
  }
}

class MarketerOverviewData {
  const MarketerOverviewData({
    required this.topPerformers,
    required this.allMarketers,
    required this.chatThreads,
    required this.activeContracts,
    required this.pastContracts,
  });

  final List<MarketerSummary> topPerformers;
  final List<MarketerSummary> allMarketers;
  final List<MarketerChatThread> chatThreads;
  final List<ActiveMarketerContract> activeContracts;
  final List<PastMarketerContract> pastContracts;

  int get unreadChats => chatThreads.fold<int>(
        0,
        (int sum, MarketerChatThread thread) => sum + thread.unreadCount,
      );

  factory MarketerOverviewData.fromJson(Map<String, dynamic> json) {
    return MarketerOverviewData(
      topPerformers: _parseList(
        json['top_performers'] as List<dynamic>?,
        (Map<String, dynamic> item) => MarketerSummary.fromJson(item),
      ),
      allMarketers: _parseList(
        json['all_marketers'] as List<dynamic>?,
        (Map<String, dynamic> item) => MarketerSummary.fromJson(item),
      ),
      chatThreads: _parseList(
        json['chat_threads'] as List<dynamic>?,
        (Map<String, dynamic> item) => MarketerChatThread.fromJson(item),
      ),
      activeContracts: _parseList(
        json['active_contracts'] as List<dynamic>?,
        (Map<String, dynamic> item) => ActiveMarketerContract.fromJson(item),
      ),
      pastContracts: _parseList(
        json['past_contracts'] as List<dynamic>?,
        (Map<String, dynamic> item) => PastMarketerContract.fromJson(item),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'top_performers': topPerformers
          .map((MarketerSummary marketer) => marketer.toJson())
          .toList(growable: false),
      'all_marketers': allMarketers
          .map((MarketerSummary marketer) => marketer.toJson())
          .toList(growable: false),
      'chat_threads': chatThreads
          .map((MarketerChatThread thread) => thread.toJson())
          .toList(growable: false),
      'active_contracts': activeContracts
          .map((ActiveMarketerContract contract) => contract.toJson())
          .toList(growable: false),
      'past_contracts': pastContracts
          .map((PastMarketerContract contract) => contract.toJson())
          .toList(growable: false),
    };
  }
}

class CreateMarketerContractRequest {
  const CreateMarketerContractRequest({
    required this.marketerId,
    required this.name,
    required this.specialization,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.budgetTotal,
    required this.initialProgress,
    required this.conversionTarget,
    required this.channel,
    required this.goals,
  });

  final String marketerId;
  final String name;
  final String specialization;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final double budgetTotal;
  final double initialProgress;
  final double conversionTarget;
  final String channel;
  final List<String> goals;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'marketer_id': marketerId,
      'name': name,
      'specialization': specialization,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'budget_total': budgetTotal,
      'initial_progress': initialProgress,
      'conversion_target': conversionTarget,
      'channel': channel,
      'goals': goals,
    };
  }
}

String normalizeMarketerId(String value) {
  return value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

Color colorFromHex(String hex) {
  final String normalized = hex.replaceFirst('#', '');
  if (normalized.length == 6) {
    return Color(int.parse('0xFF$normalized'));
  }
  if (normalized.length == 8) {
    return Color(int.parse('0x$normalized'));
  }
  return const Color(0xFF1E88E5);
}

List<T> _parseList<T>(
  List<dynamic>? raw,
  T Function(Map<String, dynamic> item) parser,
) {
  return (raw ?? <dynamic>[])
      .whereType<Map<String, dynamic>>()
      .map<T>(parser)
      .toList(growable: false);
}
