import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';

Future<void> downloadFile(String content, String filename) async {
  try {
    Directory? directory;
    if (Platform.isAndroid) {
      // Use Downloads directory on Android so users can easily find it
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    
    if (directory != null) {
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);
      Get.snackbar(
        'Report Saved!',
        'Saved to: ${file.path}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  } catch (e) {
    Get.snackbar(
      'Error',
      'Could not save report: $e',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
