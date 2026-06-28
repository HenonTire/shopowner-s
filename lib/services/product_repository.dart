import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shop_manager/models/product.dart';
import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';



// ─── Variant ──────────────────────────────────────────────────────────────────

class ProductVariantRequest {
  const ProductVariantRequest({
    required this.variantName,
    required this.price,
    this.color,
    this.size,
  });

  final String variantName;
  final double price;
  final String? color;
  final String? size;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'variant_name': variantName,
      'price': price.toStringAsFixed(2),
      'attributes': <String, String>{
        if (color != null && color!.isNotEmpty) 'color': color!,
        if (size != null && size!.isNotEmpty) 'size': size!,
      },
    };
  }
}
// ─── Media ────────────────────────────────────────────────────────────────────

class ProductMediaRequest {
  const ProductMediaRequest({
    required this.bytes,
    required this.fileName,
    this.caption = '',
    this.isPrimary = false,
    this.order = 1,
  });

  final Uint8List bytes;
  final String fileName;
  final String caption;
  final bool isPrimary;
  final int order;
}

// ─── Main request ─────────────────────────────────────────────────────────────

class ProductCreateRequest {
  const ProductCreateRequest({
    required this.name,
    required this.price,
    required this.stock,
    this.description = '',
    this.category = 'General',
    this.weight,
    this.dimensions,
    this.tags = const <String>[],
    this.isActive = true,
    this.variants = const <ProductVariantRequest>[],
    this.media = const <ProductMediaRequest>[],
    // Legacy fields kept for backwards compat
    this.note = '',
    this.featured = false,
    this.trackInventory = true,
    this.discountPercent = 0,
    this.reorderLevel = 5,
    this.imageBytes,
    this.imageFileName,
  });

  final String name;
  final double price;
  final int stock;
  final String description;
  final String category;
  final double? weight;
  final String? dimensions;
  final List<String> tags;
  final bool isActive;
  final List<ProductVariantRequest> variants;
  final List<ProductMediaRequest> media;

  // Legacy
  final String note;
  final bool featured;
  final bool trackInventory;
  final double discountPercent;
  final int reorderLevel;
  final List<int>? imageBytes;
  final String? imageFileName;

  /// JSON body — used when there are NO media files to upload
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'description': description.isNotEmpty ? description : note,
      'price': price.toStringAsFixed(2),
      'stock': stock,
      'category': category,
      if (weight != null) 'weight': weight.toString(),
      if (dimensions != null && dimensions!.isNotEmpty) 'dimensions': dimensions,
      'tags': tags,
      'is_active': isActive,
      'variants': variants.map((ProductVariantRequest v) => v.toJson()).toList(),
    };
  }
}

// ─── Abstract repo ────────────────────────────────────────────────────────────

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
  Future<Product> createProduct(ProductCreateRequest request);
}

// ─── Mock repo ────────────────────────────────────────────────────────────────

class MockProductRepository implements ProductRepository {
  const MockProductRepository();

  @override
  Future<List<Product>> fetchProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return <Product>[];
  }

  @override
  Future<Product> createProduct(ProductCreateRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return Product(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      name: request.name,
      imageUrl: 'https://images.unsplash.com/photo-1561059491-e7a106cc33f2?auto=format&fit=crop&w=400&q=80',
      price: request.price,
      stock: request.stock,
    );
  }
}

// ─── Backend repo ─────────────────────────────────────────────────────────────

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
      if (token == null) throw Exception('Not authenticated. Please login first.');

      final Uri endpoint = _endpoint('/catalog/products/');
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

      print('✅ Status: ${response.statusCode} | Body length: ${response.body.length}');
      if (response.body.length < 1000) print('   Body: ${response.body}');

      if (response.statusCode == 401) throw Exception('Session expired. Please login again.');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);
      List<dynamic> results;
      if (decoded is Map<String, dynamic>) {
        results = decoded['results'] ?? [];
      } else if (decoded is List) {
        results = decoded;
      } else {
        results = [];
      }

      final List<Product> products = results
          .whereType<Map<String, dynamic>>()
          .map(_productFromJson)
          .toList();

      print('✅ Parsed ${products.length} products');
      return products;
    } catch (e, st) {
      print('❌ FETCH PRODUCTS ERROR: $e\n$st');
      rethrow;
    } finally {
      if (client == null) activeClient.close();
      print('═══════════════════════════════════════════════════════');
    }
  }

  @override
  Future<Product> createProduct(ProductCreateRequest request) async {
    final http.Client activeClient = client ?? http.Client();
    try {
      print('═══════════════════════════════════════════════════════');
      print('🟡 CREATE PRODUCT ATTEMPT');

      final String? token = AuthSessionStore.token;
      if (token == null) throw Exception('Not authenticated. Please login first.');

      final Uri endpoint = _endpoint('/catalog/products/');
      print('📍 Endpoint: $endpoint');

      http.Response response;

      // ── Multipart (with images) ──────────────────────────────────────────────
      if (request.media.isNotEmpty || request.imageBytes != null) {
        final http.MultipartRequest multipart =
            http.MultipartRequest('POST', endpoint);

        multipart.headers['Authorization'] = 'Bearer $token';
        multipart.headers['Accept'] = 'application/json';

        // Basic fields
        multipart.fields['name'] = request.name;
        multipart.fields['description'] = request.description.isNotEmpty
            ? request.description
            : request.note;
        multipart.fields['price'] = request.price.toStringAsFixed(2);
        multipart.fields['stock'] = request.stock.toString();
        multipart.fields['category'] = request.category;
        multipart.fields['is_active'] = request.isActive.toString();
        if (request.weight != null) {
          multipart.fields['weight'] = request.weight.toString();
        }
        if (request.dimensions != null && request.dimensions!.isNotEmpty) {
          multipart.fields['dimensions'] = request.dimensions!;
        }
        if (request.tags.isNotEmpty) {
          multipart.fields['tags'] = jsonEncode(request.tags);
        }
        if (request.variants.isNotEmpty) {
          multipart.fields['variants'] = jsonEncode(
            request.variants.map((ProductVariantRequest v) => v.toJson()).toList(),
          );
        }

        // New-style media list
        for (int i = 0; i < request.media.length; i++) {
          final ProductMediaRequest m = request.media[i];
          multipart.files.add(
            http.MultipartFile.fromBytes(
              'media_files',
              m.bytes,
              filename: m.fileName,
            ),
          );
          multipart.fields['media_${i}_caption'] = m.caption;
          multipart.fields['media_${i}_is_primary'] = m.isPrimary.toString();
          multipart.fields['media_${i}_order'] = m.order.toString();
        }

        // Legacy single image fallback
        if (request.media.isEmpty && request.imageBytes != null) {
          multipart.files.add(
            http.MultipartFile.fromBytes(
              'media_files',
              request.imageBytes! is Uint8List
                  ? request.imageBytes! as Uint8List
                  : Uint8List.fromList(request.imageBytes!),
              filename: request.imageFileName ?? 'image.jpg',
            ),
          );
        }

        print('📦 Sending multipart (${multipart.files.length} file(s))');
        final http.StreamedResponse streamed = await multipart.send();
        response = await http.Response.fromStream(streamed);
      }
      // ── JSON (no images) ────────────────────────────────────────────────────
      else {
        final String jsonBody = jsonEncode(request.toJson());
        print('📦 JSON body: $jsonBody');
        response = await activeClient
            .post(
              endpoint,
              headers: <String, String>{
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonBody,
            )
            .timeout(const Duration(seconds: 20));
      }

      print('✅ Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 401) throw Exception('Session expired. Please login again.');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to create product (${response.statusCode}): ${response.body}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      print('✅ Product created: ${data['id']}');
      return _productFromJson(data);
    } catch (e, st) {
      print('❌ CREATE PRODUCT ERROR: $e\n$st');
      rethrow;
    } finally {
      if (client == null) activeClient.close();
      print('═══════════════════════════════════════════════════════');
    }
  }

  Uri _endpoint(String path) {
    final String base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$base$path');
  }
Product _productFromJson(Map<String, dynamic> json) {
  return Product.fromJson(json);
}}