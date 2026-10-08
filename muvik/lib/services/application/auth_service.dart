import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../configs/app_config.dart';
import '../../models/ui_models/app_error.dart';
import '../../utils/app_log.dart';

@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
}

/// Optional Google identity (P15). Never required for local listening; all
/// failures are typed and none of them block bootstrap. Tokens are never logged.
class AuthService {
  final ValueNotifier<AuthUser?> user = ValueNotifier(null);
  bool _initialized = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _sub;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final serverId = AppConfig.googleServerClientId;
      await GoogleSignIn.instance
          .initialize(serverClientId: serverId.isEmpty ? null : serverId)
          .timeout(const Duration(seconds: 5));
      _initialized = true;
      _sub = GoogleSignIn.instance.authenticationEvents.listen(
        (e) {
          switch (e) {
            case GoogleSignInAuthenticationEventSignIn():
              user.value = _map(e.user);
            case GoogleSignInAuthenticationEventSignOut():
              user.value = null;
          }
        },
        onError: (Object e) =>
            AppLog.info('AuthService.events: ${e.runtimeType}'),
      );
      // Restore a previous session silently; offline/timeout is fine.
      unawaited(
        GoogleSignIn.instance
            .attemptLightweightAuthentication()
            ?.timeout(const Duration(seconds: 8))
            .catchError((Object _) => null),
      );
    } catch (e) {
      AppLog.info('AuthService.init: ${e.runtimeType}');
    }
  }

  Future<AuthUser> signIn() async {
    if (!_initialized) await init();
    if (!_initialized) throw const AppError(AppErrorCode.authConfig);
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const AppError(AppErrorCode.authConfig);
    }
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final u = _map(account);
      user.value = u;
      return u;
    } on GoogleSignInException catch (e) {
      throw AppError(_code(e.code));
    } on SocketException {
      throw const AppError(AppErrorCode.network);
    } on TimeoutException {
      throw const AppError(AppErrorCode.network);
    }
  }

  /// Only clears the account state; local playlists/history/settings stay.
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } finally {
      user.value = null;
    }
  }

  static AppErrorCode _code(GoogleSignInExceptionCode c) {
    switch (c) {
      case GoogleSignInExceptionCode.canceled:
        return AppErrorCode.authCancelled;
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return AppErrorCode.authConfig;
      default:
        return AppErrorCode.authFailed;
    }
  }

  AuthUser _map(GoogleSignInAccount a) => AuthUser(
    id: a.id,
    email: a.email,
    displayName: a.displayName,
    photoUrl: a.photoUrl,
  );

  void dispose() {
    _sub?.cancel();
  }
}
