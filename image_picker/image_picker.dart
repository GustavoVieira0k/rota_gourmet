import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(File) onImageSelected;

  const ImagePickerWidget({super.key, required this.onImageSelected});

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      widget.onImageSelected(_image!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _image != null
            ? Image.file(_image!, height: 150, width: 150, fit: BoxFit.cover)
            : const Icon(Icons.image, size: 100, color: Colors.grey),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text("Galeria"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: const Text("Câmera"),
            ),
          ],
        ),
      ],
    );
  }
}
