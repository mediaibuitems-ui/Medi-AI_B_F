import 'package:get/get.dart';
import 'health_analyzer_controller.dart';

class HealthAnalyzerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HealthAnalyzerController>(() => HealthAnalyzerController());
  }
}
