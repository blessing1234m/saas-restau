import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageHandler {
  static final ImagePicker _picker = ImagePicker();

  /// Sélectionne une image et la convertit en base64
  static Future<String?> pickImageAsBase64({
    ImageSource source = ImageSource.gallery,
    int? maxWidthDp,
    int? maxHeightDp,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidthDp?.toDouble(),
        maxHeight: maxHeightDp?.toDouble(),
        imageQuality: imageQuality,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        return 'data:image/${image.mimeType?.split('/').last ?? 'jpeg'};base64,$base64String';
      }
    } catch (e) {
      print('[ImageHandler] Error picking image: $e');
    }
    return null;
  }

  /// Sélectionne plusieurs images et les convertit en base64
  static Future<List<String>> pickMultipleImagesAsBase64({
    ImageSource source = ImageSource.gallery,
    int maxImages = 3,
    int? maxWidthDp,
    int? maxHeightDp,
    int imageQuality = 85,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: maxWidthDp?.toDouble(),
        maxHeight: maxHeightDp?.toDouble(),
        imageQuality: imageQuality,
      );

      final base64Images = <String>[];
      for (var image in images) {
        if (base64Images.length >= maxImages) break;
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType = image.mimeType?.split('/').last ?? 'jpeg';
        base64Images.add('data:image/$mimeType;base64,$base64String');
      }
      return base64Images;
    } catch (e) {
      print('[ImageHandler] Error picking multiple images: $e');
    }
    return [];
  }

  /// Récupère l'image depuis la caméra
  static Future<String?> takePictureAsBase64({
    int? maxWidthDp,
    int? maxHeightDp,
    int imageQuality = 85,
  }) async {
    return pickImageAsBase64(
      source: ImageSource.camera,
      maxWidthDp: maxWidthDp,
      maxHeightDp: maxHeightDp,
      imageQuality: imageQuality,
    );
  }

  /// Convertit un fichier File en base64
  static Future<String?> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = _getMimeType(file.path);
      return 'data:image/$mimeType;base64,$base64String';
    } catch (e) {
      print('[ImageHandler] Error converting file to base64: $e');
    }
    return null;
  }

  /// Détermine le type MIME basé sur l'extension du fichier
  static String _getMimeType(String filePath) {
    if (filePath.endsWith('.png')) return 'png';
    if (filePath.endsWith('.gif')) return 'gif';
    if (filePath.endsWith('.webp')) return 'webp';
    if (filePath.endsWith('.jpg') || filePath.endsWith('.jpeg')) return 'jpeg';
    return 'jpeg'; // par défaut
  }
}
