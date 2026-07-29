import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

class AiSymptomResultController extends GetxController {
  final Map<String, dynamic> resultData = Get.arguments ?? {};

  String get possibleCondition => resultData['possibleCondition'] ?? 'Unknown';
  String get confidenceLevel => resultData['confidenceLevel'] ?? 'N/A';
  String get severity => resultData['severity'] ?? 'Unknown';
  String get urgencyMessage => resultData['urgencyMessage'] ?? '';
  String get triageTier => resultData['triageTier'] ?? 'self_care';
  String get whenToSeekCare => resultData['whenToSeekCare'] ?? '';
  List<String> get recommendations => _parseStringList(resultData['recommendations']);
  List<String> get homeCareGuidance => _parseStringList(resultData['homeCareGuidance']);

  List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    if (data is String) {
      return [data];
    }
    return [];
  }
  String get recommendedDoctorType =>
      resultData['recommendedDoctorType'] ?? 'General Physician';

  void bookAppointment() {
    // Navigate to the book appointment screen and pass the recommended doctor type if needed
    Get.toNamed(AppRoutes.bookAppointment,
        arguments: {'doctorType': recommendedDoctorType});
  }
}
