import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop_manager/models/supplier_models.dart';
import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';

abstract class SupplierRepository {
  Future<SupplierDashboardData> fetchDashboard();
}

class BackendSupplierRepository implements SupplierRepository {
  BackendSupplierRepository({String? baseUrl, this.client})
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
  Future<SupplierDashboardData> fetchDashboard() async {
    final http.Client activeClient = client ?? http.Client();
    try {
      final String token = _requireToken();
      final http.Response response = await activeClient
          .get(
            _endpoint('/procurement/dashboard/'),
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) throw Exception('Session expired. Please login again.');
      if (response.statusCode == 403) throw Exception('Only shop owners can view suppliers.');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to fetch supplier dashboard (${response.statusCode}): ${response.body}');
      }

      return SupplierDashboardData.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } finally {
      if (client == null) activeClient.close();
    }
  }
}