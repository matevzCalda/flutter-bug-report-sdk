import 'dart:typed_data';

import 'viewport_recorder.dart';

class CaldaScreenRecordRecorder implements CaldaViewportRecorder {
  CaldaScreenRecordRecorder();

  @override
  String get suggestedFilename => 'recording.mp4';

  @override
  Future<void> start() async {
    throw UnsupportedError('Screen recording is not supported on this platform.');
  }

  @override
  Future<Uint8List?> stop() async => null;
}
