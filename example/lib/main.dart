import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:calda_bug_sdk/calda_bug_sdk.dart';
import 'package:calda_bug_sdk/src/screenshot/boundary.dart';

void main() {
  CaldaBug.init(
    CaldaBugConfig(
      endpoint: Uri.parse('https://your-backend.example.com/bug-reports'),
      apiKey: 'STAGING_KEY',
      env: 'staging',
      release: 'myapp@0.0.1+1',
      app: const AppInfo(name: 'MyApp', version: '0.0.1', build: '1'),
      session: const SessionInfo(
        sessionId: 'sess_123',
        user: {'id': 'user_abc'},
      ),
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey _repaintKey = GlobalKey();
  final Dio dio = Dio();

  @override
  void initState() {
    super.initState();

    // Hook navigation observer (breadcrumbs)
    // Provide snapshot provider
    CaldaBug.setStateSnapshotProvider(
      () => {
        'featureFlags': {'newCheckout': true},
        'screen': 'home',
      },
    );

    // Instrument Dio
    final interceptor =
        CaldaBug.dioInterceptor(redactUrl: (u) => u.split('?').first);
    if (interceptor != null) dio.interceptors.add(interceptor);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [CaldaBug.navigatorObserver()],
      home: CaldaBugBreadcrumbScope(
        child: Stack(
          children: [
            CaldaBugBoundary(
            repaintKey: _repaintKey,
            child: Scaffold(
              appBar: AppBar(title: const Text('SDK Example')),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        debugPrint('User tapped test button');
                        throw Exception('Boom (test)');
                      },
                      child: const Text('Trigger error'),
                    ),
                  ],
                ),
              ),
            ),
          ),
            CaldaBugFloatingButton(
              repaintKey: _repaintKey,
              enabled: CaldaBug.config.env == 'staging',
            ),
          ],
        ),
      ),
    );
  }
}
