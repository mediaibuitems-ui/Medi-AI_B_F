import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:medi_ai/app/services/api_service.dart';
import 'package:medi_ai/app/data/models/api_response.dart';

class VerificationRequest {
  final int id;
  final int userId;
  final String documentUrl;
  final String status;
  final String? adminNotes;
  final String? submittedAt;
  final String? reviewedAt;

  VerificationRequest({
    required this.id,
    required this.userId,
    required this.documentUrl,
    required this.status,
    this.adminNotes,
    this.submittedAt,
    this.reviewedAt,
  });

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    return VerificationRequest(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      documentUrl: json['documentUrl'] ?? '',
      status: json['status'] ?? 'Pending',
      adminNotes: json['adminNotes'],
      submittedAt: json['submittedAt'],
      reviewedAt: json['reviewedAt'],
    );
  }
}

class VerificationService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  // --- USER ENDPOINTS ---

  /// Submits a verification request with an image file.
  Future<ApiResponse> submitVerification(String imagePath) async {
    final formData = dio.FormData.fromMap({
      'DocumentImage': await dio.MultipartFile.fromFile(imagePath, filename: 'document.jpg'),
    });

    return await _apiService.post(
      '/Users/verification/submit',
      data: formData,
    );
  }

  /// Gets the current user's verification status
  Future<VerificationRequest?> getMyVerificationStatus() async {
    final response = await _apiService.get('/Users/verification/status');
    if (response.success && response.data != null) {
      return VerificationRequest.fromJson(response.data!);
    }
    return null;
  }

  // --- ADMIN ENDPOINTS ---

  /// Gets all pending verification requests
  Future<List<VerificationRequest>> getPendingVerifications() async {
    final response = await _apiService.get('/Admin/verifications');
    if (response.success && response.data != null) {
      final List<dynamic> data = response.data!;
      return data.map((json) => VerificationRequest.fromJson(json)).toList();
    }
    return [];
  }

  /// Approves a verification request
  Future<ApiResponse> approveVerification(int id) async {
    return await _apiService.post('/Admin/verifications/$id/approve');
  }

  /// Rejects a verification request with notes
  Future<ApiResponse> rejectVerification(int id, String adminNotes) async {
    return await _apiService.post(
      '/Admin/verifications/$id/reject',
      data: {'adminNotes': adminNotes},
    );
  }
}
