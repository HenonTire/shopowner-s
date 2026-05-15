import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/product.dart';
import 'package:shop_manager/services/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ProviderRef<ProductRepository> ref) {
  // Replace with BackendProductRepository after wiring your API client.
  return const MockProductRepository();
});

final productsProvider = FutureProvider<List<Product>>((FutureProviderRef<List<Product>> ref) async {
  final ProductRepository repository = ref.watch(productRepositoryProvider);
  return repository.fetchProducts();
});
