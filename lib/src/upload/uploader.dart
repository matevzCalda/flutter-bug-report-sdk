import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models.dart';

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

    final formData = FormData();

    // 1. Gzipped JSON payload
    formData.files.add(MapEntry(
      'files',
      MultipartFile.fromBytes(
        payloadGzipJson,
        filename: 'payload.json.gz',
        contentType: DioMediaType('application', 'gzip'),
      ),
    ));

    // 2. Screenshot
    if (screenshotPng != null && screenshotPng.isNotEmpty) {
      formData.files.add(MapEntry(
        'files',
        MultipartFile.fromBytes(
          screenshotPng,
          filename: 'screenshot.png',
          contentType: DioMediaType('image', 'png'),
        ),
      ));
    }

    // 3. Extra attachments (images / videos)
    for (var i = 0; i < attachments.length; i++) {
      final a = attachments[i];
      final ext = a.type == 'video' ? 'webm' : 'png';
      final name = a.filename ?? 'attachment_$i.$ext';
      final DioMediaType ct;
      if (a.type == 'video') {
        ct = name.endsWith('.mp4')
            ? DioMediaType('video', 'mp4')
            : DioMediaType('video', 'webm');
      } else {
        ct = DioMediaType('image', 'png');
      }
      formData.files.add(MapEntry(
        'files',
        MultipartFile.fromBytes(a.data, filename: name, contentType: ct),
      ));
    }

    final dio = Dio(BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
    ));

    final response = await dio.postUri<Map<String, dynamic>>(
      endpoint,
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $authToken'},
      ),
    );

    final data = response.data ?? {};
    final reportId = data['reportId'] as String? ?? '';
    final viewerUrlStr = data['viewerUrl'] as String?;
    final viewerUrl =
        viewerUrlStr != null ? Uri.parse(viewerUrlStr) : Uri();
    return UploadResult(reportId: reportId, viewerUrl: viewerUrl);
  }
}
