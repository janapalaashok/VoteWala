import 'dart:typed_data';

import 'file_pick_stub.dart' if (dart.library.js_interop) 'file_pick_web.dart' as impl;

class PickedFile {
  const PickedFile(this.name, this.bytes, this.contentType);

  final String name;
  final Uint8List bytes;
  final String contentType;
}

/// Opens the browser's file chooser (admin panel runs on the web only).
Future<PickedFile?> pickImageFile() => impl.pickImageFile();

/// Triggers a browser download (used for config backups).
void downloadText(String filename, String text) => impl.downloadText(filename, text);

/// Saves [bytes] as a download on the web; returns false elsewhere (the
/// apps share the file instead).
bool downloadBytes(String filename, Uint8List bytes, String contentType) =>
    impl.downloadBytes(filename, bytes, contentType);

/// Reloads the website into the admin console (web only).
void openAdminConsole() => impl.openAdminConsole();
