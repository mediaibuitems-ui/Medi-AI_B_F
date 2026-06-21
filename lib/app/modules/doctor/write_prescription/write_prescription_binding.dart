import 'package:get/get.dart';
import '../dashboard/doctor_dashboard_controller.dart';

class WritePrescriptionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DoctorDashboardController>()) {
      Get.lazyPut(() => DoctorDashboardController(), fenix: true);
    }
  }
}
