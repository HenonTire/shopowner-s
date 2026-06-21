import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop_manager/models/product.dart';
import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';

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
  BackendProductRepository({
    String? baseUrl,
    this.client,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final http.Client? client;

  @override
  Future<List<Product>> fetchProducts() async {
    final http.Client activeClient = client ?? http.Client();
    try {
      print('═══════════════════════════════════════════════════════');
      print('🟢 FETCH PRODUCTS ATTEMPT');
      print('═══════════════════════════════════════════════════════');

      final String? token = AuthSessionStore.token;
      print('🔑 Token present: ${token != null}');
      if (token != null) {
        print('🔑 Token (first 30 chars): ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
      }

      if (token == null) {
        print('❌ ERROR: No token found, user not authenticated');
        throw Exception('Not authenticated. Please login first.');
      }

      final Uri endpoint = _endpoint('/catalog/products/');
      print('📍 Backend URL: $baseUrl');
      print('📍 Full Endpoint: $endpoint');

      final http.Response response = await activeClient
          .get(
            endpoint,
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      print('✅ Response received from backend');
      print('   Status: ${response.statusCode}');
      print('   Body length: ${response.body.length} bytes');
      if (response.body.length < 1000) {
        print('   Body: ${response.body}');
      } else {
        print('   Body (first 500 chars): ${response.body.substring(0, 500)}...');
      }

      if (response.statusCode == 401) {
        print('❌ ERROR: 401 Unauthorized - session expired');
        throw Exception('Session expired. Please login again.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        print('❌ ERROR: Bad status code ${response.statusCode}');
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);
      print('🔍 Decoded type: ${decoded.runtimeType}');

      List<dynamic> results;
      if (decoded is Map<String, dynamic>) {
        print('🔍 Top-level keys: ${decoded.keys.toList()}');
        results = decoded['results'] ?? [];
        print('🔍 results key found, length: ${results.length}');
      } else if (decoded is List) {
        print('⚠️ Response is a raw List, not a Map with "results" key!');
        results = decoded;
      } else {
        print('❌ ERROR: Unexpected response shape: $decoded');
        results = [];
      }

      final List<Product> products = results
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) => _productFromJson(item))
          .toList();

      print('✅ Parsed ${products.length} products successfully');
      for (final p in products) {
        print('   - ${p.name} (id: ${p.id}, price: ${p.price}, stock: ${p.stock})');
      }

      return products;
    } catch (e, stackTrace) {
      print('❌ FETCH PRODUCTS ERROR:');
      print('   Error: $e');
      print('   Type: ${e.runtimeType}');
      print('   Stack: $stackTrace');
      rethrow;
    } finally {
      if (client == null) {
        activeClient.close();
      }
      print('═══════════════════════════════════════════════════════');
    }
  }

  @override
  Future<Product> createProduct(ProductCreateRequest request) async {
    final http.Client activeClient = client ?? http.Client();
    try {
    print('═══════════════════════════════════════════════════════');
    print('🟡 CREATE PRODUCT ATTEMPT');
    print('═══════════════════════════════════════════════════════');
      final String? token = AuthSessionStore.token;
      print('🔑 Token present: ${token != null}');
      if (token == null) {
        print('❌ ERROR: No token found, user not authenticated');
        throw Exception('Not authenticated. Please login first.');
      }
    

      final http.Response response = await activeClient
          .post(
            _endpoint('/catalog/products/'),
            headers: <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 20));
        print('✅ Response received from backend');
         print('   Status: ${response.statusCode}');
    print('   Body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to create product: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return _productFromJson(data);
    } catch (e) {
      rethrow;
    } finally {
      if (client == null) {
        activeClient.close();
      }
    }
  }

  Uri _endpoint(String path) {
    final String normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl$path');
  }

 Product _productFromJson(Map<String, dynamic> json) {
  String imageUrl = 'https://images.unsplash.com/photo-1561059491-e7a106cc33f2?auto=format&fit=crop&w=400&q=80';

  try {
    final media = json['media'];
    if (media is List && media.isNotEmpty && media[0] is Map) {
      final file = media[0]['file'];
      if (file is String && file.isNotEmpty) {
        imageUrl = file;
      }
    }
  } catch (_) {}

  double parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  return Product(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    imageUrl: imageUrl,
    price: parsePrice(json['price']),
    stock: parseInt(json['stock']) != 0
        ? parseInt(json['stock'])
        : ((() {
            try {
              final variants = json['variants'];
              if (variants is List && variants.isNotEmpty && variants[0] is Map) {
                return parseInt(variants[0]['stock']);
              }
            } catch (_) {}
            return 0;
          })()),
  );
}}