import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';

Future<void> downloadFile(String content, String filename) async {
  try {
    Directory? directory;
    String finalPath = '';

    if (Platform.isAndroid) {
      // Direct write to public Downloads folder (allowed without permissions for new files on Android 10+)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFilename = filename.replaceAll('.csv', '_$timestamp.csv');
      finalPath = '/storage/emulated/0/Download/$safeFilename';
    } else {
      directory = await getApplicationDocumentsDirectory();
      finalPath = '${directory.path}/$filename';
    }
    
    final file = File(finalPath);
    await file.writeAsString(content);
    
    Get.snackbar(
      'Report Saved Successfully!',
      'Saved in your Downloads folder:\n$finalPath',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 8),
      backgroundColor: const Color(0xFF4CAF50),
      colorText: const Color(0xFFFFFFFF),
    );
  } catch (e) {
    Get.snackbar(
      'Error Saving Report',
      'Please ensure you have enough storage space. Error: $e',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }
}
