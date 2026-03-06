import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models.dart';

void Function(BugEvent)? _breadcrumbAdd;
bool _breadcrumbEnabled = false;
int Function()? _breadcrumbNowMs;
String? Function()? _breadcrumbLastRoute;

void configureBreadcrumbCapture({
  required void Function(BugEvent) add,
  required bool enabled,
  required int Function() nowMs,
  String? Function()? lastRoute,
}) {
  _breadcrumbAdd = add;
  _breadcrumbEnabled = enabled;
  _breadcrumbNowMs = nowMs;
  _breadcrumbLastRoute = lastRoute;
}

class CaldaBugBreadcrumbScope extends StatelessWidget {
  final Widget child;

  const CaldaBugBreadcrumbScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!_breadcrumbEnabled) return child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _onPointerDown(event.position),
      child: child,
    );
  }

  void _onPointerDown(Offset position) {
    final add = _breadcrumbAdd;
    if (add == null) return;
    try {
      String target = 'tap';
      final hit = HitTestResult();
      final viewId = WidgetsBinding.instance.platformDispatcher.implicitView?.viewId ?? 0;
      RendererBinding.instance.hitTestInView(hit, position, viewId);
      final path = hit.path;
      if (path.isNotEmpty) {
        target = path.first.target.runtimeType.toString();
      }
      final route = _breadcrumbLastRoute?.call() ?? '';
      add(
        BugEvent.breadcrumb(
          t: _breadcrumbNowMs?.call() ?? 0,
          action: 'tap',
          target: target,
          route: route,
          attrs: const {},
        ),
      );
    } catch (_) {}
  }
}
