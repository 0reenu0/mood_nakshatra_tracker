import 'dart:typed_data';

/// Stub implementation for non-web platforms
Future<void> downloadFileWeb(Uint8List data, String fileName) async {
  throw UnsupportedError('Download is only supported on web');
}

