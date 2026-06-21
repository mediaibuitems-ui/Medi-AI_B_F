import 'package:get/get.dart';
import '../../../../app/services/auth_service.dart';
import '../../../../app/services/storage_service.dart';

class DoctorSettingsController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxBool isNotificationsMuted = false.obs;

  @override
  void onInit() {
    super.onInit();
    isNotificationsMuted.value = _storageService.isNotificationsMuted;
  }

  Future<void> setNotificationsMuted(bool muted) async {
    isNotificationsMuted.value = muted;
    await _storageService.setNotificationsMuted(muted);
  }

  void logout() {
    _authService.logout();
  }
}
