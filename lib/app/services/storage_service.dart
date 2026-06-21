import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../data/models/user.dart';
import '../../config/app_config.dart';

class StorageService extends GetxService {
  FlutterSecureStorage? _secureStorage;
  late final SharedPreferences _prefs;
  static const String _notificationsMutedKey = 'isNotificationsMuted';

  Future<StorageService> init() async {
    // On web, use SharedPreferences for everything. On mobile, use secure storage.
    if (!kIsWeb) {
      _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );
    }
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // Secure Storage (JWT Tokens)
  Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      await _prefs.setString(AppConfig.accessTokenKey, token);
    } else {
      await _secureStorage!.write(key: AppConfig.accessTokenKey, value: token);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      return _prefs.getString(AppConfig.accessTokenKey);
    } else {
      return await _secureStorage!.read(key: AppConfig.accessTokenKey);
    }
  }

  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      await _prefs.setString(AppConfig.refreshTokenKey, token);
    } else {
      await _secureStorage!.write(key: AppConfig.refreshTokenKey, value: token);
    }
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      return _prefs.getString(AppConfig.refreshTokenKey);
    } else {
      return await _secureStorage!.read(key: AppConfig.refreshTokenKey);
    }
  }

  Future<void> saveUser(User user) async {
    if (kIsWeb) {
      await _prefs.setString(AppConfig.userDataKey, jsonEncode(user.toJson()));
    } else {
      await _secureStorage!.write(
        key: AppConfig.userDataKey,
        value: jsonEncode(user.toJson()),
      );
    }
  }

  Future<User?> getUser() async {
    String? userData;
    if (kIsWeb) {
      userData = _prefs.getString(AppConfig.userDataKey);
    } else {
      userData = await _secureStorage!.read(key: AppConfig.userDataKey);
    }
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  Future<void> clearAuthData() async {
    if (kIsWeb) {
      await _prefs.remove(AppConfig.accessTokenKey);
      await _prefs.remove(AppConfig.refreshTokenKey);
      await _prefs.remove(AppConfig.userDataKey);
    } else {
      await _secureStorage!.delete(key: AppConfig.accessTokenKey);
      await _secureStorage!.delete(key: AppConfig.refreshTokenKey);
      await _secureStorage!.delete(key: AppConfig.userDataKey);
    }
  }

  // Onboarding
  Future<void> setOnboardingComplete() async {
    await _prefs.setBool('onboarding_complete', true);
  }

  bool isOnboardingComplete() {
    return _prefs.getBool('onboarding_complete') ?? false;
  }

  // FCM Token
  Future<void> saveFcmToken(String token) async {
    await _prefs.setString('fcm_token', token);
  }

  String? getFcmToken() {
    return _prefs.getString('fcm_token');
  }

  // Remember Me
  Future<void> saveRememberMeEmail(String email) async {
    await _prefs.setString('remember_me_email', email);
  }

  String? getRememberMeEmail() {
    return _prefs.getString('remember_me_email');
  }

  Future<void> removeRememberMeEmail() async {
    await _prefs.remove('remember_me_email');
  }

  // Local notification preferences
  bool get isNotificationsMuted {
    return _prefs.getBool(_notificationsMutedKey) ?? false;
  }

  Future<void> setNotificationsMuted(bool muted) async {
    await _prefs.setBool(_notificationsMutedKey, muted);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all data
  Future<void> clearAll() async {
    if (!kIsWeb) {
      await _secureStorage!.deleteAll();
    }
    await _prefs.clear();
  }
}
