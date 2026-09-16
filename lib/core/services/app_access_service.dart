import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AccessStatus {
  final bool isAllowed;
  final String title;
  final String message;
  final String? contactInfo;

  AccessStatus({
    required this.isAllowed,
    required this.title,
    required this.message,
    this.contactInfo,
  });
}

class AppAccessService {
  // Remote Kill Switch Config URL (You can update this JSON anytime on GitHub Gist / Pastebin / JSONBin)
  static const String defaultControlUrl =
      'https://raw.githubusercontent.com/sahilkhan-dev/app-control/main/fino_pay_access.json';

  // Admin Master PIN for emergency override
  static const String masterAdminPin = '8899';

  static const String _keyCachedAccess = 'fino_cached_access';
  static const String _keyCachedMsg = 'fino_cached_access_msg';
  static const String _keyCustomControlUrl = 'fino_custom_control_url';
  static const String _keyAdminOverride = 'fino_admin_override';

  /// Checks whether the app is active, disabled, or revoked
  Future<AccessStatus> verifyAppAccess() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if Admin override is enabled locally
    final bool isAdminOverride = prefs.getBool(_keyAdminOverride) ?? false;
    if (isAdminOverride) {
      return AccessStatus(
        isAllowed: true,
        title: 'Admin Access',
        message: 'Master override active.',
      );
    }

    final controlUrl = prefs.getString(_keyCustomControlUrl) ?? defaultControlUrl;

    try {
      final uri = Uri.parse(controlUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final bool isAppActive = data['is_app_active'] as bool? ?? true;
        final bool isKillSwitch = data['kill_switch_enabled'] as bool? ?? false;
        final String title = data['lock_title'] as String? ?? 'Access Restricted';
        final String message = data['lock_message'] as String? ??
            'This application access has been disabled by the administrator.';
        final String contact = data['contact_info'] as String? ?? 'Contact: Sahil Khan';

        final bool allowed = isAppActive && !isKillSwitch;

        // Cache last verified state
        await prefs.setBool(_keyCachedAccess, allowed);
        await prefs.setString(_keyCachedMsg, message);

        return AccessStatus(
          isAllowed: allowed,
          title: title,
          message: message,
          contactInfo: contact,
        );
      }
    } catch (_) {
      // If offline or network error, check cached state
    }

    // Offline / Network fallback
    final cachedAccess = prefs.getBool(_keyCachedAccess) ?? true;
    final cachedMsg = prefs.getString(_keyCachedMsg) ??
        'Access to this build has been suspended by the administrator.';

    return AccessStatus(
      isAllowed: cachedAccess,
      title: 'Access Restricted',
      message: cachedMsg,
      contactInfo: 'Contact: Sahil Khan',
    );
  }

  /// Sets Admin Master Override
  Future<bool> unlockWithMasterPin(String pin) async {
    if (pin.trim() == masterAdminPin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAdminOverride, true);
      return true;
    }
    return false;
  }

  /// Locks the app locally
  Future<void> revokeAdminOverride() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAdminOverride);
    await prefs.setBool(_keyCachedAccess, false);
  }

  /// Sets custom remote control JSON URL
  Future<void> setCustomControlUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomControlUrl, url.trim());
  }
}
