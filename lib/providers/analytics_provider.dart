import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/providers/shop_analytics_trend.dart';
import 'package:shop_manager/services/shop_analytics_repository.dart';


final shopAnalyticsRepositoryProvider = Provider<ShopAnalyticsRepository>(
  (ProviderRef<ShopAnalyticsRepository> ref) {
    return BackendShopAnalyticsRepository();
  },
);

/// Keyed by a record of (period, limit) — Dart 3 records get structural
/// equality/hashCode for free, so this works directly as a family param.
final shopTrendProvider = FutureProvider.family<
    List<ShopAnalyticsTrendPoint>, ({String period, int limit})>(
  (FutureProviderRef<List<ShopAnalyticsTrendPoint>> ref, ({String period, int limit}) params) async {
    final ShopAnalyticsRepository repository = ref.watch(shopAnalyticsRepositoryProvider);
    return repository.fetchTrend(period: params.period, limit: params.limit);
  },
);