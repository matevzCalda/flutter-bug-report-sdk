import 'package:dio/dio.dart';
import '../models.dart';
import '../time.dart';

class CaldaBugDioInterceptor extends Interceptor {
  final void Function(BugEvent) add;
  final Stopwatch clock;
  final String Function(String url) redactUrl;

  CaldaBugDioInterceptor({
    required this.add,
    required this.clock,
    required this.redactUrl,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['_caldaStart'] = DateTime.now().microsecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final start = response.requestOptions.extra['_caldaStart'] as int?;
    final ms = start == null
        ? null
        : ((DateTime.now().microsecondsSinceEpoch - start) / 1000).round();
    add(
      BugEvent.net(
        t: nowMs(clock),
        method: response.requestOptions.method,
        url: redactUrl(response.requestOptions.uri.toString()),
        status: response.statusCode,
        ms: ms,
        attrs: const {'client': 'dio'},
      ),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final req = err.requestOptions;
    final start = req.extra['_caldaStart'] as int?;
    final ms = start == null
        ? null
        : ((DateTime.now().microsecondsSinceEpoch - start) / 1000).round();
    add(
      BugEvent.net(
        t: nowMs(clock),
        method: req.method,
        url: redactUrl(req.uri.toString()),
        status: err.response?.statusCode,
        ms: ms,
        attrs: {'client': 'dio', 'error': err.type.name},
      ),
    );
    handler.next(err);
  }
}
