import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _kToken = 'auth_token';
  static const _kUsername = 'auth_username';
  static const _kRole = 'auth_role';

  static Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  static Future<bool> hasToken() async {
    final sp = await _sp();
    final t = sp.getString(_kToken);
    return t != null && t.trim().isNotEmpty;
  }

  static Future<String?> token() async {
    final sp = await _sp();
    final t = sp.getString(_kToken);
    if (t == null) return null;
    final tt = t.trim();
    return tt.isEmpty ? null : tt;
  }

  static Future<String?> username() async {
    final sp = await _sp();
    return sp.getString(_kUsername);
  }

  static Future<String?> role() async {
    final sp = await _sp();
    return sp.getString(_kRole);
  }

  static Future<void> setAuth({
    required String token,
    required String username,
    required String role,
  }) async {
    final sp = await _sp();
    await sp.setString(_kToken, token);
    await sp.setString(_kUsername, username);
    await sp.setString(_kRole, role);
  }

  static Future<void> clear() async {
    final sp = await _sp();
    await sp.remove(_kToken);
    await sp.remove(_kUsername);
    await sp.remove(_kRole);
  }
}
