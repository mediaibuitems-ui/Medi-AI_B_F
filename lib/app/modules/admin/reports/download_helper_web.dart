// Web-specific implementation using dart:html
import 'dart:html' as html;
import 'dart:convert';

Future<void> downloadFile(String content, String filename) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
