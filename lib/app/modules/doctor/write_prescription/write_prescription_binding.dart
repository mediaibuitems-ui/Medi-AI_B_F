import 'package:get/get.dart';
import 'write_prescription_controller.dart';
import '../dashboard/doctor_dashboard_controller.dart';

class WritePrescriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WritePrescriptionController>(() => WritePrescriptionController());
    if (!Get.isRegistered<DoctorDashboardController>()) {
      Get.lazyPut(() => DoctorDashboardController(), fenix: true);
    }
  }
}
