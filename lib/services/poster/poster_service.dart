import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class PosterService {
  /// Render a widget to PNG bytes at 3x resolution.
  static Future<Uint8List?> renderToPng(
    BuildContext context,
    Widget widget, {
    Size size = const Size(400, 600),
  }) async {
    final key = GlobalKey();

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top: -10000,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: widget,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Wait for rendering
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await WidgetsBinding.instance.endOfFrame;

    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }
}
