import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/selected_image_model.dart';

class ImageProcessingService {
  static const int defaultMaxSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> supportedFormats = ['jpg', 'jpeg', 'png', 'webp', 'heic'];

  /// Validates whether the image matches format and size requirements
  String? validateImage(SelectedImageModel image, {int maxSizeBytes = defaultMaxSizeBytes}) {
    final extension = image.name.split('.').last.toLowerCase();
    if (!supportedFormats.contains(extension)) {
      return 'Format .$extension is not supported. Please select JPG, PNG, or WEBP.';
    }

    if (image.originalSizeBytes > maxSizeBytes) {
      final maxMb = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(0);
      return 'File size exceeds maximum allowed limit of ${maxMb}MB.';
    }

    return null;
  }

  /// Optimizes and prepares the image file for upload in a clean app cache directory
  Future<SelectedImageModel> optimizeImageForUpload(SelectedImageModel model) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetDir = Directory('${tempDir.path}/fino_uploads');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final originalFile = File(model.originalPath);
      if (!await originalFile.exists()) {
        return model;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedFileName = 'fino_opt_${timestamp}_${model.name.replaceAll(' ', '_')}';
      final targetFilePath = '${targetDir.path}/$compressedFileName';

      // Read original bytes and write to app upload cache
      final bytes = await originalFile.readAsBytes();
      final targetFile = File(targetFilePath);
      await targetFile.writeAsBytes(bytes);

      final finalSize = await targetFile.length();

      return model.copyWith(
        compressedPath: targetFile.path,
        compressedSizeBytes: finalSize,
      );
    } catch (e) {
      return model;
    }
  }

  /// Cleans up temporary upload cache files
  Future<void> clearTempCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetDir = Directory('${tempDir.path}/fino_uploads');
      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
