class SupplierDashboardData {
  const SupplierDashboardData({
    required this.quickStats,
    required this.reorderSuggestions,
    required this.trustedSuppliers,
    required this.orders,
    required this.marketSuppliers,
    required this.activities,
    required this.categoryChips,
    required this.regionChips,
    required this.speedChips,
    required this.ratingChips,
  });

  final List<SupplierQuickStat> quickStats;
  final List<SupplierReorderSuggestion> reorderSuggestions;
  final List<SupplierTrustedItem> trustedSuppliers;
  final List<SupplierOrder> orders;
  final List<SupplierMarketItem> marketSuppliers;
  final List<SupplierActivityItem> activities;
  final List<String> categoryChips;
  final List<String> regionChips;
  final List<String> speedChips;
  final List<String> ratingChips;

  factory SupplierDashboardData.fromJson(Map<String, dynamic> json) {
    return SupplierDashboardData(
      quickStats: _parseList(
        json['quick_stats'] as List<dynamic>?,
        (Map<String, dynamic> item) => SupplierQuickStat.fromJson(item),
      ),
      reorderSuggestions: _parseList(
        json['reorder_suggestions'] as List<dynamic>?,
        (Map<String, dynamic> item) => SupplierReorderSuggestion.fromJson(item),
      ),
      trustedSuppliers: _parseList(
        json['trusted_suppliers'] as List<dynamic>?,
        (Map<String, dynamic> item) => SupplierTrustedItem.fromJson(item),
      ),
      orders: _parseList(
        json['orders'] as List<dynamic>?,
        (Map<String, dynamic> item) => SupplierOrder.fromJson(item),
      ),
      marketSuppliers: _parseList(
        json['market_suppliers'] as List<dynamic>?,
        (Map<String, dynamic> item) => SupplierMarketItem.fromJson(item),
      ),
      activities: _parseList(
        json['activities'] as List<dynamic>?,
        (Map<String, dynamic> item) => SupplierActivityItem.fromJson(item),
      ),
      categoryChips: _stringList(json['category_chips'] as List<dynamic>?),
      regionChips: _stringList(json['region_chips'] as List<dynamic>?),
      speedChips: _stringList(json['speed_chips'] as List<dynamic>?),
      ratingChips: _stringList(json['rating_chips'] as List<dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'quick_stats': quickStats
          .map((SupplierQuickStat stat) => stat.toJson())
          .toList(growable: false),
      'reorder_suggestions': reorderSuggestions
          .map((SupplierReorderSuggestion item) => item.toJson())
          .toList(growable: false),
      'trusted_suppliers': trustedSuppliers
          .map((SupplierTrustedItem item) => item.toJson())
          .toList(growable: false),
      'orders': orders
          .map((SupplierOrder item) => item.toJson())
          .toList(growable: false),
      'market_suppliers': marketSuppliers
          .map((SupplierMarketItem item) => item.toJson())
          .toList(growable: false),
      'activities': activities
          .map((SupplierActivityItem item) => item.toJson())
          .toList(growable: false),
      'category_chips': categoryChips,
      'region_chips': regionChips,
      'speed_chips': speedChips,
      'rating_chips': ratingChips,
    };
  }
}

class SupplierQuickStat {
  const SupplierQuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.trend,
  });

  final String label;
  final String value;
  final String icon;
  final String trend;

  factory SupplierQuickStat.fromJson(Map<String, dynamic> json) {
    return SupplierQuickStat(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      icon: json['icon'] as String? ?? 'insights',
      trend: json['trend'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'label': label,
      'value': value,
      'icon': icon,
      'trend': trend,
    };
  }
}

class SupplierReorderSuggestion {
  const SupplierReorderSuggestion({
    required this.product,
    required this.currentStock,
    required this.reorderQty,
    required this.supplier,
    required this.unitPrice,
    required this.eta,
    required this.urgency,
  });

  final String product;
  final int currentStock;
  final int reorderQty;
  final String supplier;
  final double unitPrice;
  final String eta;
  final String urgency;

  factory SupplierReorderSuggestion.fromJson(Map<String, dynamic> json) {
    return SupplierReorderSuggestion(
      product: json['product'] as String? ?? '',
      currentStock: (json['current_stock'] as num?)?.toInt() ?? 0,
      reorderQty: (json['reorder_qty'] as num?)?.toInt() ?? 0,
      supplier: json['supplier'] as String? ?? '',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      eta: json['eta'] as String? ?? '',
      urgency: json['urgency'] as String? ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'product': product,
      'current_stock': currentStock,
      'reorder_qty': reorderQty,
      'supplier': supplier,
      'unit_price': unitPrice,
      'eta': eta,
      'urgency': urgency,
    };
  }
}

class SupplierTrustedItem {
  const SupplierTrustedItem({
    required this.name,
    required this.rating,
    required this.speed,
    required this.categories,
    required this.lastInteraction,
    required this.verified,
    required this.avatarColor,
  });

  final String name;
  final double rating;
  final String speed;
  final String categories;
  final String lastInteraction;
  final bool verified;
  final String avatarColor;

  factory SupplierTrustedItem.fromJson(Map<String, dynamic> json) {
    return SupplierTrustedItem(
      name: json['name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      speed: json['speed'] as String? ?? '',
      categories: json['categories'] as String? ?? '',
      lastInteraction: json['last_interaction'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      avatarColor: json['avatar_color'] as String? ?? '#1E88E5',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'rating': rating,
      'speed': speed,
      'categories': categories,
      'last_interaction': lastInteraction,
      'verified': verified,
      'avatar_color': avatarColor,
    };
  }
}

class SupplierOrder {
  const SupplierOrder({
    required this.id,
    required this.supplier,
    required this.productCount,
    required this.amount,
    required this.orderDate,
    required this.eta,
    required this.status,
  });

  final String id;
  final String supplier;
  final int productCount;
  final String amount;
  final String orderDate;
  final String eta;
  final String status;

  factory SupplierOrder.fromJson(Map<String, dynamic> json) {
    return SupplierOrder(
      id: json['id'] as String? ?? '',
      supplier: json['supplier'] as String? ?? '',
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
      amount: json['amount'] as String? ?? '',
      orderDate: json['order_date'] as String? ?? '',
      eta: json['eta'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'supplier': supplier,
      'product_count': productCount,
      'amount': amount,
      'order_date': orderDate,
      'eta': eta,
      'status': status,
    };
  }
}

class SupplierMarketItem {
  const SupplierMarketItem({
    required this.name,
    required this.specialties,
    required this.startPrice,
    required this.region,
    required this.delivery,
    required this.rating,
    required this.verified,
    required this.avatarColor,
  });

  final String name;
  final String specialties;
  final String startPrice;
  final String region;
  final String delivery;
  final double rating;
  final bool verified;
  final String avatarColor;

  factory SupplierMarketItem.fromJson(Map<String, dynamic> json) {
    return SupplierMarketItem(
      name: json['name'] as String? ?? '',
      specialties: json['specialties'] as String? ?? '',
      startPrice: json['start_price'] as String? ?? '',
      region: json['region'] as String? ?? '',
      delivery: json['delivery'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      verified: json['verified'] as bool? ?? false,
      avatarColor: json['avatar_color'] as String? ?? '#1E88E5',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'specialties': specialties,
      'start_price': startPrice,
      'region': region,
      'delivery': delivery,
      'rating': rating,
      'verified': verified,
      'avatar_color': avatarColor,
    };
  }
}

class SupplierActivityItem {
  const SupplierActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String time;
  final String icon;
  final String color;

  factory SupplierActivityItem.fromJson(Map<String, dynamic> json) {
    return SupplierActivityItem(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      time: json['time'] as String? ?? '',
      icon: json['icon'] as String? ?? 'history',
      color: json['color'] as String? ?? '#1E88E5',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'subtitle': subtitle,
      'time': time,
      'icon': icon,
      'color': color,
    };
  }
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

List<String> _stringList(List<dynamic>? raw) {
  return (raw ?? <dynamic>[])
      .map((dynamic item) => item.toString())
      .toList(growable: false);
}
