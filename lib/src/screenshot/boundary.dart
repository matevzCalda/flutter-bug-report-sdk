import 'package:flutter/widgets.dart';

class CaldaBugBoundary extends StatelessWidget {
  static final GlobalKey boundaryKey = GlobalKey();

  final Widget child;

  const CaldaBugBoundary({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(key: boundaryKey, child: child);
  }
}
