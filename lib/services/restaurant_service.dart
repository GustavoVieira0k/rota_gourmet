import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class RestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> saveRestaurant(
    String userId,
    String name,
    String description,
    String cuisine,
    String price,
    String location,
    String contact,
    String instagram,
    TimeOfDay openingTime,
    TimeOfDay closingTime,
    List<int> daysOpen,
    List<File> mobileImages,
    List<Uint8List> webImages,
  ) async {
    List<String> imageUrls = await _uploadImages(mobileImages, webImages);

    try {
      await _firestore.collection('restaurants').add({
        'ownerId': userId,
        'name': name,
        'description': description,
        'cuisine': cuisine,
        'price': price,
        'location': location,
        'contact': contact,
        'instagram': instagram,
        'openingTime': '${openingTime.hour}:${openingTime.minute}',
        'closingTime': '${closingTime.hour}:${closingTime.minute}',
        'daysOpen': daysOpen,
        'images': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("✅ Restaurante salvo com sucesso!");
    } catch (e) {
      print("❌ Erro ao salvar no Firestore: $e");
    }
  }

  Future<List<String>> _uploadImages(
      List<File> mobileImages, List<Uint8List> webImages) async {
    List<String> imageUrls = [];

    for (var image in mobileImages) {
      try {
        Uint8List bytes = await image.readAsBytes();
        String url = await _uploadFile(bytes, isWeb: false);
        imageUrls.add(url);
      } catch (e) {
        print("❌ Erro ao fazer upload da imagem (mobile): $e");
      }
    }

    for (var webImage in webImages) {
      try {
        String url = await _uploadFile(webImage, isWeb: true);
        imageUrls.add(url);
      } catch (e) {
        print("❌ Erro ao fazer upload da imagem (web): $e");
      }
    }

    return imageUrls;
  }

  Future<String> _uploadFile(Uint8List fileData, {bool isWeb = false}) async {
    String fileName =
        'restaurants/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = _storage.ref().child(fileName);
    UploadTask uploadTask = ref.putData(fileData);

    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  bool isRestaurantOpen(
      String openingTime, String closingTime, List<int> daysOpen) {
    DateTime now = DateTime.now();
    int today = now.weekday % 7; // Firebase salva dias como [0 = Dom, 6 = Sáb]

    if (!daysOpen.contains(today)) {
      return false; // Se o restaurante não abre hoje, retorna fechado
    }

    List<String> openParts = openingTime.split(':');
    List<String> closeParts = closingTime.split(':');

    int openHour = int.parse(openParts[0]);
    int openMinute = int.parse(openParts[1]);
    int closeHour = int.parse(closeParts[0]);
    int closeMinute = int.parse(closeParts[1]);

    DateTime openTime =
        DateTime(now.year, now.month, now.day, openHour, openMinute);
    DateTime closeTime =
        DateTime(now.year, now.month, now.day, closeHour, closeMinute);

    return now.isAfter(openTime) && now.isBefore(closeTime);
  }

  updateRestaurant(String restaurantId, String text, String text2, String text3, String s, String text4, String text5, String text6, TimeOfDay timeOfDay, TimeOfDay timeOfDay2, List<int> daysOpen, List<String> existingImages, List<File> newImages, List<Uint8List> newWebImages) {}
}
