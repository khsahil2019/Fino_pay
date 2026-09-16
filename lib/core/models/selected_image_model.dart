import 'dart:io';

enum UploadStatus {
  idle,
  compressing,
  uploading,
  success,
  error,
}

class SelectedImageModel {
  final String id;
  final String name;
  final String originalPath;
  final int originalSizeBytes;
  String? compressedPath;
  int? compressedSizeBytes;
  final String mimeType;
  final int? width;
  final int? height;
  UploadStatus status;
  double uploadProgress; // 0.0 to 1.0
  String? remoteUrl;
  String? errorMessage;
  final DateTime selectedAt;

  SelectedImageModel({
    required this.id,
    required this.name,
    required this.originalPath,
    required this.originalSizeBytes,
    this.compressedPath,
    this.compressedSizeBytes,
    required this.mimeType,
    this.width,
    this.height,
    this.status = UploadStatus.idle,
    this.uploadProgress = 0.0,
    this.remoteUrl,
    this.errorMessage,
    DateTime? selectedAt,
  }) : selectedAt = selectedAt ?? DateTime.now();

  File get activeFile {
    if (compressedPath != null && File(compressedPath!).existsSync()) {
      return File(compressedPath!);
    }
    return File(originalPath);
  }

  int get activeSizeBytes => compressedSizeBytes ?? originalSizeBytes;

  String get formattedOriginalSize => formatBytes(originalSizeBytes);

  String get formattedActiveSize => formatBytes(activeSizeBytes);

  double get compressionRatio {
    if (compressedSizeBytes == null || originalSizeBytes == 0) return 0.0;
    return (1.0 - (compressedSizeBytes! / originalSizeBytes)) * 100;
  }

  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (bytes > 0) ? (bytes.toString().length - 1) ~/ 3 : 0;
    if (i >= suffixes.length) i = suffixes.length - 1;
    double num = bytes / (1 << (i * 10));
    return "${num.toStringAsFixed(decimals)} ${suffixes[i]}";
  }

  SelectedImageModel copyWith({
    String? compressedPath,
    int? compressedSizeBytes,
    UploadStatus? status,
    double? uploadProgress,
    String? remoteUrl,
    String? errorMessage,
  }) {
    return SelectedImageModel(
      id: id,
      name: name,
      originalPath: originalPath,
      originalSizeBytes: originalSizeBytes,
      compressedPath: compressedPath ?? this.compressedPath,
      compressedSizeBytes: compressedSizeBytes ?? this.compressedSizeBytes,
      mimeType: mimeType,
      width: width,
      height: height,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedAt: selectedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'originalPath': originalPath,
      'originalSizeBytes': originalSizeBytes,
      'compressedPath': compressedPath,
      'compressedSizeBytes': compressedSizeBytes,
      'mimeType': mimeType,
      'width': width,
      'height': height,
      'status': status.name,
      'uploadProgress': uploadProgress,
      'remoteUrl': remoteUrl,
      'errorMessage': errorMessage,
      'selectedAt': selectedAt.toIso8601String(),
    };
  }

  factory SelectedImageModel.fromJson(Map<String, dynamic> json) {
    UploadStatus parseStatus(String? val) {
      if (val == null) return UploadStatus.idle;
      return UploadStatus.values.firstWhere(
        (e) => e.name == val,
        orElse: () => UploadStatus.idle,
      );
    }

    return SelectedImageModel(
      id: json['id'] as String? ?? '${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'document.jpg',
      originalPath: json['originalPath'] as String? ?? '',
      originalSizeBytes: json['originalSizeBytes'] as int? ?? 0,
      compressedPath: json['compressedPath'] as String?,
      compressedSizeBytes: json['compressedSizeBytes'] as int?,
      mimeType: json['mimeType'] as String? ?? 'image/jpeg',
      width: json['width'] as int?,
      height: json['height'] as int?,
      status: parseStatus(json['status'] as String?),
      uploadProgress: (json['uploadProgress'] as num?)?.toDouble() ?? 0.0,
      remoteUrl: json['remoteUrl'] as String?,
      errorMessage: json['errorMessage'] as String?,
      selectedAt: json['selectedAt'] != null
          ? DateTime.tryParse(json['selectedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
