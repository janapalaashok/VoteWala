import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'file_pick.dart';

Future<PickedFile?> pickImageFile() {
  final completer = Completer<PickedFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/png,image/jpeg,image/webp,image/svg+xml';
  input.onchange = (web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      completer.complete(null);
      return;
    }
    file.arrayBuffer().toDart.then((buffer) {
      completer.complete(PickedFile(file.name, buffer.toDart.asUint8List(), file.type.isEmpty ? 'image/png' : file.type));
    });
  }.toJS;
  input.click();
  return completer.future;
}

void downloadText(String filename, String text) {
  final blob = web.Blob([text.toJS].toJS, web.BlobPropertyBag(type: 'application/json'));
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
}

void openAdminConsole() {
  web.window.location.hash = '/admin';
  web.window.location.reload();
}
