import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../../config/app_config.dart';

class AiSymptomHistoryController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final RxList<Map<String, dynamic>> history = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    error.value = '';

    try {
      final response = await _apiService.get('${AppConfig.baseUrl}/analyzer/history');
      if (response.success && response.data is List) {
        history.value = (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        error.value = response.message ?? 'Failed to load history';
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void viewResult(Map<String, dynamic> item) {
    // Map backend history fields to the format expected by AiSymptomResultController
    final mappedData = {
      'possibleCondition': item['possibleCondition'] ?? item['PossibleCondition'],
      'confidenceLevel': item['confidenceLevel'] ?? item['ConfidenceLevel'],
      'severity': item['calculatedSeverity'] ?? item['CalculatedSeverity'],
      'urgencyMessage': item['urgencyMessage'] ?? item['UrgencyMessage'],
      'recommendations': item['recommendations'] ?? item['Recommendations'] ?? [],
      'homeCareGuidance': item['homeCareGuidance'] ?? item['HomeCareGuidance'] ?? [],
      'recommendedDoctorType': item['recommendedDoctorType'] ?? item['RecommendedDoctorType'],
    };

    Get.toNamed('/student/ai-symptom-result', arguments: mappedData);
  }
}
