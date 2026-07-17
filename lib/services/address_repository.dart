import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';

class AddressPair {
  const AddressPair({this.shipping, this.billing});
  final String? shipping;
  final String? billing;
}

class AddressRepository {
  AddressRepository({String? baseUrl, this.client}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

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

  Future<AddressPair> fetchMyAddresses() async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/addresses/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 FETCH MY ADDRESSES');
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

      final String? shipping = (body['shipping'] as Map<String, dynamic>?)?['full_address']?.toString();
      final String? billing = (body['billing'] as Map<String, dynamic>?)?['full_address']?.toString();
      return AddressPair(shipping: shipping, billing: billing);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      print('❌ Fetch addresses error: $e');
      throw const AuthFailure('Could not load addresses.');
    } finally {
      if (client == null) activeClient.close();
      print('═══════════════════════════════════════════════════════');
    }
  }

  /// type must be 'shipping' or 'billing' (lowercase).
  Future<String> updateAddress({required String type, required String fullAddress}) async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/addresses/$type/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 UPDATE ADDRESS ($type)');
    print('📍 Full Endpoint: $endpoint');
    print('📦 Payload: {full_address: $fullAddress}');
    print('═══════════════════════════════════════════════════════');

    try {
      final http.Response response = await activeClient
          .put(
            endpoint,
            headers: _headers,
            body: jsonEncode(<String, String>{'full_address': fullAddress}),
          )
          .timeout(const Duration(seconds: 20));

      print('✅ Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final Map<String, dynamic> body = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthFailure(_messageFromErrorBody(body));
      }

      return body['full_address']?.toString() ?? fullAddress;
    } on AuthFailure {
      rethrow;
    } catch (e) {
      print('❌ Update address error: $e');
      throw const AuthFailure('Could not update address.');
    } finally {
      if (client == null) activeClient.close();
      print('═══════════════════════════════════════════════════════');
    }
  }

  Future<void> deleteAddress(String type) async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/addresses/$type/');

    try {
      final http.Response response =
          await activeClient.delete(endpoint, headers: _headers).timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final Map<String, dynamic> body = _decodeBody(response.body);
        throw AuthFailure(_messageFromErrorBody(body));
      }
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw const AuthFailure('Could not delete address.');
    } finally {
      if (client == null) activeClient.close();
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