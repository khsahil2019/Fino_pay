import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/selected_image_model.dart';
import '../../../core/theme/app_theme.dart';

class ImagePreviewCard extends StatelessWidget {
  final SelectedImageModel image;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;

  const ImagePreviewCard({
    super.key,
    required this.image,
    this.onRemove,
    this.onTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(),
            width: image.status == UploadStatus.uploading ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Image Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 54,
                    height: 54,
                    color: Colors.grey.shade100,
                    child: Image.file(
                      File(image.originalPath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        image.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            image.formattedActiveSize,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          _buildStatusBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
                // Trailing actions
                if (image.status == UploadStatus.error && onRetry != null)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
                    tooltip: 'Retry Upload',
                    onPressed: onRetry,
                  )
                else if (onRemove != null && image.status != UploadStatus.uploading)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                    tooltip: 'Remove',
                    onPressed: onRemove,
                  ),
              ],
            ),
            if (image.status == UploadStatus.uploading) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: image.uploadProgress > 0 ? image.uploadProgress : null,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Uploading to Fino server...',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${(image.uploadProgress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ],
            if (image.status == UploadStatus.error && image.errorMessage != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  image.errorMessage!,
                  style: const TextStyle(fontSize: 11, color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (image.status) {
      case UploadStatus.uploading:
        return AppColors.primaryLight;
      case UploadStatus.success:
        return AppColors.success.withValues(alpha: 0.5);
      case UploadStatus.error:
        return AppColors.error.withValues(alpha: 0.5);
      default:
        return AppColors.cardBorder;
    }
  }

  Widget _buildStatusBadge() {
    switch (image.status) {
      case UploadStatus.idle:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Ready',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
          ),
        );
      case UploadStatus.compressing:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Optimizing',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
          ),
        );
      case UploadStatus.uploading:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Uploading',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        );
      case UploadStatus.success:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
              SizedBox(width: 3),
              Text(
                'Uploaded',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success),
              ),
            ],
          ),
        );
      case UploadStatus.error:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 12, color: AppColors.error),
              SizedBox(width: 3),
              Text(
                'Failed',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error),
              ),
            ],
          ),
        );
    }
  }
}
