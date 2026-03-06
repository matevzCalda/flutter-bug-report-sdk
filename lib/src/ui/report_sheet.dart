import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../models.dart';

Widget _buildAttachmentsSection(
    BuildContext ctx, List<ReportAttachment> attachments) {
  final videoAttachments =
      attachments.where((a) => a.type == 'video').toList();
  final imageAttachments =
      attachments.where((a) => a.type == 'image').toList();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (videoAttachments.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Video recording',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.videocam, size: 40),
                  const SizedBox(width: 12),
                  Text(
                    '${videoAttachments.length} video(s) · ${_formatBytes(videoAttachments.fold<int>(0, (s, a) => s + a.data.length))}',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      if (videoAttachments.isNotEmpty && imageAttachments.isNotEmpty)
        const SizedBox(height: 8),
      if (imageAttachments.isNotEmpty)
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imageAttachments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final a = imageAttachments[i];
              return SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(a.data, fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
    ],
  );
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

Future<bool?> showCaldaReportSheet(
  BuildContext context, {
  required Uint8List? screenshotPng,
  required List<String> consoleLines,
  Map<String, String>? deviceInfo,
  String? reproductionSummary,
  List<ReportAttachment> attachments = const [],
}) async {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).viewInsets.bottom;
      final deviceInfoEntries = deviceInfo?.entries.toList() ?? [];
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (screenshotPng != null && screenshotPng.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    screenshotPng,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (attachments.isNotEmpty) ...[
              _buildAttachmentsSection(ctx, attachments),
              const SizedBox(height: 12),
            ],
            if (reproductionSummary != null &&
                reproductionSummary.trim().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Reproduction',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      reproductionSummary,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 200,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: consoleLines.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: SelectableText(
                      consoleLines[i],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (deviceInfoEntries.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: deviceInfoEntries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: SelectableText(
                            '${e.key}: ${e.value}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Send'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
