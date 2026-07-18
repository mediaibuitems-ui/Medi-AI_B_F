import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../../app/widgets/app_feedback.dart';

class AdminVerificationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final RxList<Map<String, dynamic>> pendingUsers =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  final RxBool isLoadingMore = false.obs;
  int currentPage = 1;
  final int limit = 20;
  bool hasMore = true;

  @override
  void onInit() {
    super.onInit();
    loadPendingVerifications(refresh: true);
  }

  Future<void> loadPendingVerifications({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      hasMore = true;
      pendingUsers.clear();
      isLoading.value = true;
    } else {
      if (!hasMore || isLoadingMore.value || isLoading.value) return;
      isLoadingMore.value = true;
    }

    try {
      final response = await _apiService.get('/Admin/pending-verifications?page=$currentPage&limit=$limit');
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

        if (refresh) {
          pendingUsers.value = items;
        } else {
          pendingUsers.addAll(items);
        }

        if (items.length < limit) {
          hasMore = false;
        } else {
          currentPage++;
        }
      } else {
        AppFeedback.error('Error', 'Failed to load pending verifications');
      }
    } catch (e) {
      AppFeedback.error('Error', 'Error loading pending verifications');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> approveUser(int userId) async {
    try {
      final response =
          await _apiService.put('/Admin/verify-user/$userId', data: {});
      if (response.success) {
        pendingUsers.removeWhere((u) => u['id'] == userId);
        AppFeedback.success(
            'Success', 'User approved and verified successfully');
      } else {
        AppFeedback.error(
            'Error',
            response.message.isNotEmpty
                ? response.message
                : 'Failed to approve user');
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
        AppFeedback.error(
            'Error',
            response.message.isNotEmpty
                ? response.message
                : 'Failed to reject user');
      }
    } catch (e) {
      AppFeedback.error('Error', 'Error rejecting user');
    }
  }
}
