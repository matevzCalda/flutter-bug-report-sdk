import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../calda_bug_sdk.dart';
import '../models.dart';
import '../screenshot/capture.dart';
import '../recording/viewport_recorder.dart';
import '../recording/screen_record_recorder.dart';
import 'report_sheet.dart';

class CaldaBugFloatingButton extends StatefulWidget {
  final GlobalKey repaintKey;
  final bool enabled;
  final CaldaViewportRecorder? recorder;

  const CaldaBugFloatingButton({
    super.key,
    required this.repaintKey,
    this.enabled = true,
    this.recorder,
  });

  @override
  State<CaldaBugFloatingButton> createState() => _CaldaBugFloatingButtonState();
}

enum _FloatingState { idle, menuOpen, busy, recording }

class _CaldaBugFloatingButtonState extends State<CaldaBugFloatingButton> {
  _FloatingState _state = _FloatingState.idle;
  Timer? _recordingTimer;
  static const _maxRecordingMs = 30000;
  OverlayEntry? _menuOverlay;

  CaldaViewportRecorder get _recorder =>
      widget.recorder ?? createCaldaScreenRecordRecorder();

  @override
  void dispose() {
    _removeMenuOverlay();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _removeMenuOverlay() {
    _menuOverlay?.remove();
    _menuOverlay = null;
  }

  Future<void> _openReportSheet({
    Uint8List? screenshotPng,
    List<ReportAttachment> attachments = const [],
  }) async {
    final consoleLines = CaldaBug.getLastLogLines(limit: 500);
    final deviceInfo = await DeviceInfo.collect();
    final deviceInfoMap = deviceInfo.toDisplayMap();
    deviceInfoMap['Theme'] =
        Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
    deviceInfoMap['Locale'] = Localizations.localeOf(context).toString();
    if (!mounted) return;
    final send = await showCaldaReportSheet(
      context,
      screenshotPng: screenshotPng,
      consoleLines: consoleLines,
      deviceInfo: deviceInfoMap,
      reproductionSummary: CaldaBug.getReproductionSummary(),
      attachments: attachments,
    );
    if (send != true) {
      if (mounted) setState(() => _state = _FloatingState.idle);
      return;
    }
    try {
      await CaldaBug.report(
        userMessage: '',
        screenshotPng: screenshotPng,
        attachments: attachments,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bug report sent.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send report.')),
        );
      }
    } finally {
      if (mounted) setState(() => _state = _FloatingState.idle);
    }
  }

  void _openMenu() {
    if (_state != _FloatingState.idle) return;
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final buttonRect = box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;
    _menuOverlay = OverlayEntry(
      builder: (overlayCtx) {
        final size = MediaQuery.sizeOf(overlayCtx);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              right: size.width - buttonRect.right,
              bottom: size.height - buttonRect.top + 8,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(overlayCtx).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Take screenshot and report'),
                      onTap: _onScreenshotChosen,
                    ),
                    ListTile(
                      leading: const Icon(Icons.videocam),
                      title: const Text('Start recording (max 30s)'),
                      onTap: _onStartRecording,
                    ),
                  ],
                  ),
                ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_menuOverlay!);
    setState(() => _state = _FloatingState.menuOpen);
  }

  void _closeMenu() {
    if (_state == _FloatingState.menuOpen) {
      _removeMenuOverlay();
      setState(() => _state = _FloatingState.idle);
    }
  }

  void _onScreenshotChosen() async {
    _closeMenu();
    setState(() => _state = _FloatingState.busy);
    final png = await capturePng(widget.repaintKey);
    if (!mounted) return;
    await _openReportSheet(screenshotPng: png);
  }

  void _onStartRecording() async {
    final recorder = _recorder;
    _closeMenu();
    setState(() => _state = _FloatingState.recording);
    _recordingTimer = Timer(const Duration(milliseconds: _maxRecordingMs),
        () async {
      _recordingTimer = null;
      if (!mounted || _state != _FloatingState.recording) return;
      final videoBytes = await recorder.stop();
      if (!mounted) return;
      final attachments = videoBytes != null && videoBytes.isNotEmpty
          ? [
              ReportAttachment(
                type: 'video',
                data: videoBytes,
                filename: recorder.suggestedFilename,
              ),
            ]
          : <ReportAttachment>[];
      await _openReportSheet(attachments: attachments);
    });
    try {
      await recorder.start();
    } catch (_) {
      if (mounted) {
        setState(() => _state = _FloatingState.idle);
        _recordingTimer?.cancel();
        _recordingTimer = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording failed to start.')),
        );
      }
    }
  }

  void _onStopRecording() async {
    if (_state != _FloatingState.recording) return;
    final recorder = _recorder;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final videoBytes = await recorder.stop();
    if (!mounted) return;
    final attachments = videoBytes != null && videoBytes.isNotEmpty
        ? [
            ReportAttachment(
              type: 'video',
              data: videoBytes,
              filename: recorder.suggestedFilename,
            ),
          ]
        : <ReportAttachment>[];
    await _openReportSheet(attachments: attachments);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    final isRecording = _state == _FloatingState.recording;
    final isBusy = _state == _FloatingState.busy;

    return Positioned(
      right: 16,
      bottom: 24,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isRecording ? _onStopRecording : _openMenu,
          customBorder: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isRecording ? Colors.red : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isRecording ? Colors.red : Colors.black,
                width: 2,
              ),
              image: isRecording
                  ? null
                  : const DecorationImage(
                      image: AssetImage(
                        'assets/calda_bug_logo.png',
                        package: 'calda_bug_sdk',
                      ),
                      fit: BoxFit.contain,
                    ),
            ),
            child: isRecording
                ? const Center(
                    child: Icon(Icons.stop, color: Colors.white, size: 32),
                  )
                : isBusy
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
          ),
        ),
      ),
    );
  }
}
