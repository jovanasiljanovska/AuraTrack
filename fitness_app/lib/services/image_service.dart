import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

enum ImageSource_ { camera, gallery }

class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Pick an image, compress it heavily, return base64 string.
  /// Returns null if the user cancels.
  ///
  /// Designed for storing profile photos in Firestore (1 MB doc limit),
  /// so we target ~50 KB output.
  Future<String?> pickAndCompressAsBase64({
    required ImageSource_ source,
    int maxWidth = 400,
    int maxHeight = 400,
    int quality = 70,
  }) async {
    final XFile? file = await _picker.pickImage(
      source: source == ImageSource_.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: quality,
    );

    if (file == null) return null;

    // Second-pass compression to make sure we're well under Firestore's limit.
    final compressed = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    final bytes = compressed ?? await File(file.path).readAsBytes();
    return base64Encode(bytes);
  }
}