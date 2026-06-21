import 'package:get/get.dart';
import 'admin_doctor_leaves_controller.dart';

class AdminDoctorLeavesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDoctorLeavesController>(
      () => AdminDoctorLeavesController(),
    );
  }
}
