import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Environment toggle - prefer using `--dart-define=USE_LOCAL_BACKEND=true`
  // when running locally. This allows switching without changing source.
  static bool get useLocalBackend => const bool.fromEnvironment('USE_LOCAL_BACKEND', defaultValue: false);
  static bool get usePhysicalDevice => const bool.fromEnvironment('USE_PHYSICAL_DEVICE', defaultValue: true);

  // Local development base URLs
  static const String _localWebBase = 'http://localhost:5281/api';
  static const String _localHttpBase = 'http://10.0.2.2:5281/api';
  static const String _localPhysicalBase = 'http://192.168.100.111:5281/api';

  // Production base URL
  static const String _productionBase = 'https://medi-aibf-production.up.railway.app/api';

  // Allow overriding the API base at compile/run time using --dart-define=API_BASE_URL
  static String get _overrideBase => const String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_overrideBase.isNotEmpty) return _overrideBase;
    if (useLocalBackend) {
      if (kIsWeb) return _localWebBase;
      return usePhysicalDevice ? _localPhysicalBase : _localHttpBase;
    }
    // Production fallback
    return _productionBase;
  }

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // JWT Configuration
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // BUITEMS Configuration
  static const String allowedEmailDomain = '@student.buitms.edu.pk';
  static const String universityName = 'BUITEMS Medical Center';

  // App Info
  static const String appName = 'Medi-AI';
  static const String appVersion = '1.0.0';

  // Cache/Notification Config
  static const Duration cacheMaxAge = Duration(minutes: 5);
  static const String fcmTopicAll = 'all_users';
  static const String fcmTopicStudents = 'students';
  static const String fcmTopicDoctors = 'doctors';

  // API Endpoints
  static String get authLoginEndpoint => '$baseUrl/Auth/login';
  static String get authRegisterEndpoint => '$baseUrl/Auth/register';
  static String get authSendOtpEndpoint => '$baseUrl/Auth/send-otp';
  static String get authVerifyOtpEndpoint => '$baseUrl/Auth/verify-otp';
  static String get authRefreshTokenEndpoint => '$baseUrl/Auth/refresh-token';
}

//flutter run --dart-define=USE_LOCAL_BACKEND=true