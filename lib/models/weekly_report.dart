class WeeklyReportPoint {
  const WeeklyReportPoint({
    required this.dayLabel,
    required this.sales,
    required this.orders,
  });

  final String dayLabel;
  final double sales;
  final int orders;

  double get averageBasket => orders == 0 ? 0 : sales / orders;

  factory WeeklyReportPoint.fromJson(Map<String, dynamic> json) {
    return WeeklyReportPoint(
      dayLabel: json['day_label'] as String? ?? '',
      sales: (json['sales'] as num?)?.toDouble() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'day_label': dayLabel,
      'sales': sales,
      'orders': orders,
    };
  }
}

class WeeklyReport {
  const WeeklyReport({
    required this.points,
    required this.generatedAt,
    required this.growthRate,
  });

  final List<WeeklyReportPoint> points;
  final DateTime generatedAt;
  final double growthRate;

  double get totalSales => points.fold<double>(0, (sum, point) => sum + point.sales);
  int get totalOrders => points.fold<int>(0, (sum, point) => sum + point.orders);
  double get averageBasket => totalOrders == 0 ? 0 : totalSales / totalOrders;

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    final List<dynamic> pointsJson = json['points'] as List<dynamic>? ?? <dynamic>[];
    return WeeklyReport(
      points: pointsJson
          .map((dynamic item) => WeeklyReportPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? '') ?? DateTime.now(),
      growthRate: (json['growth_rate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'points': points.map((WeeklyReportPoint point) => point.toJson()).toList(),
      'generated_at': generatedAt.toIso8601String(),
      'growth_rate': growthRate,
    };
  }
}
