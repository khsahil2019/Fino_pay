import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/selected_image_model.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/services/image_processing_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/upload_api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_helper.dart';
import '../../photo_upload/screens/photo_preview_screen.dart';
import '../../photo_upload/widgets/image_preview_card.dart';
import '../../photo_upload/widgets/photo_picker_bottom_sheet.dart';

class FinoHomeScreen extends StatefulWidget {
  const FinoHomeScreen({super.key});

  @override
  State<FinoHomeScreen> createState() => _FinoHomeScreenState();
}

class _FinoHomeScreenState extends State<FinoHomeScreen> with SingleTickerProviderStateMixin {
  final ImagePickerService _pickerService = ImagePickerService();
  final ImageProcessingService _processingService = ImageProcessingService();
  final LocalStorageService _storageService = LocalStorageService();

  // App State
  SelectedImageModel? _profileAvatar;
  final List<SelectedImageModel> _kycDocuments = [];
  final List<SelectedImageModel> _transactionReceipts = [];

  // State flags
  bool _isLoadingStorage = true;
  bool _isProcessingSelection = false;
  bool _isUploadingBatch = false;

  // API Configuration
  bool _isSimulationMode = true;
  String _apiEndpoint = 'https://api.finopay.in/v1/kyc/upload';
  String _fileParamName = 'document_file';
  String _authToken = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllFromLocalStorage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // Local Storage Load & Save Handlers
  // ----------------------------------------------------
  Future<void> _loadAllFromLocalStorage() async {
    try {
      final savedAvatar = await _storageService.loadProfileAvatar();
      final savedKyc = await _storageService.loadDocumentsList(isKyc: true);
      final savedReceipts = await _storageService.loadDocumentsList(isKyc: false);
      final savedSettings = await _storageService.loadApiSettings();

      if (mounted) {
        setState(() {
          _profileAvatar = savedAvatar;
          _kycDocuments.clear();
          _kycDocuments.addAll(savedKyc);
          _transactionReceipts.clear();
          _transactionReceipts.addAll(savedReceipts);

          _isSimulationMode = savedSettings['isSimulation'] as bool;
          _apiEndpoint = savedSettings['apiEndpoint'] as String;
          _fileParamName = savedSettings['fileParamName'] as String;
          _authToken = savedSettings['authToken'] as String;
          _isLoadingStorage = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStorage = false);
    }
  }

  Future<void> _persistDocuments({required bool isKyc}) async {
    final list = isKyc ? _kycDocuments : _transactionReceipts;
    await _storageService.saveDocumentsList(docs: list, isKyc: isKyc);
  }

  UploadApiService get _uploadService => UploadApiService(
        customApiEndpoint: _apiEndpoint,
        authToken: _authToken,
        isSimulationMode: _isSimulationMode,
      );

  // ----------------------------------------------------
  // Profile Avatar Picker Flow
  // ----------------------------------------------------
  Future<void> _handleProfileAvatarPick() async {
    final action = await PhotoPickerBottomSheet.show(
      context,
      allowMultiple: false,
      allowCamera: true,
      title: 'Update Profile Photo',
      subtitle: 'Take a new selfie or select from gallery',
    );

    if (action == null) return;

    try {
      SelectedImageModel? selected;
      if (action == PhotoSourceAction.camera) {
        selected = await _pickerService.capturePhotoFromCamera();
      } else {
        selected = await _pickerService.pickSingleImage();
      }

      if (selected != null) {
        final validationError = _processingService.validateImage(selected);
        if (validationError != null) {
          _showSnackBar(validationError, isError: true);
          return;
        }

        final optimized = await _processingService.optimizeImageForUpload(selected);
        setState(() {
          _profileAvatar = optimized;
        });
        await _storageService.saveProfileAvatar(_profileAvatar);

        // Auto upload avatar
        _uploadSingleItem(_profileAvatar!, isAvatar: true);
      }
    } catch (e) {
      _showSnackBar(ErrorHelper.format(e), isError: true);
    }
  }

  // ----------------------------------------------------
  // Document Picking Flow (KYC / Receipts)
  // ----------------------------------------------------
  Future<void> _handleDocumentPick({required bool isKyc, PhotoSourceAction? forceAction}) async {
    final action = forceAction ??
        await PhotoPickerBottomSheet.show(
          context,
          allowMultiple: true,
          allowCamera: true,
          title: isKyc ? 'Upload KYC Document' : 'Upload Transaction Receipt',
          subtitle: isKyc
              ? 'Attach PAN, Aadhaar, or Bank Passbook photo'
              : 'Attach payment slip or transaction screenshot',
        );

    if (action == null) return;

    try {
      setState(() => _isProcessingSelection = true);

      List<SelectedImageModel> newlySelected = [];

      if (action == PhotoSourceAction.camera) {
        final photo = await _pickerService.capturePhotoFromCamera();
        if (photo != null) newlySelected.add(photo);
      } else if (action == PhotoSourceAction.gallerySingle) {
        final photo = await _pickerService.pickSingleImage();
        if (photo != null) newlySelected.add(photo);
      } else if (action == PhotoSourceAction.galleryMultiple) {
        newlySelected = await _pickerService.pickMultipleImages();
      }

      if (newlySelected.isEmpty) {
        setState(() => _isProcessingSelection = false);
        return;
      }

      int addedCount = 0;
      for (final item in newlySelected) {
        final error = _processingService.validateImage(item);
        if (error != null) {
          _showSnackBar(ErrorHelper.format(error), isError: true);
          continue;
        }

        final optimized = await _processingService.optimizeImageForUpload(item);
        if (mounted) {
          setState(() {
            if (isKyc) {
              _kycDocuments.add(optimized);
            } else {
              _transactionReceipts.add(optimized);
            }
          });
          addedCount++;
        }
      }

      await _persistDocuments(isKyc: isKyc);
      setState(() => _isProcessingSelection = false);
      if (addedCount > 0) {
        _showSnackBar('Added $addedCount document(s). Ready to upload.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingSelection = false);
        _showSnackBar(ErrorHelper.format(e), isError: true);
      }
    }
  }

  // ----------------------------------------------------
  // Single & Batch Upload Logic
  // ----------------------------------------------------
  Future<void> _uploadSingleItem(SelectedImageModel image, {bool isAvatar = false, bool isKyc = true}) async {
    if (image.status == UploadStatus.uploading) return;

    setState(() {
      image.status = UploadStatus.uploading;
      image.uploadProgress = 0.0;
      image.errorMessage = null;
    });

    await for (final progress in _uploadService.uploadImage(
      image: image,
      fileParamName: _fileParamName,
      extraFields: {
        'doc_type': isAvatar ? 'profile_picture' : (isKyc ? 'kyc_proof' : 'receipt'),
        'user_id': 'FINO_USR_98210',
      },
      onComplete: (result) async {
        if (mounted) {
          setState(() {
            if (result.isSuccess) {
              image.status = UploadStatus.success;
              image.uploadProgress = 1.0;
              image.remoteUrl = result.remoteUrl;
              _showSnackBar('${image.name} uploaded successfully!');
            } else {
              image.status = UploadStatus.error;
              image.errorMessage = ErrorHelper.format(result.errorMessage);
              _showSnackBar(image.errorMessage!, isError: true);
            }
          });

          if (isAvatar) {
            await _storageService.saveProfileAvatar(_profileAvatar);
          } else {
            await _persistDocuments(isKyc: isKyc);
          }
        }
      },
    )) {
      if (mounted) {
        setState(() {
          image.uploadProgress = progress;
        });
      }
    }
  }

  Future<void> _uploadAllPending({required bool isKyc}) async {
    if (_isUploadingBatch) return;

    final list = isKyc ? _kycDocuments : _transactionReceipts;
    final pending = list.where((d) => d.status == UploadStatus.idle || d.status == UploadStatus.error).toList();

    if (pending.isEmpty) {
      _showSnackBar('No pending documents to upload.');
      return;
    }

    setState(() => _isUploadingBatch = true);

    for (final doc in pending) {
      if (!mounted) break;
      await _uploadSingleItem(doc, isKyc: isKyc);
    }

    if (mounted) {
      setState(() => _isUploadingBatch = false);
      _showSnackBar('All uploads completed successfully.');
    }
  }

  Future<void> _removeItem(int index, {required bool isKyc}) async {
    setState(() {
      if (isKyc) {
        _kycDocuments.removeAt(index);
      } else {
        _transactionReceipts.removeAt(index);
      }
    });
    await _persistDocuments(isKyc: isKyc);
    _showSnackBar('Removed document.');
  }

  Future<void> _clearCompleted({required bool isKyc}) async {
    setState(() {
      if (isKyc) {
        _kycDocuments.removeWhere((d) => d.status == UploadStatus.success);
      } else {
        _transactionReceipts.removeWhere((d) => d.status == UploadStatus.success);
      }
    });
    await _persistDocuments(isKyc: isKyc);
    _showSnackBar('Cleared uploaded documents.');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ----------------------------------------------------
  // Clean, Breathable, Modern UI Build
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoadingStorage) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final currentIsKyc = _tabController.index == 0;
    final activeList = currentIsKyc ? _kycDocuments : _transactionReceipts;
    final pendingCount = activeList.where((d) => d.status != UploadStatus.success).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'FINO',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white, letterSpacing: 1.1),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Pay Documents',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
            tooltip: 'Settings',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Original Navy Profile Header
          _buildCleanProfileHeader(),

          // Clean Segmented Tabs
          Container(
            margin: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.badge_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text('KYC Proofs (${_kycDocuments.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text('Receipts (${_transactionReceipts.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isProcessingSelection) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(
                  backgroundColor: Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3,
                ),
              ),
            ),
          ],

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCleanDocumentTab(isKyc: true),
                _buildCleanDocumentTab(isKyc: false),
              ],
            ),
          ),
        ],
      ),
      // Clean Bottom Floating Action
      bottomNavigationBar: activeList.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (pendingCount > 0)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUploadingBatch ? null : () => _uploadAllPending(isKyc: currentIsKyc),
                          icon: _isUploadingBatch
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: Text(_isUploadingBatch ? 'Uploading documents...' : 'Upload All ($pendingCount)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _clearCompleted(isKyc: currentIsKyc),
                          icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                          label: const Text('Clear Completed List'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCleanProfileHeader() {
    final totalDocs = _kycDocuments.length + _transactionReceipts.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar with Camera Button
          Stack(
            children: [
              GestureDetector(
                onTap: _handleProfileAvatarPick,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: ClipOval(
                    child: _profileAvatar != null && File(_profileAvatar!.originalPath).existsSync()
                        ? Image.file(
                            File(_profileAvatar!.originalPath),
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.person_rounded, size: 34, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _handleProfileAvatarPick,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Sahil Khan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.verified_rounded, color: Color(0xFF60A5FA), size: 15),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Merchant Account • $totalDocs Docs Saved',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanDocumentTab({required bool isKyc}) {
    final list = isKyc ? _kycDocuments : _transactionReceipts;

    return CustomScrollView(
      slivers: [
        // Easy 2-Button Picker Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _handleDocumentPick(isKyc: isKyc, forceAction: PhotoSourceAction.camera),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Take Photo',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _handleDocumentPick(isKyc: isKyc),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_rounded, color: Color(0xFF16A34A), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'From Gallery',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // List of Documents
        if (list.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildCleanEmptyPlaceholder(isKyc: isKyc),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = list[index];
                  return ImagePreviewCard(
                    image: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhotoPreviewScreen(
                            image: item,
                            onUpload: () => _uploadSingleItem(item, isKyc: isKyc),
                          ),
                        ),
                      );
                    },
                    onRemove: () => _removeItem(index, isKyc: isKyc),
                    onRetry: () => _uploadSingleItem(item, isKyc: isKyc),
                  );
                },
                childCount: list.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCleanEmptyPlaceholder({required bool isKyc}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Icon(
                isKyc ? Icons.badge_outlined : Icons.receipt_long_outlined,
                size: 36,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isKyc ? 'No KYC documents attached' : 'No receipts attached',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              isKyc
                  ? 'Tap "Take Photo" or "From Gallery" to add Aadhaar or PAN'
                  : 'Add transaction receipts for quick verification',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // Configuration Settings Modal
  // ----------------------------------------------------
  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API & Upload Settings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      title: const Text('Simulation Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Instant progress test without needing a live backend', style: TextStyle(fontSize: 12)),
                      value: _isSimulationMode,
                      activeThumbColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setModalState(() => _isSimulationMode = val);
                        setState(() => _isSimulationMode = val);
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _apiEndpoint,
                      decoration: const InputDecoration(
                        labelText: 'API Endpoint URL',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) => _apiEndpoint = val,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _fileParamName,
                      decoration: const InputDecoration(
                        labelText: 'Multipart File Parameter',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) => _fileParamName = val,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _storageService.saveApiSettings(
                            isSimulation: _isSimulationMode,
                            apiEndpoint: _apiEndpoint,
                            fileParamName: _fileParamName,
                            authToken: _authToken,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            _showSnackBar('Settings saved successfully.');
                          }
                        },
                        child: const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
