import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'boundary.dart';

Future<Uint8List?> capturePng({
  double pixelRatio = 2.0,
}) async {
  final context = CaldaBugBoundary.boundaryKey.currentContext;
  if (context == null) return null;
  final boundary = context.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;

  // Ensure the pipeline is flushed so the boundary is fully painted
  // before calling toImage. Without this, toImage may assert in debug
  // mode (debugNeedsPaint) or return a stale/empty image.
  final owner = boundary.owner;
  if (owner != null) {
    owner.flushLayout();
    owner.flushCompositingBits();
    owner.flushPaint();
  }

  try {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}
