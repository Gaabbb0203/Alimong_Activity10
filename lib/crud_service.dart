import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class PickedImage {
  final File? file;
  final String url;
  PickedImage({this.file, required this.url});
}

class CrudService {
  final CollectionReference items =
      FirebaseFirestore.instance.collection('items');

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'pcuikmvz',
    'flutter_notes_preset',
    cache: false,
  );

  final ImagePicker _picker = ImagePicker();

  Future<PickedImage?> pickImageForAddItem() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: pickedFile.name,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return PickedImage(url: response.secureUrl);
    } else {
      final file = File(pickedFile.path);
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return PickedImage(file: file, url: response.secureUrl);
    }
  }

  //CREATE
  Future<void> addItemWithImage(
      String name, int quantity, String? imageUrl) async {
    await items.add({
      'name': name,
      'quantity': quantity,
      'image_url': imageUrl,
      'isFavorite': false,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> addItem(String name, int quantity) {
    //CREATE
    return items.add({
      'name': name,
      'quantity': quantity,
      'isFavorite': false,
      'createdAt': Timestamp.now(),
    });
  }

  //READ
  Stream<QuerySnapshot> getItems() {
    return items.orderBy('createdAt', descending: true).snapshots();
  }

  //UPDATE
  Future<void> updateItem(String id, String name, int quantity) {
    return items.doc(id).update({
      'name': name,
      'quantity': quantity,
    });
  }

  //TOGGLE FAVORITE
  Future<void> toggleFavorite(String id, bool currentStatus) {
    return items.doc(id).update({
      'isFavorite': !currentStatus,
    });
  }

  //DELETE
  Future<void> deleteItem(String id) {
    return items.doc(id).delete();
  }
}
