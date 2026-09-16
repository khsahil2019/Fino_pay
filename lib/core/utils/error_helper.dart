class ErrorHelper {
  /// Converts raw technical exceptions into clean, friendly, polite messages
  static String format(dynamic error) {
    if (error == null) return 'Something went wrong. Please try again.';

    final errorStr = error.toString().toLowerCase();

    // Network & Connection issues
    if (errorStr.contains('socketexception') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('connection reset')) {
      return 'Network connection issue. Please check your internet and try again.';
    }

    // Timeout
    if (errorStr.contains('timeoutexception') || errorStr.contains('timed out')) {
      return 'Request took too long. Please check your connection and retry.';
    }

    // Camera / Permission issues
    if (errorStr.contains('camera_access_denied') ||
        errorStr.contains('permission_denied') ||
        errorStr.contains('permission denied')) {
      return 'Camera access is required. Please grant permission in device Settings.';
    }

    if (errorStr.contains('permanently denied')) {
      return 'Camera permission is turned off. Please enable it in device Settings.';
    }

    // Storage / File issues
    if (errorStr.contains('no such file') || errorStr.contains('filenotfoundexception')) {
      return 'The selected file could not be accessed. Please pick the photo again.';
    }

    if (errorStr.contains('out of memory')) {
      return 'Image is too high resolution. Please try selecting a smaller photo.';
    }

    // HTTP Status Codes
    if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
      return 'Authentication session expired. Please verify your token.';
    }

    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return 'Access denied. You do not have permission to upload this file.';
    }

    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return 'Upload server endpoint not found. Please verify the API URL.';
    }

    if (errorStr.contains('413') || errorStr.contains('payload too large')) {
      return 'File size is too large for the server. Maximum limit is 5MB.';
    }

    if (errorStr.contains('415') || errorStr.contains('unsupported media type')) {
      return 'File type not accepted. Please upload a JPG, PNG, or HEIC photo.';
    }

    if (errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503') ||
        errorStr.contains('504') ||
        errorStr.contains('internal server error')) {
      return 'Server is temporarily unavailable. Please try again shortly.';
    }

    // Cancellation
    if (errorStr.contains('cancel') || errorStr.contains('user cancelled')) {
      return 'Selection cancelled.';
    }

    // Fallback: If it's already a clean string without system jargon, return it
    if (!errorStr.contains('exception') && !errorStr.contains('error:') && error.toString().length < 90) {
      return error.toString();
    }

    return 'Unable to complete upload. Please retry in a moment.';
  }
}
