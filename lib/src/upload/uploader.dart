import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'multipart.dart';

class Uploader {
  final Uri endpoint;
  final String apiKey;
  final Duration timeout;

  Uploader(this.endpoint, this.apiKey, {required this.timeout});

  Future<UploadResult> uploadReport({
    required List<int> payloadGzipJson,
    Uint8List? screenshotPng,
    List<ReportAttachment> attachments = const [],
    String? token,
  }) async {
    final authToken = token ?? apiKey;
    final req = http.MultipartRequest('POST', endpoint);
    req.headers['Authorization'] = 'Bearer $authToken';
    req.files.add(
      bytesPart(
        'payload.json.gz',
        payloadGzipJson,
        contentType: 'application/gzip',
      ),
    );

    if (screenshotPng != null && screenshotPng.isNotEmpty) {
      req.files.add(
        bytesPart('screenshot.png', screenshotPng, contentType: 'image/png'),
      );
    }

    for (var i = 0; i < attachments.length; i++) {
      final a = attachments[i];
      final ext = a.type == 'video' ? 'webm' : 'png';
      final name = a.filename ?? 'attachment_$i.$ext';
      final ct = a.type == 'video'
          ? (name.endsWith('.mp4') ? 'video/mp4' : 'video/webm')
          : 'image/png';
      req.files.add(bytesPart(name, a.data, contentType: ct));
    }

    final streamed = await req.send().timeout(timeout);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Upload failed: ${streamed.statusCode} $body');
    }

    return _parseUploadResponse(body);
  }

  UploadResult _parseUploadResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final reportId = json['reportId'] as String? ?? '';
    final viewerUrlStr = json['viewerUrl'] as String?;
    final viewerUrl =
        viewerUrlStr != null ? Uri.parse(viewerUrlStr) : Uri();
    return UploadResult(reportId: reportId, viewerUrl: viewerUrl);
  }
}
