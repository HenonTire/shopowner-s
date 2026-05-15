import 'dart:convert';

import 'package:shop_manager/models/product.dart';

class ProductCreateRequest {
  const ProductCreateRequest({
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.note,
    required this.featured,
    required this.trackInventory,
    required this.discountPercent,
    required this.reorderLevel,
    this.imageBytes,
    this.imageFileName,
  });

  final String name;
  final String category;
  final double price;
  final int stock;
  final String note;
  final bool featured;
  final bool trackInventory;
  final double discountPercent;
  final int reorderLevel;
  final List<int>? imageBytes;
  final String? imageFileName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'note': note,
      'featured': featured,
      'track_inventory': trackInventory,
      'discount_percent': discountPercent,
      'reorder_level': reorderLevel,
      'image_file_name': imageFileName,
      'image_base64': imageBytes == null ? null : base64Encode(imageBytes!),
    };
  }
}

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
  Future<Product> createProduct(ProductCreateRequest request);
}

class MockProductRepository implements ProductRepository {
  const MockProductRepository();

  @override
  Future<List<Product>> fetchProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 550));

    return const <Product>[
      Product(
        id: 'prod-001',
        name: 'Organic Flour 5kg',
        imageUrl:
            'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?auto=format&fit=crop&w=400&q=80',
        price: 1240.00,
        stock: 18,
      ),
      Product(
        id: 'prod-002',
        name: 'Sunflower Oil 3L',
        imageUrl:
            'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80',
        price: 980.00,
        stock: 5,
      ),
      Product(
        id: 'prod-003',
        name: 'Whole Milk 1L',
        imageUrl:
            'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=400&q=80',
        price: 92.50,
        stock: 0,
      ),
      Product(
        id: 'prod-004',
        name: 'Arabica Coffee 500g',
        imageUrl:
            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=400&q=80',
        price: 560.00,
        stock: 12,
      ),
    ];
  }

  @override
  Future<Product> createProduct(ProductCreateRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return Product(
      id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
      name: request.name,
      imageUrl:
          'https://images.unsplash.com/photo-1561059491-e7a106cc33f2?auto=format&fit=crop&w=400&q=80',
      price: request.price,
      stock: request.stock,
    );
  }
}

class BackendProductRepository implements ProductRepository {
  const BackendProductRepository();

  @override
  Future<List<Product>> fetchProducts() {
    throw UnimplementedError(
      'Connect BackendProductRepository.fetchProducts to your API endpoint.',
    );
  }

  @override
  Future<Product> createProduct(ProductCreateRequest request) {
    throw UnimplementedError(
      'Connect BackendProductRepository.createProduct to your API endpoint.',
    );
  }
}
