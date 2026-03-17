import 'package:meta/meta.dart';
import 'models.dart';
import 'redaction.dart';

typedef StateSnapshotProvider = Map<String, Object?> Function();

@immutable
class CaldaBugConfig {
  final Uri endpoint; // e.g. https://bugs.thecalda.com/ingest
  final String apiKey; // staging key
  final String env; // "staging" | "prod"
  final String release; // "myapp@1.2.3+45"
  final AppInfo app;
  final SessionInfo session;

  final String sdkVersion;
  final String schemaVersion;

  final int maxEvents; // ring buffer capacity
  final Duration uploadTimeout;

  final bool enableFloatingButton;
  final bool enableDebugPrintCapture;
  final bool enableFlutterErrorCapture;

  final RedactionConfig redaction;

  final bool enableNetworkCapture;
  final bool enableBreadcrumbCapture;

  const CaldaBugConfig({
    required this.endpoint,
    required this.apiKey,
    required this.env,
    required this.release,
    required this.app,
    required this.session,
    this.sdkVersion = '0.1.0',
    this.schemaVersion = '1.0.0',
    this.maxEvents = 800,
    this.uploadTimeout = const Duration(seconds: 60),
    this.enableFloatingButton = true,
    this.enableDebugPrintCapture = true,
    this.enableFlutterErrorCapture = true,
    this.enableNetworkCapture = true,
    this.enableBreadcrumbCapture = true,
    this.redaction = const RedactionConfig(),
  });
}
