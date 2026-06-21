import 'package:get/get.dart';
import 'admin_verifications_controller.dart';

class AdminVerificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminVerificationController>(() => AdminVerificationController());
  }
}
