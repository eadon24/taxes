class AuthService {
  static const String _usuario = 'admin';
  static const String _password = '123456';

  static bool login({
    required String usuario,
    required String password,
  }) {
    return usuario == _usuario && password == _password;
  }
}
