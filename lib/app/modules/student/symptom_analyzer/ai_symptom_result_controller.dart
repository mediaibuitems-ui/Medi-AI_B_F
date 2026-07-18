import 'package:get/get.dart';

class AiSymptomResultController extends GetxController {
  final Map<String, dynamic> resultData = Get.arguments ?? {};

  String get possibleCondition => resultData['possibleCondition'] ?? 'Unknown';
  String get confidenceLevel => resultData['confidenceLevel'] ?? 'N/A';
  String get severity => resultData['severity'] ?? 'Unknown';
  String get urgencyMessage => resultData['urgencyMessage'] ?? '';
  List<String> get recommendations =>
      List<String>.from(resultData['recommendations'] ?? []);
  List<String> get homeCareGuidance =>
      List<String>.from(resultData['homeCareGuidance'] ?? []);
  String get recommendedDoctorType =>
      resultData['recommendedDoctorType'] ?? 'General Physician';

  void bookAppointment() {
    // Navigate to the book appointment screen and pass the recommended doctor type if needed
    Get.toNamed('/student/book-appointment',
        arguments: {'doctorType': recommendedDoctorType});
  }
}
