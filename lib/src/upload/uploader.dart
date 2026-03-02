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
  }) async {
    final req = http.MultipartRequest('POST', endpoint);
    req.headers['Authorization'] = 'Bearer $apiKey';
    req.files.add(
      bytesPart(
        'payload.json.gz',
        payloadGzipJson,
        contentType: 'application/gzip',
      ),
    );

    if (screenshotPng != null) {
      req.files.add(
        bytesPart('screenshot.png', screenshotPng, contentType: 'image/png'),
      );
    }

    final streamed = await req.send().timeout(timeout);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Upload failed: ${streamed.statusCode} $body');
    }

    // Expect JSON: { reportId, viewerUrl }
    final parsed = parseUploadResponse(body);
    return parsed;
  }

  UploadResult parseUploadResponse(String body) {
    // keep skeleton simple; implement jsonDecode
    // return UploadResult(reportId: '...', viewerUrl: Uri.parse('...'));
    throw UnimplementedError('Implement JSON parsing for upload response');
  }
}
