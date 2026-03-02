import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models.dart';
import '../time.dart';

void installFlutterErrorCapture({
  required void Function(BugEvent) onError,
  required Stopwatch clock,
}) {
  final prev = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    try {
      onError(
        BugEvent.err(
          t: nowMs(clock),
          name: details.exception.runtimeType.toString(),
          message: details.exceptionAsString(),
          stack: details.stack?.toString(),
          attrs: const {'handled': true, 'source': 'FlutterError.onError'},
        ),
      );
    } catch (_) {}
    prev?.call(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    try {
      onError(
        BugEvent.err(
          t: nowMs(clock),
          name: error.runtimeType.toString(),
          message: error.toString(),
          stack: stack.toString(),
          attrs: const {
            'handled': false,
            'source': 'PlatformDispatcher.onError',
          },
        ),
      );
    } catch (_) {}
    return false; // let default handler run too
  };
}

/// Optional helper to wrap app entry
Future<void> runCaldaZoned(
  Stopwatch clock,
  void Function(BugEvent) onError,
  Future<void> Function() body,
) async {
  return runZonedGuarded(body, (error, stack) {
    onError(
      BugEvent.err(
        t: nowMs(clock),
        name: error.runtimeType.toString(),
        message: error.toString(),
        stack: stack.toString(),
        attrs: const {'handled': false, 'source': 'runZonedGuarded'},
      ),
    );
  });
}
