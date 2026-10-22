import 'dart:io';

import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../configs/app_config.dart';
import '../configs/pref_const.dart';
import 'native/media_library_channel.dart';
import 'storage/pref_store.dart';

/// Email feedback and store rating (P14-15..P14-20). Opening a composer or
/// the store is all the app can know — it never claims "sent"/"rated".
class FeedbackService {
  FeedbackService._();

  static Future<PackageInfo> packageInfo() => PackageInfo.fromPlatform();

  /// Opens the user's email app with recipient, subject, body and minimal
  /// app/device info. Returns false when no email app could be opened.
  static Future<bool> composeEmail({
    required String subject,
    required String body,
    String? replyTo,
  }) async {
    final info = await packageInfo();
    final sdk = await MediaLibraryChannel.sdkInt();
    final footer = StringBuffer()
      ..writeln()
      ..writeln('---')
      ..writeln('${AppConfig.appName} ${info.version} (${info.buildNumber})')
      ..writeln(
        '${Platform.operatingSystem} ${sdk > 0 ? 'API $sdk' : Platform.operatingSystemVersion}',
      );
    if (replyTo != null && replyTo.isNotEmpty) {
      footer.writeln('Reply-to: $replyTo');
    }
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: _encodeQuery({'subject': subject, 'body': '$body\n$footer'}),
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }

  static Future<void> copySupportEmail() =>
      Clipboard.setData(const ClipboardData(text: AppConfig.supportEmail));

  /// Opens the store review flow for any star count (P14-19). Records only
  /// that the store was opened.
  static Future<bool> openStoreReview() async {
    var opened = false;
    try {
      final review = InAppReview.instance;
      if (Platform.isAndroid) {
        opened = await launchUrl(
          Uri.parse('market://details?id=${AppConfig.androidPackage}'),
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          opened = await launchUrl(
            Uri.parse(AppConfig.playStoreUrl),
            mode: LaunchMode.externalApplication,
          );
        }
      } else {
        await review.openStoreListing();
        opened = true;
      }
    } catch (_) {
      try {
        opened = await launchUrl(
          Uri.parse(AppConfig.playStoreUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        opened = false;
      }
    }
    if (opened) {
      await PrefStore.setInt(
        PrefConst.rateStoreOpenedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
    return opened;
  }

  static Future<void> markRatePrompted() => PrefStore.setInt(
        PrefConst.rateLastPromptAt,
        DateTime.now().millisecondsSinceEpoch,
      );

  static Future<bool> openUrl(String url) async {
    if (url.isEmpty) return false;
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } on PlatformException {
      return false;
    }
  }

  static String? _encodeQuery(Map<String, String> params) => params.entries
      .map(
        (e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
      )
      .join('&');
}
