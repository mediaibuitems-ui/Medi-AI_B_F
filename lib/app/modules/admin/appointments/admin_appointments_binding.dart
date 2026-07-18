import 'package:get/get.dart';
import 'admin_appointments_controller.dart';

class AdminAppointmentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminAppointmentsController>(
        () => AdminAppointmentsController());
  }
}
