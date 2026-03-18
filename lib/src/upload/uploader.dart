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

    print('[CaldaBug] uploadReport: endpoint=$endpoint');
    print('[CaldaBug] uploadReport: payloadGzipJson=${payloadGzipJson.length} bytes');
    print('[CaldaBug] uploadReport: screenshotPng=${screenshotPng?.length ?? 0} bytes');
    print('[CaldaBug] uploadReport: attachments=${attachments.length}');
    print('[CaldaBug] uploadReport: authToken=${authToken.isNotEmpty ? "${authToken.substring(0, 10)}..." : "(empty)"}');

    // Build the list of file parts
    final files = <MultipartFile>[
      // 1. Gzipped JSON payload
      MultipartFile.fromBytes(
        payloadGzipJson,
        filename: 'payload.json.gz',
        contentType: DioMediaType('application', 'gzip'),
      ),
    ];
    print('[CaldaBug] added file: payload.json.gz (${payloadGzipJson.length} bytes, application/gzip)');

    // 2. Screenshot
    if (screenshotPng != null && screenshotPng.isNotEmpty) {
      files.add(MultipartFile.fromBytes(
        screenshotPng,
        filename: 'screenshot.png',
        contentType: DioMediaType('image', 'png'),
      ));
      print('[CaldaBug] added file: screenshot.png (${screenshotPng.length} bytes, image/png)');
    } else {
      print('[CaldaBug] no screenshot attached');
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
      files.add(MultipartFile.fromBytes(a.data, filename: name, contentType: ct));
      print('[CaldaBug] added file: $name (${a.data.length} bytes, ${ct.mimeType})');
    }

    final formData = FormData.fromMap({
      'platform': 'flutter',
      'files': files,
    });

    print('[CaldaBug] formData fields: ${formData.fields.map((e) => "${e.key}=${e.value}").toList()}');
    print('[CaldaBug] formData files: ${formData.files.map((e) => "${e.key}=${e.value.filename}").toList()}');

    final dio = Dio(BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      // Accept all status codes so we can read the response body on errors.
      validateStatus: (_) => true,
    ));

    print('[CaldaBug] sending POST to $endpoint ...');

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

    print('[CaldaBug] response: statusCode=$statusCode');
    print('[CaldaBug] response headers: ${response.headers.map}');
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
