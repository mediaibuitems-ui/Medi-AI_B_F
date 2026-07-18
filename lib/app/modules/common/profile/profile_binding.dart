import 'package:get/get.dart';
import '../../../../app/services/doctor_service.dart';
import 'profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<DoctorService>(() => DoctorService());
  }
}
