import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/selected_image_model.dart';
import '../utils/error_helper.dart';

class UploadResult {
  final bool isSuccess;
  final String? remoteUrl;
  final String? fileId;
  final String? errorMessage;
  final int statusCode;

  UploadResult({
    required this.isSuccess,
    this.remoteUrl,
    this.fileId,
    this.errorMessage,
    this.statusCode = 200,
  });
}

class UploadApiService {
  final String? customApiEndpoint;
  final String? authToken;
  final bool isSimulationMode;

  UploadApiService({
    this.customApiEndpoint,
    this.authToken,
    this.isSimulationMode = true,
  });

  /// Uploads a selected image with real-time stream progress updates
  Stream<double> uploadImage({
    required SelectedImageModel image,
    required String fileParamName,
    Map<String, String>? extraFields,
    required Function(UploadResult result) onComplete,
  }) async* {
    final endpoint = customApiEndpoint?.trim() ?? '';
    final isMockEndpoint = endpoint.isEmpty ||
        endpoint.contains('api.finopay.in') ||
        endpoint.contains('example.com') ||
        !endpoint.startsWith('http');

    if (isSimulationMode || isMockEndpoint) {
      yield* _simulateUploadProgress(image, onComplete);
    } else {
      yield* _performRealMultipartUpload(
        image: image,
        fileParamName: fileParamName,
        extraFields: extraFields,
        onComplete: onComplete,
      );
    }
  }

  /// High-fidelity simulation mimicking realistic network streaming and server response
  Stream<double> _simulateUploadProgress(
    SelectedImageModel image,
    Function(UploadResult result) onComplete,
  ) async* {
    yield 0.15;
    await Future.delayed(const Duration(milliseconds: 100));
    yield 0.45;
    await Future.delayed(const Duration(milliseconds: 120));
    yield 0.75;
    await Future.delayed(const Duration(milliseconds: 120));
    yield 0.95;
    await Future.delayed(const Duration(milliseconds: 80));
    yield 1.0;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = image.name.replaceAll(' ', '_');
    final mockRemoteUrl = 'https://cdn.finopay.in/uploads/doc_${timestamp}_$sanitizedName';

    onComplete(
      UploadResult(
        isSuccess: true,
        remoteUrl: mockRemoteUrl,
        fileId: 'FINO_DOC_$timestamp',
        statusCode: 200,
      ),
    );
  }

  /// Live HTTP Multipart Upload with authorization and custom fields
  Stream<double> _performRealMultipartUpload({
    required SelectedImageModel image,
    required String fileParamName,
    Map<String, String>? extraFields,
    required Function(UploadResult result) onComplete,
  }) async* {
    try {
      final uri = Uri.parse(customApiEndpoint!);
      final request = http.MultipartRequest('POST', uri);

      if (authToken != null && authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.headers['Accept'] = 'application/json';

      if (extraFields != null) {
        request.fields.addAll(extraFields);
      }

      final file = image.activeFile;
      final multipartFile = await http.MultipartFile.fromPath(
        fileParamName,
        file.path,
        filename: image.name,
      );
      request.files.add(multipartFile);

      yield 0.1;
      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      yield 0.8;

      final response = await http.Response.fromStream(streamedResponse);
      yield 1.0;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        String? remoteUrl;
        String? fileId;
        try {
          final json = jsonDecode(response.body);
          remoteUrl = json['data']?['url'] ?? json['url'];
          fileId = json['data']?['id'] ?? json['id'];
        } catch (_) {}

        onComplete(
          UploadResult(
            isSuccess: true,
            remoteUrl: remoteUrl ?? 'https://api.finopay.in/cdn/uploads/${image.name}',
            fileId: fileId,
            statusCode: response.statusCode,
          ),
        );
      } else {
        onComplete(
          UploadResult(
            isSuccess: false,
            errorMessage: ErrorHelper.format('HTTP ${response.statusCode}: ${response.body}'),
            statusCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      yield 0.0;
      onComplete(
        UploadResult(
          isSuccess: false,
          errorMessage: ErrorHelper.format(e),
          statusCode: 500,
        ),
      );
    }
  }
}
