import 'dart:typed_data';

import 'package:screen_record_plus/screen_record_plus.dart';

import 'viewport_recorder.dart';

class CaldaScreenRecordRecorder implements CaldaViewportRecorder {
  CaldaScreenRecordRecorder();

  final ScreenRecorderController _controller = ScreenRecorderController();

  @override
  String get suggestedFilename => 'recording.mp4';

  @override
  Future<void> start() async {
    await _controller.start();
  }

  @override
  Future<Uint8List?> stop() async {
    await _controller.stop();
    try {
      final file = await _controller.exporter.exportVideo(
        cacheFolder: 'calda_bug_recordings',
      );
      if (file == null || !file.existsSync()) return null;
      final bytes = await file.readAsBytes();
      try {
        file.deleteSync();
      } catch (_) {}
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }
}
