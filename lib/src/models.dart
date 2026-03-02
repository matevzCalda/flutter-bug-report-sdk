import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

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
  final String platform; // ios|android|web|desktop
  final String os;
  final String locale;
  final String model;

  const DeviceInfo({
    required this.platform,
    required this.os,
    required this.locale,
    required this.model,
  });

  static Future<DeviceInfo> collect() async {
    // Skeleton: replace with device_info_plus etc if you want more.
    final p = kIsWeb
        ? 'web'
        : (Platform.isIOS
              ? 'ios'
              : Platform.isAndroid
              ? 'android'
              : 'desktop');
    final os = kIsWeb ? 'web' : Platform.operatingSystem;
    return DeviceInfo(platform: p, os: os, locale: 'unknown', model: 'unknown');
  }

  Map<String, Object?> toJson() => {
    'platform': platform,
    'os': os,
    'locale': locale,
    'model': model,
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
  final Map<String, Object?> stateSnapshot;
  final List<BugEvent> events;
  final Map<String, Object?> extra;

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
    required this.stateSnapshot,
    required this.events,
    required this.extra,
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
    'stateSnapshot': stateSnapshot,
    'events': events.map((e) => e.toJson()).toList(),
    'extra': extra,
    'attachments': {'screenshot': true},
  };
}

class UploadResult {
  final String reportId;
  final Uri viewerUrl;
  const UploadResult({required this.reportId, required this.viewerUrl});
}
