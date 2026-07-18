import 'package:get/get.dart';
import '../../../services/doctor_service.dart';

class PatientsController extends GetxController {
  final _doctorService = Get.find<DoctorService>();

  final RxList<Map<String, dynamic>> patients = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredPatients =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPatients();
  }

  Future<void> loadPatients() async {
    isLoading.value = true;
    try {
      final response = await _doctorService.getPatients();
      if (response.success && response.data != null) {
        patients.value = response.data!
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        applySearch();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load patients');
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    applySearch();
  }

  void applySearch() {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) {
      filteredPatients.value = List<Map<String, dynamic>>.from(patients);
      return;
    }

    filteredPatients.value = patients.where((patient) {
      final name = (patient['fullName'] ?? patient['FullName'] ?? '')
          .toString()
          .toLowerCase();
      final cms = (patient['registrationNumber'] ??
              patient['RegistrationNumber'] ??
              patient['cmsNumber'] ??
              patient['CmsNumber'] ??
              '')
          .toString()
          .toLowerCase();
      return name.contains(q) || cms.contains(q);
    }).toList();
  }
}
