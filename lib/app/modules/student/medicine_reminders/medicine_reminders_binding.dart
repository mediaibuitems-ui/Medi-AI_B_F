import 'package:get/get.dart';
import '../../../services/medicine_reminder_service.dart';
import '../../../services/notification_service.dart';

class MedicineRemindersBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MedicineReminderService>()) {
      Get.lazyPut(() => MedicineReminderService(), fenix: true);
    }
    if (!Get.isRegistered<NotificationService>()) {
      Get.lazyPut(() => NotificationService(), fenix: true);
    }
  }
}
