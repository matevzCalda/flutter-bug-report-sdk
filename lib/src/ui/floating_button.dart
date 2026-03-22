import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;
import 'package:url_launcher/url_launcher.dart';
import '../../calda_bug_sdk.dart';
import '../models.dart';
import '../screenshot/capture.dart';
import '../recording/viewport_recorder.dart';
import '../recording/screen_record_recorder.dart';
import '../auth/supabase.dart' as auth;
import 'report_sheet.dart';
import 'login_screen.dart';

class CaldaBugFloatingButton extends StatefulWidget {
  final bool enabled;
  final CaldaViewportRecorder? recorder;

  const CaldaBugFloatingButton({
    super.key,
    this.enabled = true,
    this.recorder,
  });

  @override
  State<CaldaBugFloatingButton> createState() => _CaldaBugFloatingButtonState();
}

enum _FloatingState { idle, menuOpen, busy, recording }

enum _MenuStep { main, settings }

class _CaldaBugFloatingButtonState extends State<CaldaBugFloatingButton> {
  _FloatingState _state = _FloatingState.idle;
  _MenuStep _menuStep = _MenuStep.main;
  Timer? _recordingTimer;
  static const _maxRecordingMs = 30000;
  OverlayEntry? _menuOverlay;
  OverlayEntry? _toastOverlay;
  CaldaViewportRecorder? _cachedDefaultRecorder;
  bool _isAuthed = false;
  StreamSubscription? _authSubscription;

  CaldaViewportRecorder get _recorder {
    if (widget.recorder != null) return widget.recorder!;
    _cachedDefaultRecorder ??= createCaldaScreenRecordRecorder();
    return _cachedDefaultRecorder!;
  }

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    if (!auth.isSupabaseInitialized) {
      await auth.ensureSupabaseInitialized();
    }
    if (!mounted) return;
    // Use async token check to determine if we have a valid session
    final token = await auth.getAccessToken();
    if (!mounted) return;
    _isAuthed = token != null;
    setState(() {});
    _authSubscription =
        auth.getSupabaseClient().auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.signedOut) {
        setState(() => _isAuthed = false);
      } else if (data.session != null) {
        setState(() => _isAuthed = true);
      }
    });
  }

  Future<void> _checkAuth() async {
    final token = await auth.getAccessToken();
    _isAuthed = token != null;
  }

  @override
  void dispose() {
    _removeMenuOverlay();
    _removeToastOverlay();
    _recordingTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _removeMenuOverlay() {
    _menuOverlay?.remove();
    _menuOverlay = null;
  }

  void _removeToastOverlay() {
    _toastOverlay?.remove();
    _toastOverlay = null;
  }

  void _showSuccessToast() {
    _removeToastOverlay();
    final overlay = Overlay.of(context);
    _toastOverlay = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          top: MediaQuery.of(ctx).padding.top + 16,
          left: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE4E4E7)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 15,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 16, color: Colors.black),
                  SizedBox(width: 4),
                  Text(
                    'New Ticket has been added',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_toastOverlay!);
    Future.delayed(const Duration(seconds: 3), () {
      _removeToastOverlay();
    });
  }

  Future<void> _openReportSheet({
    Uint8List? screenshotPng,
    List<ReportAttachment> attachments = const [],
  }) async {
    final consoleLines = CaldaBug.getLastLogLines(limit: 500);
    final deviceInfo = await DeviceInfo.collect();
    final deviceInfoDisplay = deviceInfo.toDisplayMap();
    deviceInfoDisplay['Theme'] =
        Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
    deviceInfoDisplay['Locale'] = Localizations.localeOf(context).toString();
    if (!mounted) return;
    final result = await showCaldaReportSheet(
      context,
      screenshotPng: screenshotPng,
      consoleLines: consoleLines,
      deviceInfoData: deviceInfo,
      deviceInfoDisplay: deviceInfoDisplay,
      reproductionSummary: CaldaBug.getReproductionSummary(),
      attachments: attachments,
    );

    if (mounted) setState(() => _state = _FloatingState.idle);

    // CaldaBug.report() is called inside the sheet itself.
    // If sheet returned a sent result, show success toast.
    if (result != null && result.sent && mounted) {
      _showSuccessToast();
    }
  }

  void _handleMainClick() {
    if (_state != _FloatingState.idle) return;
    if (!_isAuthed) {
      _openLoginSheet();
    } else {
      _openMenu();
    }
  }

  Future<void> _openLoginSheet() async {
    final success = await showCaldaLoginSheet(context);
    if (success == true && mounted) {
      await _checkAuth();
      setState(() {});
      _openMenu();
    }
  }

  void _openMenu() {
    if (_state != _FloatingState.idle) return;
    _menuStep = _MenuStep.main;
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final buttonRect =
        box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: StatefulBuilder(
                      builder: (ctx, setMenuState) {
                        if (_menuStep == _MenuStep.main) {
                          return _buildMainMenu(setMenuState);
                        } else {
                          return _buildSettingsMenu(setMenuState);
                        }
                      },
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

  Widget _buildMainMenu(StateSetter setMenuState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _menuItem(
          label: 'Take a screenshot and report',
          onTap: _onScreenshotChosen,
        ),
        _menuItem(
          label: 'Start recording (max 30s)',
          onTap: _onStartRecording,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
        ),
        _menuItem(
          label: 'Settings',
          onTap: () {
            _menuStep = _MenuStep.settings;
            _menuOverlay?.markNeedsBuild();
          },
        ),
      ],
    );
  }

  Widget _buildSettingsMenu(StateSetter setMenuState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _menuItem(
          label: 'Manage user',
          onTap: () {
            launchUrl(
              Uri.parse('https://calda-bugsense-frontend.vercel.app/login'),
              mode: LaunchMode.externalApplication,
            );
            _closeMenu();
          },
        ),
        _menuItem(
          label: 'Log out',
          onTap: () async {
            await auth.signOut();
            _closeMenu();
            if (mounted) {
              await _checkAuth();
              setState(() {});
            }
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
        ),
        _menuItem(
          label: 'Go back',
          onTap: () {
            _menuStep = _MenuStep.main;
            _menuOverlay?.markNeedsBuild();
          },
        ),
      ],
    );
  }

  Widget _menuItem({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }

  void _closeMenu() {
    if (_state == _FloatingState.menuOpen) {
      _removeMenuOverlay();
      _menuStep = _MenuStep.main;
      setState(() => _state = _FloatingState.idle);
    }
  }

  void _onScreenshotChosen() async {
    _closeMenu();
    // Small delay so the menu overlay is fully removed before capture.
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    final png = await capturePng();
    if (!mounted) return;
    await _openReportSheet(screenshotPng: png);
  }

  void _onStartRecording() async {
    final recorder = _recorder;
    _closeMenu();
    setState(() => _state = _FloatingState.recording);
    _recordingTimer =
        Timer(const Duration(milliseconds: _maxRecordingMs), () async {
      _recordingTimer = null;
      if (!mounted || _state != _FloatingState.recording) return;
      final videoBytes = await recorder.stop();
      if (!mounted) return;
      if (videoBytes == null || videoBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Recording could not be exported. Try again.')),
          );
        }
      }
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
    if (videoBytes == null || videoBytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Recording could not be exported. Try again.')),
        );
      }
    }
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
          onTap: isRecording ? _onStopRecording : _handleMainClick,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isRecording
                  ? const Color(0xFFCC0000)
                  : const Color(0xFF18181B),
              shape: BoxShape.circle,
              border: Border.all(
                color: isRecording
                    ? const Color(0xFFCC0000)
                    : const Color(0x33FFFFFF),
                width: isRecording ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: isRecording
                ? Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )
                : isBusy
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/calda_bug_logo.png',
                          package: 'calda_bug_sdk',
                          width: 24,
                          height: 24,
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
