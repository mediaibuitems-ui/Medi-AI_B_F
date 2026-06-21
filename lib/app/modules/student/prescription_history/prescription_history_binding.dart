import 'package:get/get.dart';
import 'prescription_history_controller.dart';

class PrescriptionHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrescriptionHistoryController>(() => PrescriptionHistoryController());
  }
}
