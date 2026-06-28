import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/earnings.dart';
import 'package:shop_manager/services/earnings_repository.dart';

final earningsRepositoryProvider = Provider<EarningsRepository>((
  ProviderRef<EarningsRepository> ref,
) {
  return FallbackEarningsRepository(
    primary: BackendEarningsRepository(),
    fallback: const MockEarningsRepository(),
  );
});

final earningsQueryProvider = StateProvider<EarningsQuery>((
  StateProviderRef<EarningsQuery> ref,
) {
  return const EarningsQuery();
});

final earningsDashboardProvider = FutureProvider<EarningsDashboard>((
  FutureProviderRef<EarningsDashboard> ref,
) async {
  final EarningsRepository repository = ref.watch(earningsRepositoryProvider);
  final EarningsQuery query = ref.watch(earningsQueryProvider);
  return repository.fetchDashboard(query: query);
});

final payoutsProvider = FutureProvider<PaginatedPayouts>((
  FutureProviderRef<PaginatedPayouts> ref,
) async {
  final EarningsRepository repository = ref.watch(earningsRepositoryProvider);
  return repository.fetchPayouts();
});
