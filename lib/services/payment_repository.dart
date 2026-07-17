import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';

class BankDetails {
  const BankDetails({
    required this.providerName,
    required this.accountNumber,
    required this.isVerified,
  });
  final String providerName;
  final String accountNumber;
  final bool isVerified;
}

class TelebirrDetails {
  const TelebirrDetails({
    required this.phoneNumber,
    required this.isVerified,
  });
  final String phoneNumber;
  final bool isVerified;
}

class PaymentMethods {
  const PaymentMethods({this.bank, this.telebirr});
  final BankDetails? bank;
  final TelebirrDetails? telebirr;
}

class PaymentRepository {
  PaymentRepository({String? baseUrl, this.client}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

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

  Future<PaymentMethods> fetchMyPaymentMethods() async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/payment-methods/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 FETCH PAYMENT METHODS');
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

      final Map<String, dynamic>? bankJson = body['bank'] as Map<String, dynamic>?;
      final Map<String, dynamic>? telebirrJson = body['telebirr'] as Map<String, dynamic>?;

      final BankDetails? bank = (bankJson != null &&
              (bankJson['provider_name']?.toString().isNotEmpty ?? false) &&
              (bankJson['account_number']?.toString().isNotEmpty ?? false))
          ? BankDetails(
              providerName: bankJson['provider_name'].toString(),
              accountNumber: bankJson['account_number'].toString(),
              isVerified: bankJson['is_verified'] == true,
            )
          : null;

      final String? telebirrPhone = telebirrJson?['phone_number']?.toString();
      final TelebirrDetails? telebirr = (telebirrPhone != null && telebirrPhone.isNotEmpty)
          ? TelebirrDetails(
              phoneNumber: telebirrPhone,
              isVerified: telebirrJson?['is_verified'] == true,
            )
          : null;

      return PaymentMethods(bank: bank, telebirr: telebirr);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      print('❌ Fetch payment methods error: $e');
      throw const AuthFailure('Could not load payment methods.');
    } finally {
      if (client == null) activeClient.close();
      print('═══════════════════════════════════════════════════════');
    }
  }
  Future<void> updateBank({required String providerName, required String accountNumber}) async {
    await _put('bank', <String, String>{
      'provider_name': providerName,
      'account_number': accountNumber,
    });
  }

  Future<void> updateTelebirr({required String phoneNumber}) async {
    await _put('telebirr', <String, String>{'phone_number': phoneNumber});
  }

  Future<void> deletePaymentMethod(String type) async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/payment-methods/$type/');

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
      throw const AuthFailure('Could not delete payment method.');
    } finally {
      if (client == null) activeClient.close();
    }
  }

  Future<void> _put(String type, Map<String, String> payload) async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/payment-methods/$type/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 UPDATE PAYMENT METHOD ($type)');
    print('📍 Full Endpoint: $endpoint');
    print('📦 Payload: $payload');
    print('═══════════════════════════════════════════════════════');

    try {
      final http.Response response = await activeClient
          .put(endpoint, headers: _headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));

      print('✅ Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final Map<String, dynamic> body = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthFailure(_messageFromErrorBody(body));
      }
    } on AuthFailure {
      rethrow;
    } catch (e) {
      print('❌ Update payment method error: $e');
      throw const AuthFailure('Could not update payment method.');
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