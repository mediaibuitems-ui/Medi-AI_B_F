import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../../app/widgets/app_feedback.dart';

class AdminVerificationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final RxList<Map<String, dynamic>> pendingUsers = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadPendingVerifications();
  }

  Future<void> loadPendingVerifications() async {
    isLoading.value = true;
    try {
      final response = await _apiService.get('/Admin/pending-verifications');
      if (response.success && response.data != null) {
        pendingUsers.value = List<Map<String, dynamic>>.from(response.data);
      } else {
        AppFeedback.error('Error', 'Failed to load pending verifications');
      }
    } catch (e) {
      AppFeedback.error('Error', 'Error loading pending verifications');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveUser(int userId) async {
    try {
      final response = await _apiService.put('/Admin/verify-user/$userId', data: {});
      if (response.success) {
        pendingUsers.removeWhere((u) => u['id'] == userId);
        AppFeedback.success('Success', 'User approved and verified successfully');
      } else {
        AppFeedback.error('Error', response.message.isNotEmpty ? response.message : 'Failed to approve user');
      }
    } catch (e) {
      AppFeedback.error('Error', 'Error approving user');
    }
  }

  Future<void> rejectUser(int userId) async {
    try {
      // Typically we'd delete the user or mark them rejected
      final response = await _apiService.delete('/Admin/users/$userId');
      if (response.success) {
        pendingUsers.removeWhere((u) => u['id'] == userId);
        AppFeedback.success('Success', 'User rejected and removed');
      } else {
        AppFeedback.error('Error', response.message.isNotEmpty ? response.message : 'Failed to reject user');
      }
    } catch (e) {
      AppFeedback.error('Error', 'Error rejecting user');
    }
  }
}
