import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

Future<Uint8List?> pickWebImage() async {
  if (!kIsWeb) return null;

  final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/*';
  uploadInput.click();

  final completer = Completer<Uint8List?>();
  uploadInput.onChange.listen((event) {
    if (uploadInput.files!.isNotEmpty) {
      final file = uploadInput.files!.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) {
        completer.complete(reader.result as Uint8List);
      });
    }
  });

  return completer.future;
}
