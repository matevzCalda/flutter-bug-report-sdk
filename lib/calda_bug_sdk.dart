library calda_bug_sdk;

export 'src/config.dart';
export 'src/models.dart';
export 'src/ui/floating_button.dart';
export 'src/screenshot/boundary.dart';
export 'src/collectors/dio_interceptor.dart';
export 'src/collectors/breadcrumb_capture.dart';
export 'src/recording/viewport_recorder.dart';
export 'src/recording/screen_record_recorder.dart';
export 'src/auth/supabase.dart';
export 'src/ui/login_screen.dart';

import 'dart:typed_data';

import 'src/config.dart';
import 'src/models.dart';
import 'src/ring_buffer.dart';
import 'src/time.dart';
import 'src/collectors/flutter_errors.dart';
import 'src/collectors/debug_print.dart';
import 'package:dio/dio.dart';

import 'src/collectors/breadcrumb_capture.dart' as breadcrumb;
import 'src/collectors/dio_interceptor.dart';
import 'src/collectors/navigation_observer.dart';
import 'src/reproduction_summary.dart';
import 'src/upload/uploader.dart';

class CaldaBug {
  CaldaBug._();

  static CaldaBugConfig? _config;
  static late final RingBuffer<BugEvent> _buffer;
  static late final Uploader _uploader;
  static late final Stopwatch _clock;
  static StateSnapshotProvider? _snapshotProvider;
  static String? _lastRoute;

  static CaldaBugConfig get config {
    final c = _config;
    if (c == null) throw StateError('CaldaBug.init must be called first');
    return c;
  }

  static void init(CaldaBugConfig config) {
    _config = config;
    _buffer = RingBuffer<BugEvent>(capacity: config.maxEvents);
    _uploader = Uploader(
      config.endpoint,
      config.apiKey,
      timeout: config.uploadTimeout,
    );
    _clock = Stopwatch()..start();

    if (config.enableDebugPrintCapture) {
      installDebugPrintInterceptor(
        onLine: (line) {
          addEvent(
            BugEvent.log(
              t: nowMs(_clock),
              level: 'debug',
              message: line,
              attrs: const {},
            ),
          );
        },
      );
    }

    if (config.enableFlutterErrorCapture) {
      installFlutterErrorCapture(
        onError: (errEvent) => addEvent(errEvent),
        clock: _clock,
      );
    }
    breadcrumb.configureBreadcrumbCapture(
      add: addEvent,
      enabled: config.enableBreadcrumbCapture,
      nowMs: () => _clock.elapsedMilliseconds,
      lastRoute: () => _lastRoute,
    );
  }

  static void setStateSnapshotProvider(StateSnapshotProvider provider) {
    _snapshotProvider = provider;
  }

  static void addEvent(BugEvent event) {
    if (_config == null) return;
    _buffer.add(event);
  }

  static List<String> getLastLogLines({int limit = 500}) {
    final events = _buffer.snapshot();
    final logMessages = events
        .where((e) => e.type == 'log')
        .map((e) => (e.data['message'] as String?) ?? '')
        .toList();
    final start = logMessages.length > limit ? logMessages.length - limit : 0;
    return logMessages.sublist(start);
  }

  static String? get lastRoute => _lastRoute;

  static CaldaBugNavigatorObserver navigatorObserver() {
    return CaldaBugNavigatorObserver(
      onRoute: (from, to) {
        _lastRoute = to;
        addEvent(
          BugEvent.nav(t: nowMs(_clock), from: from, to: to, attrs: const {}),
        );
      },
    );
  }

  static Interceptor? dioInterceptor({
    required String Function(String url) redactUrl,
  }) {
    if (!config.enableNetworkCapture) return null;
    return CaldaBugDioInterceptor(
      add: addEvent,
      clock: _clock,
      redactUrl: redactUrl,
    );
  }

  static String getReproductionSummary() {
    return getReproductionSummaryFromEvents(_buffer.snapshot());
  }

  static Future<UploadResult> report({
    required String title,
    required String description,
    required String platform,
    required String environment,
    required DeviceInfo deviceInfo,
    Uint8List? screenshotPng,
    List<ReportAttachment> attachments = const [],
    String? token,
  }) async {
    final c = config;

    final payload = BugReportPayload(
      schemaVersion: c.schemaVersion,
      sdk: SdkInfo(
        name: 'calda-bug-sdk',
        version: c.sdkVersion,
        platform: 'flutter',
      ),
      timestamp: DateTime.now().toUtc(),
      env: environment,
      release: c.release,
      app: c.app,
      device: deviceInfo,
      session: c.session,
      userMessage: '$title\n\n$description',
      reproductionSummary: getReproductionSummary(),
      stateSnapshot: _snapshotProvider?.call() ?? {},
      events: _buffer.snapshot(),
      extra: {'platform': platform},
      hasScreenshot: screenshotPng != null && screenshotPng.isNotEmpty,
      attachmentCount: attachments.length,
    );

    return _uploader.uploadReport(
      payload: payload,
      screenshotPng: screenshotPng,
      attachments: attachments,
      token: token,
    );
  }
}
