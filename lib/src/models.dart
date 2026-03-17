import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  final String name;
  final String version;
  final String build;
  const AppInfo({
    required this.name,
    required this.version,
    required this.build,
  });

  Map<String, Object?> toJson() => {
    'name': name,
    'version': version,
    'build': build,
  };
}

class SessionInfo {
  final String sessionId;
  final Map<String, Object?> user; // { id, emailHash } etc.
  const SessionInfo({required this.sessionId, this.user = const {}});
  Map<String, Object?> toJson() => {'id': sessionId, 'user': user};
}

class SdkInfo {
  final String name;
  final String version;
  final String platform; // flutter|web
  const SdkInfo({
    required this.name,
    required this.version,
    required this.platform,
  });
  Map<String, Object?> toJson() => {
    'name': name,
    'version': version,
    'platform': platform,
  };
}

class DeviceInfo {
  final String platform;
  final String os;
  final String osVersion;
  final String locale;
  final String model;
  final String manufacturer;
  final String packageId;
  final String appVersion;
  final String appBuildNumber;
  final String colorScheme;
  final double? screenWidth;
  final double? screenHeight;
  final String? timezone;
  final int? timezoneOffset;
  final String? language;

  const DeviceInfo({
    required this.platform,
    required this.os,
    this.osVersion = '',
    this.locale = 'unknown',
    this.model = 'unknown',
    this.manufacturer = '',
    this.packageId = '',
    this.appVersion = '',
    this.appBuildNumber = '',
    this.colorScheme = 'unknown',
    this.screenWidth,
    this.screenHeight,
    this.timezone,
    this.timezoneOffset,
    this.language,
  });

  static Future<DeviceInfo> collect() async {
    final p = kIsWeb
        ? 'web'
        : (Platform.isIOS
            ? 'ios'
            : Platform.isAndroid
                ? 'android'
                : 'desktop');
    final os = kIsWeb ? 'web' : Platform.operatingSystem;
    String osVersion = '';
    String model = 'unknown';
    String manufacturer = '';
    String packageId = '';
    String appVersion = '';
    String appBuildNumber = '';

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        osVersion = '${android.version.release} (SDK ${android.version.sdkInt})';
        model = android.model;
        manufacturer = android.manufacturer;
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        osVersion = ios.systemVersion;
        model = ios.utsname.machine;
        manufacturer = 'Apple';
      } else if (kIsWeb) {
        final web = await deviceInfo.webBrowserInfo;
        model = '${web.browserName.name} ${web.appVersion}';
        osVersion = web.platform ?? '';
      }
    } catch (_) {}

    try {
      final info = await PackageInfo.fromPlatform();
      packageId = info.packageName;
      appVersion = info.version;
      appBuildNumber = info.buildNumber;
    } catch (_) {}

    // Color scheme detection
    String colorScheme = 'unknown';
    try {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      colorScheme = brightness == ui.Brightness.dark ? 'dark' : 'light';
    } catch (_) {}

    // Screen dimensions
    double? screenWidth;
    double? screenHeight;
    try {
      final display = ui.PlatformDispatcher.instance.views.first.display;
      screenWidth = display.size.width / display.devicePixelRatio;
      screenHeight = display.size.height / display.devicePixelRatio;
    } catch (_) {}

    // Timezone
    String? timezone;
    int? timezoneOffset;
    try {
      final now = DateTime.now();
      timezone = now.timeZoneName;
      timezoneOffset = now.timeZoneOffset.inMinutes;
    } catch (_) {}

    // Language / locale
    String locale = 'unknown';
    String? language;
    try {
      final platformLocale =
          ui.PlatformDispatcher.instance.locale;
      locale = platformLocale.toString();
      language = platformLocale.languageCode;
    } catch (_) {}

    return DeviceInfo(
      platform: p,
      os: os,
      osVersion: osVersion,
      locale: locale,
      model: model,
      manufacturer: manufacturer,
      packageId: packageId,
      appVersion: appVersion,
      appBuildNumber: appBuildNumber,
      colorScheme: colorScheme,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      timezone: timezone,
      timezoneOffset: timezoneOffset,
      language: language,
    );
  }

  Map<String, String> toDisplayMap() {
    final m = <String, String>{
      'Platform': platform,
      'OS': os,
      if (osVersion.isNotEmpty) 'OS version': osVersion,
      'Model': model,
      if (manufacturer.isNotEmpty) 'Manufacturer': manufacturer,
      if (packageId.isNotEmpty) 'Package / Bundle ID': packageId,
      if (appVersion.isNotEmpty) 'App version': appVersion,
      if (appBuildNumber.isNotEmpty) 'Build': appBuildNumber,
      'Color scheme': colorScheme,
      if (screenWidth != null && screenHeight != null)
        'Screen': '${screenWidth!.round()}x${screenHeight!.round()}',
      if (timezone != null) 'Timezone': timezone!,
      if (language != null) 'Language': language!,
    };
    return m;
  }

  Map<String, Object?> toJson() => {
        'platform': platform,
        'os': os,
        'osVersion': osVersion,
        'locale': locale,
        'model': model,
        'manufacturer': manufacturer,
        'packageId': packageId,
        'appVersion': appVersion,
        'appBuildNumber': appBuildNumber,
        'colorScheme': colorScheme,
        if (screenWidth != null) 'screenWidth': screenWidth,
        if (screenHeight != null) 'screenHeight': screenHeight,
        if (timezone != null) 'timezone': timezone,
        if (timezoneOffset != null) 'timezoneOffset': timezoneOffset,
        if (language != null) 'language': language,
      };
}

@immutable
class BugEvent {
  final int t; // ms since init
  final String type; // log|err|nav|net|ui|custom
  final Map<String, Object?> data;

  const BugEvent._(this.t, this.type, this.data);

  factory BugEvent.log({
    required int t,
    required String level,
    required String message,
    required Map<String, Object?> attrs,
  }) => BugEvent._(t, 'log', {
    'level': level,
    'message': message,
    'attrs': attrs,
  });

  factory BugEvent.err({
    required int t,
    required String name,
    required String message,
    String? stack,
    required Map<String, Object?> attrs,
  }) => BugEvent._(t, 'err', {
    'name': name,
    'message': message,
    'stack': stack,
    'attrs': attrs,
  });

  factory BugEvent.nav({
    required int t,
    String? from,
    required String to,
    required Map<String, Object?> attrs,
  }) => BugEvent._(t, 'nav', {'from': from, 'to': to, 'attrs': attrs});

  factory BugEvent.net({
    required int t,
    required String method,
    required String url,
    int? status,
    int? ms,
    required Map<String, Object?> attrs,
  }) => BugEvent._(t, 'net', {
    'method': method,
    'url': url,
    'status': status,
    'ms': ms,
    'attrs': attrs,
  });

  factory BugEvent.breadcrumb({
    required int t,
    required String action,
    required String target,
    required String route,
    required Map<String, Object?> attrs,
  }) =>
      BugEvent._(t, 'breadcrumb', {
        'action': action,
        'target': target,
        'route': route,
        'attrs': attrs,
      });

  Map<String, Object?> toJson() => {'t': t, 'type': type, ...data};

  BugEvent redacted(redaction) {
    // actual redaction happens in redaction.dart helpers
    return this;
  }
}

class BugReportPayload {
  final String schemaVersion;
  final SdkInfo sdk;
  final DateTime timestamp;
  final String env;
  final String release;
  final AppInfo app;
  final DeviceInfo device;
  final SessionInfo session;
  final String userMessage;
  final String reproductionSummary;
  final Map<String, Object?> stateSnapshot;
  final List<BugEvent> events;
  final Map<String, Object?> extra;
  final bool hasScreenshot;
  final int attachmentCount;

  BugReportPayload({
    required this.schemaVersion,
    required this.sdk,
    required this.timestamp,
    required this.env,
    required this.release,
    required this.app,
    required this.device,
    required this.session,
    required this.userMessage,
    required this.reproductionSummary,
    required this.stateSnapshot,
    required this.events,
    required this.extra,
    this.hasScreenshot = false,
    this.attachmentCount = 0,
  });

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'sdk': sdk.toJson(),
        'timestamp': timestamp.toIso8601String(),
        'env': env,
        'release': release,
        'app': app.toJson(),
        'device': device.toJson(),
        'session': session.toJson(),
        'userMessage': userMessage,
        'reproductionSummary': reproductionSummary,
        'stateSnapshot': stateSnapshot,
        'events': events.map((e) => e.toJson()).toList(),
        'extra': extra,
        'attachments': {
          'screenshot': hasScreenshot,
          'count': (hasScreenshot ? 1 : 0) + attachmentCount,
        },
      };
}

class ReportAttachment {
  final String type;
  final Uint8List data;
  final String? filename;

  const ReportAttachment({
    required this.type,
    required this.data,
    this.filename,
  });
}

class UploadResult {
  final String reportId;
  final Uri viewerUrl;
  const UploadResult({required this.reportId, required this.viewerUrl});
}
