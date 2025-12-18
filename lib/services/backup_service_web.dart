import 'dart:html' as html;
import 'dart:typed_data';

/// Web-specific implementation for file download
Future<void> downloadFileWeb(Uint8List data, String fileName) async {
  final blob = html.Blob([data]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

