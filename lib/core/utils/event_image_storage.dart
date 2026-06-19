import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EventImageStorageException implements Exception {
  const EventImageStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EventImageStorage {
  static const String bucketName = 'donor-pmi-nias.firebasestorage.app';
  static const int maxPosterImageBytes = 5 * 1024 * 1024;

  static bool isAllowedImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  static Future<String> uploadPosterImage({
    required File imageFile,
    String? eventId,
  }) async {
    if (!isAllowedImagePath(imageFile.path)) {
      throw const EventImageStorageException(
        'Format gambar harus JPG, JPEG, PNG, atau WEBP.',
      );
    }

    final fileSize = await imageFile.length();
    if (fileSize > maxPosterImageBytes) {
      throw const EventImageStorageException(
        'Ukuran gambar maksimal 5 MB.',
      );
    }

    var signedInForUpload = false;
    try {
      signedInForUpload = await _ensureStorageAuth();
      final extension = _storageExtensionForImage(imageFile.path);
      final fileName = _buildFileName(extension, eventId: eventId);
      final objectPath = 'poster_acara/$fileName';
      final ref = FirebaseStorage.instanceFor(bucket: 'gs://$bucketName')
          .ref(objectPath);
      await ref.putFile(
        imageFile,
        SettableMetadata(contentType: _contentTypeForImage(imageFile.path)),
      );
      return publicUrlForPath(objectPath);
    } on FirebaseException catch (e) {
      throw EventImageStorageException(_friendlyFirebaseError(e));
    } finally {
      if (signedInForUpload &&
          FirebaseAuth.instance.currentUser?.isAnonymous == true) {
        await FirebaseAuth.instance.signOut();
      }
    }
  }

  static String publicUrlForPath(String objectPath) {
    return Uri.https(
      'storage.googleapis.com',
      '/$bucketName/$objectPath',
    ).toString();
  }

  static Future<bool> _ensureStorageAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return false;

    try {
      await FirebaseAuth.instance.signInAnonymously();
      return true;
    } on FirebaseAuthException catch (e) {
      throw EventImageStorageException(_friendlyFirebaseError(e));
    }
  }

  static String _friendlyFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'admin-restricted-operation':
      case 'operation-not-allowed':
        return 'Upload gambar belum aktif. Aktifkan Anonymous sign-in di Firebase Authentication agar admin bisa upload poster acara.';
      case 'unauthorized':
        return 'Upload gambar ditolak oleh Storage Rules. Izinkan write ke folder poster_acara untuk user yang sudah login.';
      case 'canceled':
        return 'Upload gambar dibatalkan.';
      default:
        final message = error.message;
        if (message == null || message.trim().isEmpty) {
          return 'Gagal upload gambar: ${error.code}';
        }
        return 'Gagal upload gambar: $message';
    }
  }

  static String _buildFileName(String extension, {String? eventId}) {
    final safeEventId = _safeSegment(eventId ?? 'acara');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${safeEventId}_$timestamp.$extension';
  }

  static String _safeSegment(String value) {
    final safe = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (safe.isEmpty) return 'acara';
    return safe;
  }

  static String _contentTypeForImage(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static String _storageExtensionForImage(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpg';
  }
}
