import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../data/models/user.dart';
import '../data/models/api_response.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../widgets/app_feedback.dart';
import '../data/models/app_roles.dart';

class AuthService extends GetxService {
  final _apiService = Get.find<ApiService>();
  final _storageService = Get.find<StorageService>();
  final _logger = Logger();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isAuthenticated = false.obs;

  Future<AuthService> init() async {
    await _loadUser();
    return this;
  }

  Future<void> _loadUser() async {
    final user = await _storageService.getUser();
    if (user != null) {
      currentUser.value = user;
      isAuthenticated.value = true;
    }
  }

  // Register
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? department,
    String? cmsId,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? specialization,
    String? licenseNumber,
    String? qualification,
    int? experience,
    String? roomNumber,
    String? bio,
  }) async {
    final requestData = {
      'Email': email,
      'Password': password,
      'FullName': name, // Backend C# property uses FullName (no space)
      'Role': role,
      'Department': department,
      'RegistrationNumber': cmsId,
      'PhoneNumber': phoneNumber,
      'DateOfBirth': dateOfBirth,
      'Gender': gender,
      'Address': address,
      'Specialization': specialization,
      'LicenseNumber': licenseNumber,
      'Qualification': qualification,
      'Experience': experience,
      'RoomNumber': roomNumber,
      'Bio': bio,
    };

    _logger.d('Sending registration request for role: $role');

    final response = await _apiService.post<Map<String, dynamic>>(
      '/Auth/register',
      data: requestData,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    return response;
  }

  // Resend OTP
  Future<ApiResponse<dynamic>> resendOtp(String email) async {
    return await _apiService.post(
      '/Auth/resend-otp',
      data: {'Email': email},
    );
  }

  // Verify OTP
  Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/Auth/verify-otp',
      data: {
        'Email': email,
        'Otp': otp,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      await _saveAuthData(response.data!);
    }

    return response;
  }

  // Login
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/Auth/login',
      data: {
        'email': email,
        'password': password,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      await _saveAuthData(response.data!);
    }

    return response;
  }

  // Save auth data
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    // Support both camelCase and PascalCase response payloads.
    final token = data['token'] ??
        data['Token'] ??
        data['accessToken'] ??
        data['AccessToken'];
    final refreshToken = data['refreshToken'] ??
        data['RefreshToken'] ??
        data['refresh_token'] ??
        data['Refresh_Token'];

    if (token is String && token.isNotEmpty) {
      await _storageService.saveAccessToken(token);
      _logger.d('Access token saved successfully.');
    } else {
      _logger.w(
          'No valid access token found in auth response. Keys: ${data.keys.toList()}');
    }
    if (refreshToken is String && refreshToken.isNotEmpty) {
      await _storageService.saveRefreshToken(refreshToken);
    }

    // User may arrive nested (user/User) or flat (userId + role fields).
    final dynamic nestedUser = data['user'] ?? data['User'];
    if (nestedUser is Map) {
      final user = User.fromJson(Map<String, dynamic>.from(nestedUser));
      await _storageService.saveUser(user);
      currentUser.value = user;
      isAuthenticated.value = true;
      return;
    }

    final role = data['role'] ?? data['Role'];
    final userId = data['userId'] ?? data['UserId'] ?? data['id'] ?? data['Id'];
    if (role != null && userId != null) {
      final user = User(
        id: userId.toString(),
        email: (data['email'] ?? data['Email'] ?? '').toString(),
        name: (data['fullName'] ?? data['FullName'] ?? data['name'] ?? '')
            .toString(),
        role: role.toString(),
        department: (data['department'] ?? data['Department'])?.toString(),
        emailVerified: (data['isEmailVerified'] ??
                data['emailVerified'] ??
                data['IsEmailVerified'] ??
                false) ==
            true,
        cmsId: (data['registrationNumber'] ??
                data['RegistrationNumber'] ??
                data['cmsId'])
            ?.toString(),
        phone: (data['phoneNumber'] ?? data['PhoneNumber'] ?? data['phone'])
            ?.toString(),
      );
      await _storageService.saveUser(user);
      currentUser.value = user;
      isAuthenticated.value = true;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiService.post('/Auth/logout');
    } catch (e) {
      _logger.w('Logout API call failed (proceeding anyway): $e');
    }

    await _storageService.clearAuthData();
    currentUser.value = null;
    isAuthenticated.value = false;
    AppFeedback.info('Signed out', 'You have been logged out successfully.');

    // Clear all GetX controllers and services to prevent state/data leakage
    // Removing Get.deleteAll because it destroys services and currently active controllers
    // before the route transition completes, causing UI crashes and 'used after dispose' errors.
    // Get.offAllNamed naturally clears non-permanent controllers bound to the removed routes.

    // Reroute to splash to re-initialize core services fresh
    Get.offAllNamed('/login'); // Redirect to login directly, or splash
  }

  // Get current user from API
  Future<User?> getCurrentUser() async {
    // Return cached user if available
    if (currentUser.value != null) {
      return currentUser.value;
    }

    // Try to load from storage
    final storedUser = await _storageService.getUser();
    if (storedUser != null) {
      currentUser.value = storedUser;
      return storedUser;
    }

    // Try to fetch from API (when backend is available)
    try {
      final response = await _apiService.get<User>(
        '/Auth/current-user',
        fromJson: (json) => User.fromJson(json),
      );

      if (response.success && response.data != null) {
        await _storageService.saveUser(response.data!);
        currentUser.value = response.data;
        return response.data;
      }
    } catch (e) {
      // API not available, return stored user
    }

    return currentUser.value;
  }

  // Update profile
  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? phone,
    String? department,
  }) async {
    final response = await _apiService.put<User>(
      '/Users/profile',
      data: {
        'FullName': name,
        'PhoneNumber': phone,
        'Department': department,
      },
      fromJson: (json) => User.fromJson(json),
    );

    if (response.success && response.data != null) {
      await _storageService.saveUser(response.data!);
      currentUser.value = response.data;
    }

    return response;
  }

  /// Forgot Password â€” verifies email + phone number + CMS/registration number against DB.
  /// Returns reset token directly in response.data['resetToken'] â€” no email sent.
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({
    required String email,
    required String phoneNumber,
    required String registrationNumber,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      '/Auth/forgot-password',
      data: {
        'email': email,
        'phoneNumber': phoneNumber,
        'registrationNumber': registrationNumber,
      },
      fromJson: (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  /// Reset Password â€” submit the token received from forgot-password + new password.
  Future<ApiResponse<void>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    return await _apiService.post<void>(
      '/Auth/reset-password',
      data: {
        'email': email,
        'token': token,
        'newPassword': newPassword,
      },
      fromJson: (_) {},
    );
  }

  bool get isStudent => currentUser.value?.role == AppRoles.student;
  bool get isDoctor => currentUser.value?.role == AppRoles.doctor;
  bool get isAdmin => currentUser.value?.role == AppRoles.admin;
}
