import 'package:get/get.dart';
import 'ai_symptom_history_controller.dart';

class AiSymptomHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiSymptomHistoryController>(() => AiSymptomHistoryController());
  }
}
