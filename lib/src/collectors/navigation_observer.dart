import 'package:flutter/widgets.dart';

typedef RouteSink = void Function(String? from, String to);

class CaldaBugNavigatorObserver extends NavigatorObserver {
  final RouteSink onRoute;
  CaldaBugNavigatorObserver({required this.onRoute});

  String? _name(Route<dynamic>? r) => r?.settings.name;

  @override
  void didPush(Route route, Route? previousRoute) {
    onRoute(_name(previousRoute), _name(route) ?? route.toString());
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    onRoute(_name(oldRoute), _name(newRoute) ?? newRoute.toString());
  }
}
