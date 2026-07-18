import 'package:get/get.dart';

import '../../../../app/services/storage_service.dart';

class ProfileController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  final RxBool isNotificationsMuted = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotificationSettings();
  }

  void loadNotificationSettings() {
    isNotificationsMuted.value = _storageService.isNotificationsMuted;
  }

  Future<void> setNotificationsMuted(bool muted) async {
    isNotificationsMuted.value = muted;
    await _storageService.setNotificationsMuted(muted);
  }
}
