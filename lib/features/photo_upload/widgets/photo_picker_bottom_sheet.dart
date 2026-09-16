import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum PhotoSourceAction {
  camera,
  gallerySingle,
  galleryMultiple,
}

class PhotoPickerBottomSheet extends StatelessWidget {
  final bool allowMultiple;
  final bool allowCamera;
  final String title;
  final String subtitle;

  const PhotoPickerBottomSheet({
    super.key,
    this.allowMultiple = true,
    this.allowCamera = true,
    this.title = 'Upload Document / Photo',
    this.subtitle = 'Select photo from gallery or capture with camera',
  });

  static Future<PhotoSourceAction?> show(
    BuildContext context, {
    bool allowMultiple = true,
    bool allowCamera = true,
    String title = 'Upload Photo / Document',
    String subtitle = 'Choose how you would like to select your photo',
  }) {
    return showModalBottomSheet<PhotoSourceAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => PhotoPickerBottomSheet(
        allowMultiple: allowMultiple,
        allowCamera: allowCamera,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (allowCamera) ...[
                _buildOptionTile(
                  context: context,
                  icon: Icons.camera_alt_rounded,
                  iconBgColor: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  title: 'Take Photo',
                  subtitle: 'Capture document directly using camera',
                  badge: 'Live Capture',
                  onTap: () => Navigator.pop(context, PhotoSourceAction.camera),
                ),
                const SizedBox(height: 12),
              ],
              _buildOptionTile(
                context: context,
                icon: Icons.photo_library_rounded,
                iconBgColor: const Color(0xFFF0FDF4),
                iconColor: const Color(0xFF16A34A),
                title: 'Choose from Gallery',
                subtitle: 'Select an image from your device photos',
                badge: 'Android Photo Picker',
                onTap: () => Navigator.pop(context, PhotoSourceAction.gallerySingle),
              ),
              if (allowMultiple) ...[
                const SizedBox(height: 12),
                _buildOptionTile(
                  context: context,
                  icon: Icons.collections_rounded,
                  iconBgColor: const Color(0xFFFAF5FF),
                  iconColor: const Color(0xFF9333EA),
                  title: 'Select Multiple Photos',
                  subtitle: 'Pick multiple documents in a single batch',
                  badge: 'Multi-Select',
                  onTap: () => Navigator.pop(context, PhotoSourceAction.galleryMultiple),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
