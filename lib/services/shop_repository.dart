import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shop_manager/models/shop.dart';
import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';

class ShopUpdateRequest {
  const ShopUpdateRequest({
    required this.name,
    required this.description,
    this.domain,
  });

  final String name;
  final String description;
  final String? domain;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      if (domain != null && domain!.isNotEmpty) 'domain': domain,
    };
  }
}

class ThemeSettingsUpdateRequest {
  const ThemeSettingsUpdateRequest({
    required this.primaryColor,
    required this.secondaryColor,
    required this.fontFamily,
    this.logoBytes,
    this.logoFileName,
    this.bannerBytes,
    this.bannerFileName,
  });

  final String primaryColor;
  final String secondaryColor;
  final String fontFamily;
  final Uint8List? logoBytes;
  final String? logoFileName;
  final Uint8List? bannerBytes;
  final String? bannerFileName;
}

abstract class ShopRepository {
  Future<Shop> fetchMyShop();
  Future<Shop> updateShop(ShopUpdateRequest request);
  Future<void> updateThemeSettings(ThemeSettingsUpdateRequest request);
}

class BackendShopRepository implements ShopRepository {
  BackendShopRepository({String? baseUrl, this.client})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final http.Client? client;

  Uri _endpoint(String path) {
    final String base =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$base$path');
  }

  String _requireToken() {
    final String? token = AuthSessionStore.token;
    if (token == null) throw Exception('Not authenticated. Please login first.');
    return token;
  }

  @override
  Future<Shop> fetchMyShop() async {
    final http.Client activeClient = client ?? http.Client();
    try {
      final String token = _requireToken();
      final http.Response response = await activeClient
          .get(
            _endpoint('/shops/me/'),
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) throw Exception('Session expired. Please login again.');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to fetch shop (${response.statusCode}): ${response.body}');
      }

      return Shop.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } finally {
      if (client == null) activeClient.close();
    }
  }

  @override
  Future<Shop> updateShop(ShopUpdateRequest request) async {
    final http.Client activeClient = client ?? http.Client();
    try {
      final String token = _requireToken();
      final http.Response response = await activeClient
          .patch(
            _endpoint('/shops/me/'),
            headers: <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) throw Exception('Session expired. Please login again.');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to update shop (${response.statusCode}): ${response.body}');
      }

      return Shop.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } finally {
      if (client == null) activeClient.close();
    }
  }

  @override
  Future<void> updateThemeSettings(ThemeSettingsUpdateRequest request) async {
    final http.Client activeClient = client ?? http.Client();
    try {
      final String token = _requireToken();
      final Uri endpoint = _endpoint('/shops/theme-settings/');

      final http.MultipartRequest multipart =
          http.MultipartRequest('PATCH', endpoint);
      multipart.headers['Authorization'] = 'Bearer $token';
      multipart.headers['Accept'] = 'application/json';

      multipart.fields['primary_color'] = request.primaryColor;
      multipart.fields['secondary_color'] = request.secondaryColor;
      multipart.fields['font_family'] = request.fontFamily;

      if (request.logoBytes != null) {
        multipart.files.add(http.MultipartFile.fromBytes(
          'logo',
          request.logoBytes!,
          filename: request.logoFileName ?? 'logo.jpg',
        ));
      }
      if (request.bannerBytes != null) {
        multipart.files.add(http.MultipartFile.fromBytes(
          'banner_image',
          request.bannerBytes!,
          filename: request.bannerFileName ?? 'banner.jpg',
        ));
      }

      final http.StreamedResponse streamed = await multipart.send();
      final http.Response response = await http.Response.fromStream(streamed);

      if (response.statusCode == 401) throw Exception('Session expired. Please login again.');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to update theme settings (${response.statusCode}): ${response.body}');
      }
    } finally {
      if (client == null) activeClient.close();
    }
  }
}