/// Typed error codes so UI can show specific messages (P02-09, P18-07).
enum AppErrorCode {
  permissionDenied('error_permission_denied'),
  permissionPermanentlyDenied('error_permission_permanently_denied'),
  sourceUnavailable('error_source_unavailable'),
  fileUnavailable('error_file_unavailable'),
  unsupportedFormat('error_unsupported_format'),
  playbackFailed('error_playback_failed'),
  queueAllFailed('error_queue_all_failed'),
  database('error_database'),
  scanFailed('error_scan_failed'),
  duplicate('error_duplicate'),
  validation('error_validation'),
  network('error_network'),
  authCancelled('error_auth_cancelled'),
  authConfig('error_auth_config'),
  authFailed('error_auth_failed'),
  noEmailApp('error_no_email_app'),
  noStoreApp('error_no_store_app'),
  unknown('error_unknown');

  const AppErrorCode(this.messageKey);
  final String messageKey;
}

class AppError implements Exception {
  const AppError(this.code, [this.detail]);
  final AppErrorCode code;
  final String? detail;

  @override
  String toString() =>
      'AppError(${code.name}${detail == null ? '' : ': $detail'})';
}
