import 'package:get/get.dart';
import 'manage_doctors_controller.dart';

class ManageDoctorsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManageDoctorsController>(() => ManageDoctorsController());
  }
}
