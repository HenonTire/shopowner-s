class LoginRequest {
  const LoginRequest({
    required this.identifier,
    required this.password,
  });

  final String identifier;
  final String password;
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
