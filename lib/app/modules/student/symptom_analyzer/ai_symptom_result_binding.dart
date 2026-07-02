import 'package:get/get.dart';
import 'ai_symptom_result_controller.dart';

class AiSymptomResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiSymptomResultController>(() => AiSymptomResultController());
  }
}
