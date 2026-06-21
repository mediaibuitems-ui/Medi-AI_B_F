import 'package:get/get.dart';
import 'doctor_profile_controller.dart';

class DoctorProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DoctorProfileController>(() => DoctorProfileController());
  }
}
