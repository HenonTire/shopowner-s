import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';

class DeliverySettings {
  const DeliverySettings({
    required this.regions,
    required this.fee,
    required this.pickupAvailable,
    required this.processingTime, // human-readable label, e.g. "1 business day"
  });

  final String regions;
  final double fee;
  final bool pickupAvailable;
  final String processingTime;

  // Backend uses coded keys; Flutter UI uses display labels — map both ways here
  // so the rest of the app never has to think about the backend's key format.
  static const Map<String, String> _backendToLabel = <String, String>{
    'SAME_DAY': 'Same day',
    '1_BUSINESS_DAY': '1 business day',
    '2_BUSINESS_DAYS': '2 business days',
    '3_BUSINESS_DAYS': '3 business days',
  };

  static String labelToBackend(String label) {
    return _backendToLabel.entries
        .firstWhere((MapEntry<String, String> e) => e.value == label, orElse: () => const MapEntry('1_BUSINESS_DAY', '1 business day'))
        .key;
  }

  factory DeliverySettings.fromJson(Map<String, dynamic> json) {
    final String backendKey = json['processing_time']?.toString() ?? '1_BUSINESS_DAY';
    return DeliverySettings(
      regions: json['regions']?.toString() ?? '',
      fee: double.tryParse(json['fee']?.toString() ?? '') ?? 0.0,
      pickupAvailable: json['pickup_available'] == true,
      processingTime: _backendToLabel[backendKey] ?? '1 business day',
    );
  }
}

class DeliveryRepository {
  DeliveryRepository({String? baseUrl, this.client}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

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

  Future<DeliverySettings> fetchMyDeliverySettings() async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/me/delivery/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 FETCH DELIVERY SETTINGS');
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

      return DeliverySettings.fromJson(body);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      print('❌ Fetch delivery settings error: $e');
      throw const AuthFailure('Could not load delivery settings.');
    } finally {
      if (client == null) activeClient.close();
      print('═══════════════════════════════════════════════════════');
    }
  }

  Future<DeliverySettings> updateDeliverySettings({
    required String regions,
    required double fee,
    required bool pickupAvailable,
    required String processingTimeLabel,
  }) async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/me/delivery/');

    final Map<String, dynamic> payload = <String, dynamic>{
      'regions': regions,
      'fee': fee,
      'pickup_available': pickupAvailable,
      'processing_time': DeliverySettings.labelToBackend(processingTimeLabel),
    };

    print('═══════════════════════════════════════════════════════');
    print('🔵 UPDATE DELIVERY SETTINGS');
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

      return DeliverySettings.fromJson(body);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      print('❌ Update delivery settings error: $e');
      throw const AuthFailure('Could not update delivery settings.');
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