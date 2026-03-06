import 'viewport_recorder.dart';
import 'screen_record_recorder_stub.dart'
    if (dart.library.io) 'screen_record_recorder_io.dart' as impl;

CaldaViewportRecorder createCaldaScreenRecordRecorder() =>
    impl.CaldaScreenRecordRecorder();
