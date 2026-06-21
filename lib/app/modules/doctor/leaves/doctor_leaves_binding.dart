import 'package:get/get.dart';
import 'doctor_leaves_controller.dart';

class DoctorLeavesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DoctorLeavesController>(
      () => DoctorLeavesController(),
    );
  }
}
