import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionController {
  SessionController._();
  static final SessionController instance = SessionController._();

  static const _keyLoggedIn = 'ml_logged_in';
  static const _keyUser = 'ml_user_json';
  static const _keyGuideSeen = 'ml_guide_seen';

  Map<String, dynamic>? _user;
  bool _isLoggedIn = false;
  bool _guideSeen = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get guideSeen => _guideSeen;

  // User fields
  int? get userId => _user?['id'] as int?;
  String? get userName => _user?['name'] as String?;
  String? get userEmail => _user?['email'] as String?;
  String? get walletAddress => _user?['wallet_address'] as String?;
  String? get turnkeyWalletId => _user?['turnkey_wallet_id'] as String?;
  String? get profilePick => _user?['profile_pick'] as String?;
  Map<String, dynamic>? get user => _user;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    _guideSeen = prefs.getBool(_keyGuideSeen) ?? false;
    final userJson = prefs.getString(_keyUser);
    if (userJson != null) {
      try {
        _user = jsonDecode(userJson) as Map<String, dynamic>;
      } catch (_) {
        _user = null;
      }
    }
  }

  Future<void> saveSession(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    _user = userData;
    _isLoggedIn = true;
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUser, jsonEncode(userData));
  }

  Future<void> updateProfileLocal({
    String? name,
    String? email,
    String? profilePick,
  }) async {
    if (_user == null) return;
    if (name != null) _user!['name'] = name;
    if (email != null) _user!['email'] = email;
    if (profilePick != null) _user!['profile_pick'] = profilePick;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(_user));
  }

  Future<void> setGuideSeen() async {
    final prefs = await SharedPreferences.getInstance();
    _guideSeen = true;
    await prefs.setBool(_keyGuideSeen, true);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = false;
    _user = null;
    await prefs.setBool(_keyLoggedIn, false);
    await prefs.remove(_keyUser);
    // guideSeen is intentionally kept
  }
}
