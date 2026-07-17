class ShopAnalyticsTrendPoint {
  const ShopAnalyticsTrendPoint({
    required this.period,
    required this.revenue,
    required this.ordersCount,
    required this.unitsSold,
  });

  final DateTime period;
  final double revenue;
  final int ordersCount;
  final int unitsSold;

  double get averageBasket => ordersCount == 0 ? 0 : revenue / ordersCount;

  factory ShopAnalyticsTrendPoint.fromJson(Map<String, dynamic> json) {
    return ShopAnalyticsTrendPoint(
      period: DateTime.tryParse(json['period']?.toString() ?? '') ?? DateTime.now(),
      revenue: double.tryParse(json['revenue']?.toString() ?? '') ?? 0,
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      unitsSold: (json['units_sold'] as num?)?.toInt() ?? 0,
    );
  }
}