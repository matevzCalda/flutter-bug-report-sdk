import 'package:flutter/widgets.dart';

class CaldaBugBoundary extends StatelessWidget {
  final GlobalKey repaintKey;
  final Widget child;

  const CaldaBugBoundary({
    super.key,
    required this.repaintKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(key: repaintKey, child: child);
  }
}
