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
  Future<void> deleteProduct(String productId);
  Future<Product> updateProduct(String productId, ProductCreateRequest request);
  Future<Product> restockProduct(
    String productId, {
    String? variantId,
    required int quantity,
    String reason,
  });
  Future<List<Product>> fetchSupplierProducts(String supplierId);
  Future<Map<String, dynamic>> importSupplierProduct(
    String productId, {
    double? price,
  });
}

// ─── Mock repo ────────────────────────────────────────────────────────────────

// class MockProductRepository implements ProductRepository {
//   const MockProductRepository();

//   @override
//   @override
//   Future<void> deleteProduct(String productId) async {
//     await Future<void>.delayed(const Duration(milliseconds: 300));
//   }
//   Future<List<Product>> fetchProducts() async {
//     await Future<void>.delayed(const Duration(milliseconds: 450));
//     return <Product>[];
//   }
//  @override
// Future<Product> restockProduct(
//   String productId, {
//   String? variantId,
//   required int quantity,
//   String reason = 'Restock',
// }) async {
//   await Future<void>.delayed(const Duration(milliseconds: 300));
//   return Product(id: productId, name: 'Mock', imageUrl: '', price: 0, stock: quantity);
// }
//  @override
//   Future<Product> updateProduct(String productId, ProductCreateRequest request) async {
//     await Future<void>.delayed(const Duration(milliseconds: 400));
//     return Product(
//       id: productId,
//       name: request.name,
//       imageUrl: '',
//       price: request.price,
//       stock: request.stock,
//     );
//   }
//   @override
//   Future<Product> createProduct(ProductCreateRequest request) async {
//     await Future<void>.delayed(const Duration(milliseconds: 450));
//     return Product(
//       id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
//       name: request.name,
//       imageUrl: 'https://images.unsplash.com/photo-1561059491-e7a106cc33f2?auto=format&fit=crop&w=400&q=80',
//       price: request.price,
//       stock: request.stock,
//     );
//   }
// }

// ─── Backend repo ─────────────────────────────────────────────────────────────

class BackendProductRepository implements ProductRepository {
  BackendProductRepository({
    String? baseUrl,
    this.client,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final http.Client? client;
  @override
Future<Product> restockProduct(
  String productId, {
  String? variantId,
  required int quantity,
  String reason = 'Restock',
}) async {
  final http.Client activeClient = client ?? http.Client();
  try {
    print('═══════════════════════════════════════════════════════');
    print('🟢 RESTOCK PRODUCT ATTEMPT: $productId');

    final String? token = AuthSessionStore.token;
    if (token == null) throw Exception('Not authenticated. Please login first.');

    final Uri endpoint = _endpoint('/inventory/products/$productId/restock/');
    final Map<String, dynamic> body = <String, dynamic>{
      'quantity': quantity,
      if (variantId != null) 'variant_id': variantId,
      'reason': reason,
    };

    final http.Response response = await activeClient
        .post(
          endpoint,
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    print('✅ Status: ${response.statusCode} | Body: ${response.body}');

    if (response.statusCode == 401) throw Exception('Session expired. Please login again.');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to restock product (${response.statusCode}): ${response.body}');
    }

    return _productFromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } catch (e, st) {
    print('❌ RESTOCK PRODUCT ERROR: $e\n$st');
    rethrow;
  } finally {
    if (client == null) activeClient.close();
    print('═══════════════════════════════════════════════════════');
  }
}
@override
Future<List<Product>> fetchSupplierProducts(String supplierId) async {
  final http.Client activeClient = client ?? http.Client();
  try {
    final String? token = AuthSessionStore.token;
    if (token == null) throw Exception('Not authenticated. Please login first.');

    final Uri endpoint = _endpoint('/catalog/suppliers/$supplierId/products/');
    final http.Response response = await activeClient
        .get(
          endpoint,
          headers: <String, String>{
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401) throw Exception('Session expired. Please login again.');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch supplier products (${response.statusCode}): ${response.body}');
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> results = decoded is Map<String, dynamic>
        ? (decoded['results'] ?? [])
        : (decoded is List ? decoded : []);

    return results
        .whereType<Map<String, dynamic>>()
        .map(_productFromJson)
        .toList();
  } finally {
    if (client == null) activeClient.close();
  }
}

@override
Future<Map<String, dynamic>> importSupplierProduct(
  String productId, {
  double? price,
}) async {
  final http.Client activeClient = client ?? http.Client();
  try {
    final String? token = AuthSessionStore.token;
    if (token == null) throw Exception('Not authenticated. Please login first.');

    final Uri endpoint = _endpoint('/catalog/products/$productId/import/');
    final Map<String, dynamic> body = <String, dynamic>{
      if (price != null) 'price': price.toStringAsFixed(2),
    };

    final http.Response response = await activeClient
        .post(
          endpoint,
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401) throw Exception('Session expired. Please login again.');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to import product (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  } finally {
    if (client == null) activeClient.close();
  }
}
  @override
  Future<List<Product>> fetchProducts() async {
    final http.Client activeClient = client ?? http.Client();
    try {
      print('═══════════════════════════════════════════════════════');
      print('🟢 FETCH PRODUCTS ATTEMPT');
      print('═══════════════════════════════════════════════════════');

      final String? token = AuthSessionStore.token;
      if (token == null) throw Exception('Not authenticated. Please login first.');

      final Uri endpoint = _endpoint('/catalog/products/mine/');
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
  Future<void> deleteProduct(String productId) async {
    final http.Client activeClient = client ?? http.Client();
    try {
      print('═══════════════════════════════════════════════════════');
      print('🔴 DELETE PRODUCT ATTEMPT: $productId');

      final String? token = AuthSessionStore.token;
      if (token == null) throw Exception('Not authenticated. Please login first.');

      final Uri endpoint = _endpoint('/catalog/products/$productId/');
      print('📍 Endpoint: $endpoint');

      final http.Response response = await activeClient
          .delete(
            endpoint,
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      print('✅ Status: ${response.statusCode}');

      if (response.statusCode == 401) throw Exception('Session expired. Please login again.');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to delete product (${response.statusCode}): ${response.body}');
      }

      print('✅ Product deleted: $productId');
    } catch (e, st) {
      print('❌ DELETE PRODUCT ERROR: $e\n$st');
      rethrow;
    } finally {
      if (client == null) activeClient.close();
      print('═══════════════════════════════════════════════════════');
    }
  }

  @override
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

    // ── Step 1: create the product as plain JSON (no files) ──────────────────
    final String jsonBody = jsonEncode(request.toJson());
    print('📦 JSON body: $jsonBody');

    final http.Response response = await activeClient
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

    print('✅ Status: ${response.statusCode}');
    print('   Body: ${response.body}');

    if (response.statusCode == 401) throw Exception('Session expired. Please login again.');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create product (${response.statusCode}): ${response.body}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final String productId = data['id'].toString();
    print('✅ Product created: $productId');

    // ── Step 2: upload each media file separately ─────────────────────────────
    final List<ProductMediaRequest> mediaToUpload = request.media.isNotEmpty
        ? request.media
        : (request.imageBytes != null
            ? <ProductMediaRequest>[
                ProductMediaRequest(
                  bytes: request.imageBytes is Uint8List
                      ? request.imageBytes! as Uint8List
                      : Uint8List.fromList(request.imageBytes!),
                  fileName: request.imageFileName ?? 'image.jpg',
                  isPrimary: true,
                )
              ]
            : const <ProductMediaRequest>[]);

    final List<Map<String, dynamic>> uploadedMedia = <Map<String, dynamic>>[];
    final List<String> mediaErrors = <String>[];

    for (final ProductMediaRequest m in mediaToUpload) {
      try {
        final Uri mediaEndpoint = _endpoint('/catalog/products/$productId/media/');
        final http.MultipartRequest mediaRequest =
            http.MultipartRequest('POST', mediaEndpoint);

        mediaRequest.headers['Authorization'] = 'Bearer $token';
        mediaRequest.headers['Accept'] = 'application/json';

        mediaRequest.fields['media_type'] = 'IMAGE';
        mediaRequest.fields['caption'] = m.caption;
        mediaRequest.fields['is_primary'] = m.isPrimary.toString();
        mediaRequest.fields['order'] = m.order.toString();

        mediaRequest.files.add(
          http.MultipartFile.fromBytes('file', m.bytes, filename: m.fileName),
        );

        print('📦 Uploading media: ${m.fileName}');
        final http.StreamedResponse mediaStreamed = await mediaRequest.send();
        final http.Response mediaResponse =
            await http.Response.fromStream(mediaStreamed);

        print('   Media status: ${mediaResponse.statusCode} | Body: ${mediaResponse.body}');

        if (mediaResponse.statusCode >= 200 && mediaResponse.statusCode < 300) {
          uploadedMedia.add(jsonDecode(mediaResponse.body) as Map<String, dynamic>);
        } else {
          mediaErrors.add('${m.fileName}: ${mediaResponse.statusCode}');
        }
      } catch (e) {
        print('❌ MEDIA UPLOAD ERROR for ${m.fileName}: $e');
        mediaErrors.add('${m.fileName}: $e');
      }
    }

    if (mediaErrors.isNotEmpty) {
      print('⚠️ Some media failed to upload: $mediaErrors');
    }

    // Merge uploaded media into the product JSON so Product.fromJson picks up imageUrl
    data['media'] = uploadedMedia;

    return _productFromJson(data);
  } catch (e, st) {
    print('❌ CREATE PRODUCT ERROR: $e\n$st');
    rethrow;
  } finally {
    if (client == null) activeClient.close();
    print('═══════════════════════════════════════════════════════');
  }
}
@override
  Future<Product> updateProduct(String productId, ProductCreateRequest request) async {
    final http.Client activeClient = client ?? http.Client();
    try {
      print('═══════════════════════════════════════════════════════');
      print('🟠 UPDATE PRODUCT ATTEMPT: $productId');

      final String? token = AuthSessionStore.token;
      if (token == null) throw Exception('Not authenticated. Please login first.');

      final Uri endpoint = _endpoint('/catalog/products/$productId/');
      print('📍 Endpoint: $endpoint');

      final String jsonBody = jsonEncode(request.toJson());
      print('📦 JSON body: $jsonBody');

      final http.Response response = await activeClient
          .patch(
            endpoint,
            headers: <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonBody,
          )
          .timeout(const Duration(seconds: 20));

      print('✅ Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 401) throw Exception('Session expired. Please login again.');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to update product (${response.statusCode}): ${response.body}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      // Upload any newly added media files.
      final List<Map<String, dynamic>> uploadedMedia = <Map<String, dynamic>>[];
      for (final ProductMediaRequest m in request.media) {
        try {
          final Uri mediaEndpoint = _endpoint('/catalog/products/$productId/media/');
          final http.MultipartRequest mediaRequest =
              http.MultipartRequest('POST', mediaEndpoint);
          mediaRequest.headers['Authorization'] = 'Bearer $token';
          mediaRequest.headers['Accept'] = 'application/json';
          mediaRequest.fields['media_type'] = 'IMAGE';
          mediaRequest.fields['caption'] = m.caption;
          mediaRequest.fields['is_primary'] = m.isPrimary.toString();
          mediaRequest.fields['order'] = m.order.toString();
          mediaRequest.files.add(
            http.MultipartFile.fromBytes('file', m.bytes, filename: m.fileName),
          );

          final http.StreamedResponse mediaStreamed = await mediaRequest.send();
          final http.Response mediaResponse =
              await http.Response.fromStream(mediaStreamed);

          if (mediaResponse.statusCode >= 200 && mediaResponse.statusCode < 300) {
            uploadedMedia.add(jsonDecode(mediaResponse.body) as Map<String, dynamic>);
          }
        } catch (e) {
          print('❌ MEDIA UPLOAD ERROR for ${m.fileName}: $e');
        }
      }

      // Combine untouched existing media (already in `data['media']` from backend)
      // with any newly uploaded media.
      final List<dynamic> existingMedia =
          (data['media'] as List<dynamic>?) ?? <dynamic>[];
      data['media'] = <dynamic>[...existingMedia, ...uploadedMedia];

      print('✅ Product updated: $productId');
      return _productFromJson(data);
    } catch (e, st) {
      print('❌ UPDATE PRODUCT ERROR: $e\n$st');
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
