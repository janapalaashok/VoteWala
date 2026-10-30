import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Why a photo was refused (message keys in l10n/strings.dart).
class PhotoRejected implements Exception {
  const PhotoRejected(this.messageKey);

  final String messageKey;
}

/// Largest photo accepted from the phone or computer.
const maxInputBytes = 15 * 1024 * 1024;

/// Opens the camera or gallery; returns a privacy-safe JPEG, or null when the
/// voter cancels. Throws [PhotoRejected] for unsupported or oversized files.
Future<Uint8List?> pickEvidencePhoto({required bool camera}) async {
  final file = await ImagePicker().pickImage(source: camera ? ImageSource.camera : ImageSource.gallery);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return prepareEvidencePhoto(bytes);
}

/// Accepts JPEG, PNG or WebP up to 15 MB. Returns a JPEG at most 1280 px on
/// the long side, re-encoded so EXIF data (GPS location, phone model) is
/// dropped.
Uint8List prepareEvidencePhoto(Uint8List bytes) {
  if (bytes.length > maxInputBytes) throw const PhotoRejected('photoTooLarge');
  final format = img.findFormatForData(bytes);
  if (format != img.ImageFormat.jpg && format != img.ImageFormat.png && format != img.ImageFormat.webp) {
    throw const PhotoRejected('photoFormat');
  }
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const PhotoRejected('photoFormat');
  var image = img.bakeOrientation(decoded);
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > 1280) {
    image = image.width >= image.height ? img.copyResize(image, width: 1280) : img.copyResize(image, height: 1280);
  }
  image.exif = img.ExifData();
  return img.encodeJpg(image, quality: 80);
}
