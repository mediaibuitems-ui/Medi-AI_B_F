import 'package:get/get.dart';
import 'ai_symptom_chat_controller.dart';

class AiSymptomChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiSymptomChatController>(() => AiSymptomChatController());
  }
}
