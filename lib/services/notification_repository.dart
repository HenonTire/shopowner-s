import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';

class NotificationSettings {
  const NotificationSettings({
    required this.pushEnabled,
    required this.emailEnabled,
  });

  final bool pushEnabled;
  final bool emailEnabled;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['push_enabled'] == true,
      emailEnabled: json['email_enabled'] == true,
    );
  }
}

class NotificationRepository {
  NotificationRepository({String? baseUrl, this.client}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final http.Client? client;

  Uri _endpoint(String path) {
    final String normalized =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$normalized$path');
  }

  Map<String, String> get _headers {
    final String? token = AuthSessionStore.token;
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<NotificationSettings> fetchMyNotificationSettings() async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/notifications/me/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 FETCH NOTIFICATION SETTINGS');
    print('📍 Full Endpoint: $endpoint');
    print('═══════════════════════════════════════════════════════');

    try {
      final http.Response response =
          await activeClient.get(endpoint, headers: _headers).timeout(const Duration(seconds: 20));

      print('✅ Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final Map<String, dynamic> body = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthFailure(_messageFromErrorBody(body));
      }

      return NotificationSettings.fromJson(body);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      print('❌ Fetch notification settings error: $e');
      throw const AuthFailure('Could not load notification settings.');
    } finally {
      if (client == null) activeClient.close();
      print('═══════════════════════════════════════════════════════');
    }
  }

  Future<NotificationSettings> updateNotificationSettings({
    required bool pushEnabled,
    required bool emailEnabled,
  }) async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/notifications/me/');

    final Map<String, dynamic> payload = <String, dynamic>{
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
    };

    print('═══════════════════════════════════════════════════════');
    print('🔵 UPDATE NOTIFICATION SETTINGS');
    print('📍 Full Endpoint: $endpoint');
    print('📦 Payload: $payload');
    print('═══════════════════════════════════════════════════════');

    try {
      final http.Response response = await activeClient
          .patch(endpoint, headers: _headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));

      print('✅ Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final Map<String, dynamic> body = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthFailure(_messageFromErrorBody(body));
      }

      return NotificationSettings.fromJson(body);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      print('❌ Update notification settings error: $e');
      throw const AuthFailure('Could not update notification settings.');
    } finally {
      if (client == null) activeClient.close();
      print('═══════════════════════════════════════════════════════');
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final Object? decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  String _messageFromErrorBody(Map<String, dynamic> body) {
    final String? direct = body['detail']?.toString() ?? body['message']?.toString();
    if (direct != null) return direct;
    for (final MapEntry<String, dynamic> entry in body.entries) {
      final Object? value = entry.value;
      if (value is List && value.isNotEmpty) {
        return '${entry.key}: ${value.first}';
      }
    }
    return 'Request failed. Please check your input.';
  }
}