import 'package:image_picker/image_picker.dart';
import '../models/selected_image_model.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Picks a single photo from device Gallery using Modern Android Photo Picker (Android 13+) / native gallery
  Future<SelectedImageModel?> pickSingleImage({
    int imageQuality = 90,
    double? maxWidth = 2048,
    double? maxHeight = 2048,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (pickedFile == null) return null;
      return await _createModelFromXFile(pickedFile);
    } catch (e) {
      rethrow;
    }
  }

  /// Picks multiple photos in a single batch from device Gallery
  Future<List<SelectedImageModel>> pickMultipleImages({
    int imageQuality = 90,
    double? maxWidth = 2048,
    double? maxHeight = 2048,
    int? limit,
  }) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        limit: limit,
      );

      final List<SelectedImageModel> list = [];
      for (final xfile in pickedFiles) {
        final model = await _createModelFromXFile(xfile);
        list.add(model);
      }
      return list;
    } catch (e) {
      rethrow;
    }
  }

  /// Captures a fresh photo using Device Camera
  Future<SelectedImageModel?> capturePhotoFromCamera({
    int imageQuality = 90,
    double? maxWidth = 2048,
    double? maxHeight = 2048,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: preferredCameraDevice,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (pickedFile == null) return null;
      return await _createModelFromXFile(pickedFile);
    } catch (e) {
      rethrow;
    }
  }

  Future<SelectedImageModel> _createModelFromXFile(XFile file) async {
    final int size = await file.length();
    final String name = file.name.isNotEmpty ? file.name : file.path.split('/').last;
    final String extension = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
    
    String mimeType = 'image/jpeg';
    if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'webp') {
      mimeType = 'image/webp';
    } else if (extension == 'heic' || extension == 'heif') {
      mimeType = 'image/heic';
    }

    return SelectedImageModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}',
      name: name,
      originalPath: file.path,
      originalSizeBytes: size,
      mimeType: mimeType,
      status: UploadStatus.idle,
    );
  }
}
