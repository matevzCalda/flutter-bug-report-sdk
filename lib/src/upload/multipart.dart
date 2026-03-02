import 'package:http/http.dart' as http;

http.MultipartFile bytesPart(
  String filename,
  List<int> bytes, {
  required String contentType,
}) {
  return http.MultipartFile.fromBytes(
    'files',
    bytes,
    filename: filename,
    contentType: _parseMediaType(contentType),
  );
}

// Minimal MediaType shim to avoid extra deps; you can add http_parser for real MediaType.
dynamic _parseMediaType(String ct) => null;
