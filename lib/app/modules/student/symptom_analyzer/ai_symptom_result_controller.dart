import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

class AiSymptomResultController extends GetxController {
  final Map<String, dynamic> rawData = Get.arguments ?? {};
  
  Map<String, dynamic> get analysisData => rawData.containsKey('analysis') 
      ? (rawData['analysis'] as Map<String, dynamic>) 
      : rawData;

  String get summary => analysisData['summary'] ?? '';
  String get possibleCondition => analysisData['possibleCondition'] ?? 'Unknown';
  String get confidenceLevel => analysisData['confidenceLevel'] ?? 'N/A';
  String get severity => analysisData['severity'] ?? 'Unknown';
  String get urgencyMessage => analysisData['urgencyMessage'] ?? '';
  String get triageTier => analysisData['triageTier'] ?? 'self_care';
  String get whenToSeekCare => analysisData['whenToSeekCare'] ?? '';
  List<String> get recommendations => _parseStringList(analysisData['recommendations']);
  List<String> get homeCareGuidance => _parseStringList(analysisData['homeCareGuidance']);
  String get recommendedDoctorType => analysisData['recommendedDoctorType'] ?? 'General Physician';
  
  List<Map<String, String>> get transcript {
    if (rawData.containsKey('transcript')) {
       return (rawData['transcript'] as List).map((t) => {
         'question': t['question']?.toString() ?? '',
         'answer': t['answer']?.toString() ?? '',
       }).toList();
    }
    return [];
  }

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

  void bookAppointment() {
    Get.toNamed(AppRoutes.bookAppointment,
        arguments: {'doctorType': recommendedDoctorType});
  }
}
