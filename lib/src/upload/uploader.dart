import 'dart:convert';
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
      // Accept all status codes so we can read the response body on errors.
      validateStatus: (_) => true,
    ));

    final response = await dio.postUri<String>(
      endpoint,
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $authToken'},
        responseType: ResponseType.plain,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final body = response.data ?? '';

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
