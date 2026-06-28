class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.variantName,
    required this.price,
    required this.stock,
    this.attributes = const <String, String>{},
  });

  final String id;
  final String variantName;
  final double price;
  final int stock;
  final Map<String, String> attributes;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final dynamic attrs = json['attributes'];
    final Map<String, String> parsedAttrs = <String, String>{};
    if (attrs is Map) {
      attrs.forEach((dynamic k, dynamic v) {
        parsedAttrs[k.toString()] = v.toString();
      });
    }
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      variantName: json['variant_name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      stock: int.tryParse(json['stock']?.toString() ?? '') ?? 0,
      attributes: parsedAttrs,
    );
  }
}

class ProductMedia {
  const ProductMedia({
    required this.id,
    required this.file,
    this.caption = '',
    this.isPrimary = false,
    this.mediaType = 'image',
    this.order = 1,
  });

  final String id;
  final String file;
  final String caption;
  final bool isPrimary;
  final String mediaType;
  final int order;

  factory ProductMedia.fromJson(Map<String, dynamic> json) {
    return ProductMedia(
      id: json['id']?.toString() ?? '',
      file: json['file']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      isPrimary: json['is_primary'] == true,
      mediaType: json['media_type']?.toString() ?? 'image',
      order: int.tryParse(json['order']?.toString() ?? '') ?? 1,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.stock,
    this.description = '',
    this.sku,
    this.category,
    this.isActive = true,
    this.weight,
    this.dimensions,
    this.tags = const <String>[],
    this.variants = const <ProductVariant>[],
    this.media = const <ProductMedia>[],
    this.averageRating,
    this.reviewsCount = 0,
  });

  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final int stock;
  final String description;
  final String? sku;
  final String? category;
  final bool isActive;
  final double? weight;
  final String? dimensions;
  final List<String> tags;
  final List<ProductVariant> variants;
  final List<ProductMedia> media;
  final double? averageRating;
  final int reviewsCount;

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse media
    final dynamic mediaRaw = json['media'];
    final List<ProductMedia> mediaList = mediaRaw is List
        ? mediaRaw
            .whereType<Map<String, dynamic>>()
            .map(ProductMedia.fromJson)
            .toList()
        : <ProductMedia>[];

    // Primary image URL
    String imageUrl = '';
    if (mediaList.isNotEmpty) {
      final ProductMedia primary = mediaList.firstWhere(
        (ProductMedia m) => m.isPrimary,
        orElse: () => mediaList.first,
      );
      imageUrl = primary.file;
    }

    // Parse variants
    final dynamic variantsRaw = json['variants'];
    final List<ProductVariant> variantList = variantsRaw is List
        ? variantsRaw
            .whereType<Map<String, dynamic>>()
            .map(ProductVariant.fromJson)
            .toList()
        : <ProductVariant>[];

    // Total stock from variants if top-level stock is 0
    int stock = int.tryParse(json['stock']?.toString() ?? '') ?? 0;
    if (stock == 0 && variantList.isNotEmpty) {
      stock = variantList.fold(0, (int sum, ProductVariant v) => sum + v.stock);
    }

    // Tags
    final dynamic tagsRaw = json['tags'];
    final List<String> tags = tagsRaw is List
        ? tagsRaw.map((dynamic t) => t.toString()).toList()
        : <String>[];

    // Dimensions
    final dynamic dims = json['dimensions'];
    String? dimensions;
    if (dims is Map) {
      dimensions =
          '${dims['length'] ?? ''}x${dims['width'] ?? ''}x${dims['height'] ?? ''}';
    } else if (dims is String && dims.isNotEmpty) {
      dimensions = dims;
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: imageUrl,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      stock: stock,
      description: json['description']?.toString() ?? '',
      sku: json['sku']?.toString(),
      category: (json['category'] as Map<String, dynamic>?)?['name']?.toString(),
      isActive: json['is_active'] == true,
      weight: double.tryParse(json['weight']?.toString() ?? ''),
      dimensions: dimensions,
      tags: tags,
      variants: variantList,
      media: mediaList,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? ''),
      reviewsCount: int.tryParse(json['reviews_count']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'price': price,
      'stock': stock,
      'description': description,
      'sku': sku,
      'category': category,
      'is_active': isActive,
      'weight': weight,
      'dimensions': dimensions,
      'tags': tags,
    };
  }
}