import 'package:get/get.dart';
import 'ai_symptom_input_controller.dart';

class AiSymptomInputBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiSymptomInputController>(() => AiSymptomInputController());
  }
}
