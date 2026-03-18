import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models.dart';

class Uploader {
  final Uri endpoint;
  final String apiKey;
  final Duration timeout;

  Uploader(this.endpoint, this.apiKey, {required this.timeout});

  Future<UploadResult> uploadReport({
    required String title,
    required String description,
    required String platform,
    required String environment,
    required String appVersion,
    Uint8List? screenshotPng,
    List<ReportAttachment> attachments = const [],
    String? token,
  }) async {
    final authToken = token ?? apiKey;

    print('[CaldaBug] uploadReport: endpoint=$endpoint');

    final request = http.MultipartRequest('POST', endpoint);
    request.headers['Authorization'] = 'Bearer $authToken';

    // Required form fields
    request.fields['title'] = title;
    request.fields['platform'] = platform;
    request.fields['environment'] = environment;
    request.fields['description'] = description;
    request.fields['appVersion'] = appVersion;

    print('[CaldaBug] fields: ${request.fields}');

    // Screenshot
    if (screenshotPng != null && screenshotPng.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'files',
        screenshotPng,
        filename: 'screenshot.png',
        contentType: MediaType('image', 'png'),
      ));
      print('[CaldaBug] added file: screenshot.png (${screenshotPng.length} bytes)');
    }

    // Extra attachments (images / videos)
    for (var i = 0; i < attachments.length; i++) {
      final a = attachments[i];
      final ext = a.type == 'video' ? 'webm' : 'png';
      final name = a.filename ?? 'attachment_$i.$ext';
      final MediaType ct;
      if (a.type == 'video') {
        ct = name.endsWith('.mp4')
            ? MediaType('video', 'mp4')
            : MediaType('video', 'webm');
      } else {
        ct = MediaType('image', 'png');
      }
      request.files.add(http.MultipartFile.fromBytes(
        'files',
        a.data,
        filename: name,
        contentType: ct,
      ));
      print('[CaldaBug] added file: $name (${a.data.length} bytes, $ct)');
    }

    print('[CaldaBug] sending POST to $endpoint ...');

    final streamed = await request.send().timeout(timeout);
    final body = await streamed.stream.bytesToString();
    final statusCode = streamed.statusCode;

    print('[CaldaBug] response: statusCode=$statusCode');
    print('[CaldaBug] response body: $body');

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('Upload failed ($statusCode): $body');
    }

    return _parseUploadResponse(body);
  }

  UploadResult _parseUploadResponse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final reportId = json['reportId'] as String? ?? '';
      final viewerUrlStr = json['viewerUrl'] as String?;
      return UploadResult(
        reportId: reportId,
        viewerUrl: viewerUrlStr != null ? Uri.parse(viewerUrlStr) : Uri(),
      );
    } catch (_) {
      return UploadResult(reportId: '', viewerUrl: Uri());
    }
  }
}
