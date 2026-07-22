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
    required this.phone,
    this.isVerified = false,
  });

  final String id;
  final String email;
  final String name;
  final String shopName;
  final String role;
  final String? phone;
  final bool isVerified;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final String firstName = json['first_name']?.toString() ?? '';
    final String lastName = json['last_name']?.toString() ?? '';
    final String combinedName = '$firstName $lastName'.trim();

    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString().isNotEmpty == true
          ? json['name'].toString()
          : combinedName,
      shopName:
          json['shopName']?.toString() ?? json['shop_name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      phone: json['phone_number']?.toString() ?? json['phone']?.toString() ?? '',
      isVerified: json['email_verified'] == true,
    );
  }

  AuthUser copyWith({
    String? id,
    String? email,
    String? name,
    String? shopName,
    String? role,
    String? phone,
    bool? isVerified,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      shopName: shopName ?? this.shopName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
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

  static void updateUser(AuthUser user) {
    if (_current == null) return;
    print("SESSION USER UPDATED: phone=${user.phone}");
    _current = AuthSession(token: _current!.token, user: user);
  }

  static void clear() {
    _current = null;
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
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
      print('DEBUG raw login user body: $userBody');

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

  /// Fetches the full profile (phone_number, location, badge, score, etc.)
  /// via GET /auth/user/me/ and merges it into AuthSessionStore.
  Future<AuthUser> fetchMyProfile() async {
    final AuthUser? currentUser = AuthSessionStore.user;
    final String? currentToken = AuthSessionStore.token;
    if (currentUser == null || currentToken == null) {
      throw const AuthFailure('Not logged in.');
    }

    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/user/me/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 FETCH MY PROFILE');
    print('📍 Full Endpoint: $endpoint');
    print('═══════════════════════════════════════════════════════');

    try {
      final http.Response response = await activeClient
          .get(
            endpoint,
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $currentToken',
            },
          )
          .timeout(const Duration(seconds: 20));

      print('✅ Response received from backend');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final Map<String, dynamic> body = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorMsg = _messageFromErrorBody(body);
        print('❌ ERROR: Status ${response.statusCode}: $errorMsg');
        throw AuthFailure(errorMsg);
      }

      final AuthUser fetched = AuthUser.fromJson(body);
      final AuthUser merged = currentUser.copyWith(
        name: fetched.name.isNotEmpty ? fetched.name : null,
        email: fetched.email.isNotEmpty ? fetched.email : null,
        phone: fetched.phone,
        isVerified: fetched.isVerified,
        // role / shopName intentionally NOT overwritten — this endpoint doesn't return them.
      );
      AuthSessionStore.updateUser(merged);
      return merged;
    } on AuthFailure {
      rethrow;
    } catch (e, stackTrace) {
      print('❌ Fetch profile error: $e');
      print('   Stack: $stackTrace');
      throw const AuthFailure('Could not load profile details.');
    } finally {
      if (client == null) {
        activeClient.close();
      }
      print('═══════════════════════════════════════════════════════');
    }
  }

  /// Partially updates the current user's profile via PATCH /auth/user/me/
  /// and merges the result into AuthSessionStore.
  Future<AuthUser> updateMyProfile(Map<String, dynamic> updates) async {
    final String? currentToken = AuthSessionStore.token;
    if (currentToken == null) {
      throw const AuthFailure('Not logged in.');
    }

    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/user/me/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 UPDATE MY PROFILE');
    print('📍 Full Endpoint: $endpoint');
    print('📦 Payload: $updates');
    print('═══════════════════════════════════════════════════════');

    try {
      final http.Response response = await activeClient
          .patch(
            endpoint,
            headers: <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $currentToken',
            },
            body: jsonEncode(updates),
          )
          .timeout(const Duration(seconds: 20));

      print('✅ Response received from backend');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final Map<String, dynamic> body = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorMsg = _messageFromErrorBody(body);
        print('❌ ERROR: Status ${response.statusCode}: $errorMsg');
        throw AuthFailure(errorMsg);
      }

      final AuthUser? currentUser = AuthSessionStore.user;
      final AuthUser fetched = AuthUser.fromJson(body);
      final AuthUser merged = (currentUser ?? fetched).copyWith(
        name: fetched.name.isNotEmpty ? fetched.name : null,
        email: fetched.email.isNotEmpty ? fetched.email : null,
        phone: fetched.phone,
      );
      AuthSessionStore.updateUser(merged);
      return merged;
    } on AuthFailure {
      rethrow;
    } catch (e, stackTrace) {
      print('❌ Update profile error: $e');
      print('   Stack: $stackTrace');
      throw const AuthFailure('Could not update profile.');
    } finally {
      if (client == null) {
        activeClient.close();
      }
      print('═══════════════════════════════════════════════════════');
    }
  }
  /// Changes the current user's password via POST /auth/change-password/.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final String? currentToken = AuthSessionStore.token;
    if (currentToken == null) {
      throw const AuthFailure('Not logged in.');
    }

    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/change-password/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 CHANGE PASSWORD');
    print('📍 Full Endpoint: $endpoint');
    print('═══════════════════════════════════════════════════════');

    try {
      final http.Response response = await activeClient
          .post(
            endpoint,
            headers: <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $currentToken',
            },
            body: jsonEncode(<String, dynamic>{
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 20));

      print('✅ Response received from backend');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final Map<String, dynamic> body = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorMsg = _messageFromErrorBody(body);
        print('❌ ERROR: Status ${response.statusCode}: $errorMsg');
        throw AuthFailure(errorMsg);
      }
    } on AuthFailure {
      rethrow;
    } catch (e, stackTrace) {
      print('❌ Change password error: $e');
      print('   Stack: $stackTrace');
      throw const AuthFailure('Could not change password.');
    } finally {
      if (client == null) {
        activeClient.close();
      }
      print('═══════════════════════════════════════════════════════');
    }
  }

  /// Logs out from all devices via POST /auth/logout-all/ and clears
  /// the local session — caller is responsible for navigating to login.
  Future<void> logoutAllDevices() async {
    final String? currentToken = AuthSessionStore.token;
    if (currentToken == null) {
      throw const AuthFailure('Not logged in.');
    }

    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/logout-all/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 LOGOUT ALL DEVICES');
    print('📍 Full Endpoint: $endpoint');
    print('═══════════════════════════════════════════════════════');

    try {
      final http.Response response = await activeClient
          .post(
            endpoint,
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $currentToken',
            },
          )
          .timeout(const Duration(seconds: 20));

      print('✅ Response received from backend');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final Map<String, dynamic> body = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorMsg = _messageFromErrorBody(body);
        print('❌ ERROR: Status ${response.statusCode}: $errorMsg');
        throw AuthFailure(errorMsg);
      }

      AuthSessionStore.clear();
    } on AuthFailure {
      rethrow;
    } catch (e, stackTrace) {
      print('❌ Logout all error: $e');
      print('   Stack: $stackTrace');
      throw const AuthFailure('Could not log out of all devices.');
    } finally {
      if (client == null) {
        activeClient.close();
      }
      print('═══════════════════════════════════════════════════════');
    }
  }
  /// Requests a new verification email via POST /auth/resend-verification/.
  Future<void> resendVerificationEmail(String email) async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/resend-verification/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 RESEND VERIFICATION EMAIL');
    print('📍 Full Endpoint: $endpoint');
    print('═══════════════════════════════════════════════════════');

    try {
      final http.Response response = await activeClient
          .post(
            endpoint,
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{'email': email}),
          )
          .timeout(const Duration(seconds: 20));

      print('✅ Response received from backend');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final Map<String, dynamic> body = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorMsg = _messageFromErrorBody(body);
        print('❌ ERROR: Status ${response.statusCode}: $errorMsg');
        throw AuthFailure(errorMsg);
      }
    } on AuthFailure {
      rethrow;
    } catch (e, stackTrace) {
      print('❌ Resend verification error: $e');
      print('   Stack: $stackTrace');
      throw const AuthFailure('Could not send verification email.');
    } finally {
      if (client == null) {
        activeClient.close();
      }
      print('═══════════════════════════════════════════════════════');
    }
  }

  /// Deletes the current user's account via POST /auth/delete-account/
  /// (password-confirmed) and clears the local session on success.
  Future<void> deleteAccount({required String password}) async {
    final String? currentToken = AuthSessionStore.token;
    if (currentToken == null) {
      throw const AuthFailure('Not logged in.');
    }

    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/delete-account/');

    print('═══════════════════════════════════════════════════════');
    print('🔵 DELETE ACCOUNT');
    print('📍 Full Endpoint: $endpoint');
    print('═══════════════════════════════════════════════════════');

    try {
      final http.Response response = await activeClient
          .post(
            endpoint,
            headers: <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $currentToken',
            },
            body: jsonEncode(<String, dynamic>{'password': password}),
          )
          .timeout(const Duration(seconds: 20));

      print('✅ Response received from backend');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      // 204 No Content has no body to decode.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final Map<String, dynamic> body = _decodeBody(response.body);
        final errorMsg = _messageFromErrorBody(body);
        print('❌ ERROR: Status ${response.statusCode}: $errorMsg');
        throw AuthFailure(errorMsg);
      }

      AuthSessionStore.clear();
    } on AuthFailure {
      rethrow;
    } catch (e, stackTrace) {
      print('❌ Delete account error: $e');
      print('   Stack: $stackTrace');
      throw const AuthFailure('Could not delete account.');
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
    final String? direct = body['message']?.toString() ?? body['error']?.toString() ?? body['detail']?.toString();
    if (direct != null) return direct;

    // DRF validation errors look like {"field_name": ["error message"]}
    for (final MapEntry<String, dynamic> entry in body.entries) {
      final Object? value = entry.value;
      if (value is List && value.isNotEmpty) {
        return '${entry.key}: ${value.first}';
      }
    }
    return 'Request failed. Please check your input.';
  }
}
