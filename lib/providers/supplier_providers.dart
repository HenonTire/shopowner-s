import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/supplier_models.dart';
import 'package:shop_manager/services/supplier_repository.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return BackendSupplierRepository();
});

final supplierDashboardProvider =
    FutureProvider<SupplierDashboardData>((ref) async {
  final SupplierRepository repo = ref.watch(supplierRepositoryProvider);
  return repo.fetchDashboard();
});