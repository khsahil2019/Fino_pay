import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/selected_image_model.dart';

class LocalStorageService {
  static const String _keyProfileAvatar = 'fino_profile_avatar';
  static const String _keyKycDocs = 'fino_kyc_docs';
  static const String _keyReceipts = 'fino_receipts';
  static const String _keyApiEndpoint = 'fino_api_endpoint';
  static const String _keyFileParam = 'fino_file_param';
  static const String _keyAuthToken = 'fino_auth_token';
  static const String _keyIsSimulation = 'fino_is_simulation';

  // ----------------------------------------------------
  // Profile Avatar Persistence
  // ----------------------------------------------------
  Future<void> saveProfileAvatar(SelectedImageModel? avatar) async {
    final prefs = await SharedPreferences.getInstance();
    if (avatar == null) {
      await prefs.remove(_keyProfileAvatar);
    } else {
      final jsonStr = jsonEncode(avatar.toJson());
      await prefs.setString(_keyProfileAvatar, jsonStr);
    }
  }

  Future<SelectedImageModel?> loadProfileAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyProfileAvatar);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return SelectedImageModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------
  // Document Lists Persistence (KYC / Receipts)
  // ----------------------------------------------------
  Future<void> saveDocumentsList({required List<SelectedImageModel> docs, required bool isKyc}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isKyc ? _keyKycDocs : _keyReceipts;
    final jsonList = docs.map((d) => d.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    await prefs.setString(key, jsonStr);
  }

  Future<List<SelectedImageModel>> loadDocumentsList({required bool isKyc}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isKyc ? _keyKycDocs : _keyReceipts;
      final jsonStr = prefs.getString(key);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => SelectedImageModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ----------------------------------------------------
  // API Settings Persistence
  // ----------------------------------------------------
  Future<void> saveApiSettings({
    required bool isSimulation,
    required String apiEndpoint,
    required String fileParamName,
    required String authToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsSimulation, isSimulation);
    await prefs.setString(_keyApiEndpoint, apiEndpoint);
    await prefs.setString(_keyFileParam, fileParamName);
    await prefs.setString(_keyAuthToken, authToken);
  }

  Future<Map<String, dynamic>> loadApiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isSimulation': prefs.getBool(_keyIsSimulation) ?? true,
      'apiEndpoint': prefs.getString(_keyApiEndpoint) ?? 'https://api.finopay.in/v1/kyc/upload',
      'fileParamName': prefs.getString(_keyFileParam) ?? 'document_file',
      'authToken': prefs.getString(_keyAuthToken) ?? '',
    };
  }

  // ----------------------------------------------------
  // Clear All Local Data
  // ----------------------------------------------------
  Future<void> clearAllStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfileAvatar);
    await prefs.remove(_keyKycDocs);
    await prefs.remove(_keyReceipts);
  }
}
