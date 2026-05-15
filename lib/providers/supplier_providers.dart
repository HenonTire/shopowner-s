import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/supplier_models.dart';
import 'package:shop_manager/services/supplier_repository.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>(
  (ProviderRef<SupplierRepository> ref) {
    return const MockSupplierRepository();
  },
);

final supplierDashboardProvider = FutureProvider<SupplierDashboardData>(
  (FutureProviderRef<SupplierDashboardData> ref) async {
    final SupplierRepository repository = ref.watch(supplierRepositoryProvider);
    return repository.fetchDashboard();
  },
);
