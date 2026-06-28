import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop_manager/services/api_config.dart';

class LoginRequest {
  const LoginRequest({
    required this.identifier,
    required this.password,
  });

  final String identifier;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'email': identifier,
      'password': password,
    };
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.shopName,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final String shopName;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shopName:
          json['shopName']?.toString() ?? json['shop_name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final AuthUser user;
}

class AuthSessionStore {
  AuthSessionStore._();

  static AuthSession? _current;

  static AuthSession? get current => _current;
  static String? get token {
  print("TOKEN = ${_current?.token}");
  return _current?.token;
}
  static AuthUser? get user => _current?.user;

  static void save(AuthSession session) {
    print("SESSION SAVED");
    _current = session;
  }

  static void clear() {
    _current = null;
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

abstract class AuthService {
  Future<void> login(LoginRequest request);
}

class MockAuthService implements AuthService {
  const MockAuthService();

  @override
  Future<void> login(LoginRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (request.identifier.toLowerCase() == 'henon' &&
        request.password == 'Henon@12') {
      return;
    }

    throw const AuthFailure('Invalid credentials. Try demo@shikela.com');
  }
}

class BackendAuthService implements AuthService {
  BackendAuthService({
    String? baseUrl,
    this.client,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final http.Client? client;

  @override
  Future<void> login(LoginRequest request) async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/login/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 FLUTTER LOGIN ATTEMPT');
    print('═══════════════════════════════════════════════════════');
    print('📍 Backend URL: $baseUrl');
    print('📍 Full Endpoint: $endpoint');
    print('👤 Username: ${request.identifier}');
    print('═══════════════════════════════════════════════════════');

    try {
      final http.Response response = await activeClient
          .post(
            endpoint,
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 20));

      print('✅ Response received from backend');
      print('   Status: ${response.statusCode}');
      print('   Body length: ${response.body.length} bytes');
      if (response.body.length < 500) {
        print('   Body: ${response.body}');
      } else {
        print('   Body: ${response.body.substring(0, 200)}...');
      }

      final Map<String, dynamic> body = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorMsg = _messageFromErrorBody(body);
        print('❌ ERROR: Status ${response.statusCode}: $errorMsg');
        throw AuthFailure(errorMsg);
      }

      final String token =
          body['access']?.toString() ?? body['token']?.toString() ?? body['access_token']?.toString() ?? '';
      final Object? userBody = body['user'];

      if (token.isEmpty || userBody is! Map<String, dynamic>) {
        print('❌ ERROR: Missing token or user data in response');
        throw const AuthFailure(
          'Login response was missing token or user data.',
        );
      }

      print('✅ Login successful!');
      print('   Token: ${token.substring(0, 30)}...');
      print('   User: ${userBody['email'] ?? userBody['name']}');

      AuthSessionStore.save(
        AuthSession(
          token: token,
          user: AuthUser.fromJson(userBody),
        ),
      );
    } on AuthFailure catch (e) {
      print('❌ Authentication failed: ${e.message}');
      rethrow;
    } on FormatException catch (e) {
      print('❌ JSON Format Error: ${e.message}');
      throw const AuthFailure(
        'Login failed because the server returned invalid data.',
      );
    } catch (e, stackTrace) {
      print('❌ Network/Connection Error:');
      print('   Error: $e');
      print('   Type: ${e.runtimeType}');
      print('   Stack: $stackTrace');
      throw const AuthFailure(
        'Could not reach the backend. Check the API URL and try again.',
      );
    } finally {
      if (client == null) {
        activeClient.close();
      }
      print('═══════════════════════════════════════════════════════');
    }
  }

  Uri _endpoint(String path) {
    final String normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl$path');
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final Object? decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const FormatException('Expected a JSON object.');
  }

  String _messageFromErrorBody(Map<String, dynamic> body) {
    return body['message']?.toString() ??
        body['error']?.toString() ??
        'Login failed. Please check your credentials.';
  }
}
