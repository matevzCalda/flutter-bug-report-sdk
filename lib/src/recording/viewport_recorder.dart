import 'dart:typed_data';

abstract class CaldaViewportRecorder {
  Future<void> start();
  Future<Uint8List?> stop();
}
