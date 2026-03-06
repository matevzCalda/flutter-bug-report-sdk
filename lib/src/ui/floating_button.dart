import 'package:flutter/material.dart';
import '../../calda_bug_sdk.dart';
import '../models.dart';
import '../screenshot/capture.dart';
import 'report_sheet.dart';

class CaldaBugFloatingButton extends StatefulWidget {
  final GlobalKey repaintKey;
  final bool enabled;

  const CaldaBugFloatingButton({
    super.key,
    required this.repaintKey,
    this.enabled = true,
  });

  @override
  State<CaldaBugFloatingButton> createState() => _CaldaBugFloatingButtonState();
}

class _CaldaBugFloatingButtonState extends State<CaldaBugFloatingButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return Positioned(
      right: 16,
      bottom: 24,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  final png = await capturePng(widget.repaintKey);
                  final consoleLines = CaldaBug.getLastLogLines(limit: 500);
                  final deviceInfo = await DeviceInfo.collect();
                  final deviceInfoMap = deviceInfo.toDisplayMap();
                  deviceInfoMap['Theme'] =
                      Theme.of(context).brightness == Brightness.dark
                          ? 'dark'
                          : 'light';
                  deviceInfoMap['Locale'] =
                      Localizations.localeOf(context).toString();
                  if (!mounted) return;
                  final send = await showCaldaReportSheet(
                    context,
                    screenshotPng: png,
                    consoleLines: consoleLines,
                    deviceInfo: deviceInfoMap,
                  );
                  if (send != true) {
                    if (mounted) setState(() => _busy = false);
                    return;
                  }
                  try {
                    await CaldaBug.report(
                      userMessage: '',
                      screenshotPng: png,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bug report sent.')),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to send report.')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
          customBorder: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/calda_bug_logo.png', package: 'calda_bug_sdk'),
                fit: BoxFit.contain,
              ),
            ),
            child: _busy
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : null,
          ),
        ),
      ),
    );
  }
}
