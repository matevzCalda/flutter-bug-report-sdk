import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../models.dart';

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
const _dropdownBg = Color(0xFFF9FAFB);

Widget _buildMediaPreview(
  BuildContext context, {
  Uint8List? screenshotPng,
  List<ReportAttachment> attachments = const [],
}) {
  const aspectRatio = 3 / 4;
  const maxHeight = 200.0;

  if (screenshotPng != null && screenshotPng.isNotEmpty) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: maxHeight * aspectRatio),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.memory(
              screenshotPng,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
  final videoAttachments = attachments.where((a) => a.type == 'video').toList();
  final imageAttachments = attachments.where((a) => a.type == 'image').toList();
  if (videoAttachments.isNotEmpty) {
    return Center(
      child: SizedBox(
        width: maxHeight * aspectRatio,
        height: maxHeight,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam, size: 40, color: _sidebarForeground),
              const SizedBox(width: 12),
              Text(
                '${videoAttachments.length} video(s)',
                style: const TextStyle(fontSize: 14, color: _foregroundColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
  if (imageAttachments.isNotEmpty) {
    final first = imageAttachments.first;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: maxHeight * aspectRatio),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.memory(first.data, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
  return const SizedBox.shrink();
}

const _descriptionHint = 'Write a description including:\n'
    '1. Describe what happened.\n'
    '2. Explanation of what you expected to happen.\n'
    '3. List the steps to reproduce the issue.\n'
    '4. Attach screenshots or screen recordings if possible.\n'
    '5. Include the device and app version';

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
  static const _envStaging = 'STAGING';
  static const _envProduction = 'PRODUCTION';

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String _selectedEnv = _envStaging;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit(bool send) {
    final userMessage = send
        ? 'Title: ${_titleController.text.trim()}\n\n${_descriptionController.text.trim()}'
        : '';
    Navigator.of(context).pop(CaldaReportSheetResult(
      send: send,
      userMessage: userMessage,
      env: _selectedEnv.toLowerCase(),
    ));
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
            offset: Offset(0, 0),
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 71,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'New report',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _sidebarForeground,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _submit(false),
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: Icon(Icons.close, size: 20, color: _sidebarForeground),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: _dropdownBg,
                          border: Border.all(color: _borderColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedEnv,
                            isExpanded: false,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: _sidebarForeground,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            dropdownColor: Colors.white,
                            items: [_envStaging, _envProduction]
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.flight_takeoff, size: 12, color: _sidebarForeground),
                                          const SizedBox(width: 4),
                                          Text(e, style: const TextStyle(fontSize: 12, color: _sidebarForeground)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedEnv = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Title',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _foregroundColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter the title',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: _borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: _borderColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14, color: _foregroundColor),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _foregroundColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: _descriptionHint,
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: _borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: _borderColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14, color: _foregroundColor),
                      ),
                      if (hasMedia) ...[
                        const SizedBox(height: 16),
                        _buildMediaPreview(
                          context,
                          screenshotPng: widget.screenshotPng,
                          attachments: widget.attachments,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _borderColor, width: 1)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _submit(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _foregroundColor,
                            side: const BorderSide(color: _borderColor),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _submit(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _foregroundColor,
                            foregroundColor: _primaryForeground,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                          child: const Text('Create'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

}
