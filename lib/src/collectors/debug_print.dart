import 'package:flutter/foundation.dart';

typedef LogLineSink = void Function(String line);

void installDebugPrintInterceptor({required LogLineSink onLine}) {
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) onLine(message);
    original(message, wrapWidth: wrapWidth);
  };
}
