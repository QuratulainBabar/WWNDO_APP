import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';

/// Persists auth tokens/user.
///
/// Uses an in-memory cache plus SharedPreferences backup so authenticated API
/// calls (KYC, profile, etc.) still work when secure storage is flaky
/// (common on web / some desktop & emulator setups).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _secure = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'auth_user';

  String? _accessTokenMemory;
  String? _refreshTokenMemory;
  AuthUser? _userMemory;

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    _accessTokenMemory = accessToken;
    _refreshTokenMemory = refreshToken;
    _userMemory = user;
    await Future.wait([
      _write(_accessTokenKey, accessToken),
      _write(_refreshTokenKey, refreshToken),
      _write(_userKey, jsonEncode(user.toJson())),
    ]);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessTokenMemory = accessToken;
    _refreshTokenMemory = refreshToken;
    await Future.wait([
      _write(_accessTokenKey, accessToken),
      _write(_refreshTokenKey, refreshToken),
    ]);
  }

  Future<void> saveUser(AuthUser user) async {
    _userMemory = user;
    await _write(_userKey, jsonEncode(user.toJson()));
  }

  Future<AuthUser?> getUser() async {
    if (_userMemory != null) return _userMemory;
    final raw = await _read(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final user = AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _userMemory = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    if (_accessTokenMemory != null && _accessTokenMemory!.isNotEmpty) {
      return _accessTokenMemory;
    }
    final token = await _read(_accessTokenKey);
    if (token != null && token.isNotEmpty) {
      _accessTokenMemory = token;
    }
    return token;
  }

  Future<String?> getRefreshToken() async {
    if (_refreshTokenMemory != null && _refreshTokenMemory!.isNotEmpty) {
      return _refreshTokenMemory;
    }
    final token = await _read(_refreshTokenKey);
    if (token != null && token.isNotEmpty) {
      _refreshTokenMemory = token;
    }
    return token;
  }

  Future<void> clear() async {
    _accessTokenMemory = null;
    _refreshTokenMemory = null;
    _userMemory = null;
    await Future.wait([
      _delete(_accessTokenKey),
      _delete(_refreshTokenKey),
      _delete(_userKey),
    ]);
  }

  /// Locks the app session for biometric re-entry: drops the access token but
  /// keeps refresh token + cached user so Face ID / Fingerprint can unlock.
  Future<void> lockForBiometric() async {
    _accessTokenMemory = null;
    await _delete(_accessTokenKey);
  }

  Future<void> _write(String key, String value) async {
    // Always persist to SharedPreferences as a reliable backup.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}

    if (kIsWeb) return;

    try {
      await _secure.write(key: key, value: value);
    } catch (_) {
      // Prefs already has the value.
    }
  }

  Future<String?> _read(String key) async {
    if (!kIsWeb) {
      try {
        final secureValue = await _secure.read(key: key);
        if (secureValue != null && secureValue.isNotEmpty) {
          return secureValue;
        }
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _delete(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}

    if (kIsWeb) return;

    try {
      await _secure.delete(key: key);
    } catch (_) {}
  }
}
