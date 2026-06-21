import 'package:get/get.dart';
import 'manage_users_controller.dart';

class ManageUsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManageUsersController>(() => ManageUsersController());
  }
}
