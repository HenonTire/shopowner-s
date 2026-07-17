import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop_manager/providers/shop_analytics_trend.dart';

import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';

abstract class ShopAnalyticsRepository {
  Future<List<ShopAnalyticsTrendPoint>> fetchTrend({
    required String period,
    int limit = 12,
  });
}

class MockShopAnalyticsRepository implements ShopAnalyticsRepository {
  const MockShopAnalyticsRepository();

  @override
  Future<List<ShopAnalyticsTrendPoint>> fetchTrend({
    required String period,
    int limit = 12,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final DateTime now = DateTime.now();
    return List<ShopAnalyticsTrendPoint>.generate(limit, (int i) {
      return ShopAnalyticsTrendPoint(
        period: now.subtract(Duration(days: i * 7)),
        revenue: 10000 + (i * 350),
        ordersCount: 20 + i,
        unitsSold: 40 + (i * 2),
      );
    }).reversed.toList();
  }
}

class BackendShopAnalyticsRepository implements ShopAnalyticsRepository {
  BackendShopAnalyticsRepository({
    String? baseUrl,
    this.client,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final http.Client? client;

  @override
  Future<List<ShopAnalyticsTrendPoint>> fetchTrend({
    required String period,
    int limit = 12,
  }) async {
    final http.Client activeClient = client ?? http.Client();
    try {
      final String? token = AuthSessionStore.token;
      if (token == null) {
        throw Exception('Not authenticated. Please login first.');
      }

      final Uri endpoint = _buildEndpoint(period, limit);

      final http.Response response = await activeClient
          .get(
            endpoint,
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to fetch trend: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> trendJson = data['trend'] as List<dynamic>? ?? <dynamic>[];

      return trendJson
          .whereType<Map<String, dynamic>>()
          .map(ShopAnalyticsTrendPoint.fromJson)
          .toList();
    } finally {
      if (client == null) {
        activeClient.close();
      }
    }
  }

  Uri _buildEndpoint(String period, int limit) {
    final String normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final Uri base = Uri.parse('$normalizedBaseUrl/analytics/shop/dashboard/');

    return base.replace(queryParameters: <String, String>{
      'period': period,
      'limit': '$limit',
    });
  }
}