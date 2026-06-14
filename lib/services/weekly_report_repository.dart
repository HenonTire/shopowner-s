import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop_manager/models/weekly_report.dart';
import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';

abstract class WeeklyReportRepository {
  Future<WeeklyReport> fetchWeeklyReport({
    DateTime? from,
    DateTime? to,
  });
}

class MockWeeklyReportRepository implements WeeklyReportRepository {
  const MockWeeklyReportRepository();

  @override
  Future<WeeklyReport> fetchWeeklyReport({
    DateTime? from,
    DateTime? to,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    return WeeklyReport(
      generatedAt: DateTime.now(),
      growthRate: 0.084,
      points: const <WeeklyReportPoint>[
        WeeklyReportPoint(dayLabel: 'Mon', sales: 12340, orders: 28),
        WeeklyReportPoint(dayLabel: 'Tue', sales: 11020, orders: 25),
        WeeklyReportPoint(dayLabel: 'Wed', sales: 13210, orders: 30),
        WeeklyReportPoint(dayLabel: 'Thu', sales: 12540, orders: 31),
        WeeklyReportPoint(dayLabel: 'Fri', sales: 15960, orders: 37),
        WeeklyReportPoint(dayLabel: 'Sat', sales: 17220, orders: 42),
        WeeklyReportPoint(dayLabel: 'Sun', sales: 14180, orders: 33),
      ],
    );
  }
}

class BackendWeeklyReportRepository implements WeeklyReportRepository {
  BackendWeeklyReportRepository({
    String? baseUrl,
    this.client,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final http.Client? client;

  @override
  Future<WeeklyReport> fetchWeeklyReport({
    DateTime? from,
    DateTime? to,
  }) async {
    final http.Client activeClient = client ?? http.Client();
    try {
      final String? token = AuthSessionStore.token;
      if (token == null) {
        throw Exception('Not authenticated. Please login first.');
      }

      final Uri endpoint = _buildEndpoint(from, to);

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
        throw Exception('Failed to fetch report: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      return WeeklyReport(
        generatedAt: DateTime.parse(data['generated_at']?.toString() ?? DateTime.now().toIso8601String()),
        growthRate: (data['growth_rate'] as num?)?.toDouble() ?? 0.0,
        points: _parsePoints(data['points'] ?? data['data'] ?? []),
      );
    } catch (e) {
      rethrow;
    } finally {
      if (client == null) {
        activeClient.close();
      }
    }
  }

  Uri _buildEndpoint(DateTime? from, DateTime? to) {
    final String normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final Uri base = Uri.parse('$normalizedBaseUrl/analytics/weekly-report/');

    final Map<String, String> queryParams = <String, String>{};
    if (from != null) {
      queryParams['from'] = from.toIso8601String().split('T')[0];
    }
    if (to != null) {
      queryParams['to'] = to.toIso8601String().split('T')[0];
    }

    return base.replace(queryParameters: queryParams.isEmpty ? null : queryParams);
  }

  List<WeeklyReportPoint> _parsePoints(List<dynamic> data) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> point) => WeeklyReportPoint(
              dayLabel: point['day_label']?.toString() ?? point['day']?.toString() ?? '',
              sales: (point['sales'] as num?)?.toDouble() ?? 0.0,
              orders: point['orders'] as int? ?? 0,
            ))
        .toList();
  }
}
