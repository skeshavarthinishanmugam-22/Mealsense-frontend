import 'package:shared_preferences/shared_preferences.dart';

/// SessionManager handles JWT token persistence and retrieval.
/// Allows users to stay logged in without re-entering credentials on app restart.
class SessionManager {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _tokenTimestampKey = 'token_timestamp';

  static final SessionManager _instance = SessionManager._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  SessionManager._internal();

  factory SessionManager() {
    return _instance;
  }

  /// Initialize SharedPreferences (call this once at app startup)
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Save JWT token after successful login
  Future<void> saveToken(String token, String userId, String userEmail) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_userIdKey, userId);
    await _prefs.setString(_userEmailKey, userEmail);
    await _prefs.setInt(_tokenTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get stored JWT token
  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  /// Get stored user ID
  String? getUserId() {
    return _prefs.getString(_userIdKey);
  }

  /// Get stored user email
  String? getUserEmail() {
    return _prefs.getString(_userEmailKey);
  }

  /// Check if user is logged in (token exists)
  bool isLoggedIn() {
    return getToken() != null && getToken()!.isNotEmpty;
  }

  /// Check if token is likely expired (older than 24 hours)
  bool isTokenExpired() {
    final timestamp = _prefs.getInt(_tokenTimestampKey);
    if (timestamp == null) return true;
    
    final tokenAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    final twentyFourHours = 24 * 60 * 60 * 1000; // milliseconds
    
    return tokenAge > twentyFourHours;
  }

  /// Clear stored token (logout)
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userEmailKey);
    await _prefs.remove(_tokenTimestampKey);
  }

  /// Clear all user data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
