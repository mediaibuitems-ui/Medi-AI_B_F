import 'package:get/get.dart';
import 'doctor_settings_controller.dart';

class DoctorSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DoctorSettingsController>(() => DoctorSettingsController());
  }
}
