import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../models.dart';
import '../auth/supabase.dart';

class CaldaReportSheetResult {
  final bool send;
  final String userMessage;
  final String env;

  const CaldaReportSheetResult({
    required this.send,
    required this.userMessage,
    required this.env,
  });
}

const _borderColor = Color(0xFFE4E4E7);
const _foregroundColor = Color(0xFF18181B);
const _sidebarForeground = Color(0xFF3F3F46);
const _primaryForeground = Color(0xFFFAFAFA);
const _hintColor = Color(0xFFA1A1AA);
const _chipBg = Color(0xFFF9FAFB);
const _chipBorder = Color(0xFFF3F4F6);
const _separatorColor = Color(0xFFF3F4F6);

const _descriptionHint = 'Write a description including:\n\n'
    '1. A description of what happened.\n'
    '2. Explanation of what you expected to happen.\n'
    '3. List the steps to reproduce the issue.\n'
    '4. Attach screenshots or screen recordings if possible.\n'
    '5. Include the device and app version.';

const _platformOptions = ['Web', 'Apple', 'Android', 'Figma'];
const _envOptions = ['STAGING', 'PRODUCTION'];

Future<CaldaReportSheetResult?> showCaldaReportSheet(
  BuildContext context, {
  required Uint8List? screenshotPng,
  required List<String> consoleLines,
  Map<String, String>? deviceInfo,
  String? reproductionSummary,
  List<ReportAttachment> attachments = const [],
}) async {
  return showModalBottomSheet<CaldaReportSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _CaldaReportSheetContent(
        screenshotPng: screenshotPng,
        consoleLines: consoleLines,
        deviceInfo: deviceInfo ?? {},
        reproductionSummary: reproductionSummary,
        attachments: attachments,
      );
    },
  );
}

class _CaldaReportSheetContent extends StatefulWidget {
  final Uint8List? screenshotPng;
  final List<String> consoleLines;
  final Map<String, String> deviceInfo;
  final String? reproductionSummary;
  final List<ReportAttachment> attachments;

  const _CaldaReportSheetContent({
    required this.screenshotPng,
    required this.consoleLines,
    required this.deviceInfo,
    required this.reproductionSummary,
    required this.attachments,
  });

  @override
  State<_CaldaReportSheetContent> createState() =>
      _CaldaReportSheetContentState();
}

class _CaldaReportSheetContentState extends State<_CaldaReportSheetContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String _selectedEnv = 'STAGING';
  String _selectedPlatform = 'Apple';
  bool _sending = false;

  bool get _canCreate => _titleController.text.trim().isNotEmpty && !_sending;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _titleController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _titleController.removeListener(_onChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop(null);
  }

  Future<void> _handleCreate() async {
    setState(() => _sending = true);
    try {
      final supabase = getSupabaseClient();
      final res = await supabase.functions.invoke(
        'test-from-sdk',
        body: {'name': 'Functions'},
      );

      if (res.status != 200) {
        throw Exception('Edge function error: ${res.status}');
      }

      if (!mounted) return;
      final userMessage =
          'Title: ${_titleController.text.trim()}\n\n${_descriptionController.text.trim()}';
      Navigator.of(context).pop(CaldaReportSheetResult(
        send: true,
        userMessage: userMessage,
        env: _selectedEnv.toLowerCase(),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final hasMedia = (widget.screenshotPng != null &&
            widget.screenshotPng!.isNotEmpty) ||
        widget.attachments.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.fromBorderSide(BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 17.9,
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 1,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 71,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: _borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Close button
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _close,
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: Icon(Icons.close,
                                size: 20, color: _sidebarForeground),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Title "Report a bug"
                      const Text(
                        'Report a bug',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _foregroundColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Platform & Environment dropdowns row
                      Row(
                        children: [
                          _buildDropdownChip(
                            value: _selectedPlatform,
                            items: _platformOptions,
                            icon: _platformIcon(_selectedPlatform),
                            onChanged: (v) =>
                                setState(() => _selectedPlatform = v),
                          ),
                          const SizedBox(width: 8),
                          _buildDropdownChip(
                            value: _selectedEnv,
                            items: _envOptions,
                            icon: _envIcon(_selectedEnv),
                            onChanged: (v) =>
                                setState(() => _selectedEnv = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Title input (borderless, like web)
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter the title',
                          hintStyle: TextStyle(color: _hintColor, fontSize: 16),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: _foregroundColor,
                        ),
                      ),
                      // Separator
                      Container(
                        height: 1,
                        color: _separatorColor,
                      ),
                      const SizedBox(height: 12),
                      // Description
                      TextField(
                        controller: _descriptionController,
                        maxLines: null,
                        minLines: 8,
                        decoration: const InputDecoration(
                          hintText: _descriptionHint,
                          hintStyle: TextStyle(color: _hintColor, fontSize: 14),
                          hintMaxLines: 10,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: _foregroundColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Media block
                      if (hasMedia)
                        _buildMediaBlock()
                      else
                        _buildEmptyMediaBlock(),
                    ],
                  ),
                ),
              ),
              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdownChip({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _chipBg,
        border: Border.all(color: _chipBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down,
              size: 16, color: _sidebarForeground),
          borderRadius: BorderRadius.circular(6),
          dropdownColor: Colors.white,
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          e == value ? icon : _iconForItem(e, items),
                          size: 14,
                          color: _sidebarForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          e,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _sidebarForeground,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  IconData _iconForItem(String item, List<String> list) {
    if (list == _platformOptions) return _platformIcon(item);
    return _envIcon(item);
  }

  static IconData _platformIcon(String platform) {
    switch (platform) {
      case 'Web':
        return Icons.language;
      case 'Apple':
        return Icons.apple;
      case 'Android':
        return Icons.android;
      case 'Figma':
        return Icons.design_services;
      default:
        return Icons.device_unknown;
    }
  }

  static IconData _envIcon(String env) {
    switch (env) {
      case 'STAGING':
        return Icons.flight_takeoff;
      case 'PRODUCTION':
        return Icons.star;
      default:
        return Icons.settings;
    }
  }

  Widget _buildMediaBlock() {
    final allMedia = <Widget>[];

    if (widget.screenshotPng != null && widget.screenshotPng!.isNotEmpty) {
      allMedia.add(_buildMediaTile(
        child: Image.memory(widget.screenshotPng!, fit: BoxFit.contain),
      ));
    }

    for (final attachment in widget.attachments) {
      if (attachment.type == 'video') {
        allMedia.add(_buildMediaTile(
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, size: 32, color: _sidebarForeground),
              SizedBox(height: 4),
              Text('Video',
                  style: TextStyle(fontSize: 12, color: _sidebarForeground)),
            ],
          ),
        ));
      } else if (attachment.type == 'image') {
        allMedia.add(_buildMediaTile(
          child: Image.memory(attachment.data, fit: BoxFit.contain),
        ));
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allMedia,
    );
  }

  Widget _buildMediaTile({required Widget child}) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
        color: _chipBg,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildEmptyMediaBlock() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
        color: _chipBg,
      ),
      alignment: Alignment.center,
      child: const Text(
        'No image or video',
        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _close,
              style: OutlinedButton.styleFrom(
                foregroundColor: _foregroundColor,
                side: const BorderSide(color: _borderColor),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _canCreate ? _handleCreate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _foregroundColor,
                foregroundColor: _primaryForeground,
                disabledBackgroundColor: _foregroundColor.withValues(alpha: 0.5),
                disabledForegroundColor: _primaryForeground.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                minimumSize: const Size(101, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: Text(_sending ? 'Sending...' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
