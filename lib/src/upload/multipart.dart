import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

http.MultipartFile bytesPart(
  String filename,
  List<int> bytes, {
  required String contentType,
}) {
  return http.MultipartFile.fromBytes(
    'files',
    bytes,
    filename: filename,
    contentType: MediaType.parse(contentType),
  );
}
