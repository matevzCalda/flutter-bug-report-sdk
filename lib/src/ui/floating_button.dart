import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../calda_bug_sdk.dart';
import '../models.dart';
import '../screenshot/capture.dart';
import '../recording/viewport_recorder.dart';
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

enum _FloatingState { idle, busy, recording }

class _CaldaBugFloatingButtonState extends State<CaldaBugFloatingButton> {
  _FloatingState _state = _FloatingState.idle;
  Timer? _recordingTimer;
  static const _maxRecordingMs = 30000;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
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

  void _onMainButtonTap() async {
    if (_state != _FloatingState.idle) return;
    final recorder = widget.recorder;
    final showRecording = recorder != null;

    if (showRecording) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take screenshot and report'),
                  onTap: () => Navigator.of(ctx).pop('screenshot'),
                ),
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: const Text('Start recording (max 30s)'),
                  onTap: () => Navigator.of(ctx).pop('recording'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      );
      if (choice == null || !mounted) return;
      if (choice == 'screenshot') {
        setState(() => _state = _FloatingState.busy);
        final png = await capturePng(widget.repaintKey);
        if (!mounted) return;
        await _openReportSheet(screenshotPng: png);
        return;
      }
      if (choice == 'recording') {
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
                    filename: 'recording.webm',
                  ),
                ]
              : <ReportAttachment>[];
          await _openReportSheet(attachments: attachments);
        });
        try {
          await recorder.start();
        } catch (_) {
          if (mounted) setState(() => _state = _FloatingState.idle);
          _recordingTimer?.cancel();
          _recordingTimer = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording failed to start.')),
          );
        }
        return;
      }
    }

    setState(() => _state = _FloatingState.busy);
    final png = await capturePng(widget.repaintKey);
    if (!mounted) return;
    await _openReportSheet(screenshotPng: png);
  }

  void _onStopRecording() async {
    if (_state != _FloatingState.recording || widget.recorder == null) return;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final videoBytes = await widget.recorder!.stop();
    if (!mounted) return;
    final attachments = videoBytes != null && videoBytes.isNotEmpty
        ? [
            ReportAttachment(
              type: 'video',
              data: videoBytes,
              filename: 'recording.webm',
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
          onTap: isRecording ? _onStopRecording : _onMainButtonTap,
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
