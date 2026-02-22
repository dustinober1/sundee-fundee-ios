import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class UserStorageService {
  UserStorageService({required FirebaseStorage storage}) : _storage = storage;

  final FirebaseStorage _storage;

  Future<Reference> uploadBytes({
    required String userId,
    required String path,
    required Uint8List bytes,
    SettableMetadata? metadata,
  }) async {
    final Reference ref = _storage.ref().child('users/$userId/$path');
    await ref.putData(bytes, metadata);
    return ref;
  }

  Future<String> getDownloadUrl({
    required String userId,
    required String path,
  }) {
    return _storage.ref().child('users/$userId/$path').getDownloadURL();
  }
}
