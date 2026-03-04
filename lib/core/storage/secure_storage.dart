import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage for token persistence.
class SecureStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiresAtKey = 'expires_at_utc';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _userDisplayNameKey = 'user_display_name';
  static const _householdIdKey = 'household_id';

  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  // ── Tokens ──────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAtUtc,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _expiresAtKey, value: expiresAtUtc.toIso8601String()),
    ]);
  }

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);

  Future<DateTime?> get expiresAtUtc async {
    final s = await _storage.read(key: _expiresAtKey);
    return s != null ? DateTime.tryParse(s) : null;
  }

  Future<bool> get hasValidToken async {
    final token = await accessToken;
    final expires = await expiresAtUtc;
    if (token == null || expires == null) return false;
    return expires.isAfter(DateTime.now().toUtc());
  }

  // ── User ────────────────────────────────────────────────

  Future<void> saveUser({
    required String id,
    String? email,
    String? displayName,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: id),
      if (email != null) _storage.write(key: _userEmailKey, value: email),
      if (displayName != null)
        _storage.write(key: _userDisplayNameKey, value: displayName),
    ]);
  }

  Future<String?> get userId => _storage.read(key: _userIdKey);
  Future<String?> get userEmail => _storage.read(key: _userEmailKey);
  Future<String?> get userDisplayName =>
      _storage.read(key: _userDisplayNameKey);

  // ── Household ───────────────────────────────────────────

  Future<void> saveHouseholdId(String id) =>
      _storage.write(key: _householdIdKey, value: id);

  Future<String?> get householdId => _storage.read(key: _householdIdKey);

  // ── Clear ───────────────────────────────────────────────

  Future<void> clearAll() => _storage.deleteAll();
}
