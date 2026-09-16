import 'package:flutter_test/flutter_test.dart';
import 'package:fino_pay/core/models/selected_image_model.dart';
import 'package:fino_pay/core/services/image_processing_service.dart';
import 'package:fino_pay/main.dart';

void main() {
  group('Fino Pay App Smoke Test', () {
    testWidgets('App renders Fino Pay header and tabs', (WidgetTester tester) async {
      await tester.pumpWidget(const FinoPayApp());
      await tester.pump();

      expect(find.text('FINO'), findsOneWidget);
      expect(find.text('Android 13+ Photo Picker Ready'), findsOneWidget);
      expect(find.text('Add from Gallery'), findsOneWidget);
    });
  });

  group('SelectedImageModel & Processing Tests', () {
    test('Image size formatting works as expected', () {
      expect(SelectedImageModel.formatBytes(500), '500.0 B');
      expect(SelectedImageModel.formatBytes(1024 * 500), '500.0 KB');
      expect(SelectedImageModel.formatBytes(1024 * 1024 * 4), '4.0 MB');
    });

    test('Validation detects unsupported file formats', () {
      final processingService = ImageProcessingService();
      final model = SelectedImageModel(
        id: '1',
        name: 'document.pdf',
        originalPath: '/path/document.pdf',
        originalSizeBytes: 1024,
        mimeType: 'application/pdf',
      );

      final error = processingService.validateImage(model);
      expect(error, isNotNull);
      expect(error!.contains('not supported'), isTrue);
    });

    test('Validation approves JPG/PNG within size limit', () {
      final processingService = ImageProcessingService();
      final model = SelectedImageModel(
        id: '2',
        name: 'aadhaar_front.jpg',
        originalPath: '/path/aadhaar_front.jpg',
        originalSizeBytes: 1024 * 1024 * 2, // 2MB
        mimeType: 'image/jpeg',
      );

      final error = processingService.validateImage(model);
      expect(error, isNull);
    });
  });
}
