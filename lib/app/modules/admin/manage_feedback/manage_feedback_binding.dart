import 'package:get/get.dart';

import 'manage_feedback_controller.dart';

class ManageFeedbackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManageFeedbackController>(() => ManageFeedbackController());
  }
}
