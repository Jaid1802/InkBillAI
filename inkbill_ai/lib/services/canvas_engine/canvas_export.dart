import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inkbill_ai/features/handwriting/domain/entities/ink_stroke.dart';
import 'package:inkbill_ai/services/canvas_engine/canvas_renderer.dart';

class CanvasExport {
  final CanvasRenderer _renderer;

  CanvasExport({CanvasRenderer? renderer})
      : _renderer = renderer ?? CanvasRenderer();

  Future<ui.Image> renderToImage(
    List<InkStroke> strokes, {
    double scale = 4.0,
    Size? size,
    Rect? cropRect,
  }) async {
    Rect bounds;
    if (cropRect != null) {
      bounds = cropRect;
    } else {
      bounds = _renderer.calculateBounds(strokes);
      if (bounds == Rect.zero) {
        bounds = const Rect.fromLTWH(0, 0, 100, 100);
      }
    }

    final renderSize = Size(bounds.width, bounds.height);
    final picture = _renderer.renderToPicture(
      strokes,
      renderSize,
      scale: scale,
      cropRect: bounds,
    );

    final image = await picture.toImage(
      (renderSize.width * scale).round(),
      (renderSize.height * scale).round(),
    );
    return image;
  }

  Future<List<int>> renderToPngBytes(
    List<InkStroke> strokes, {
    double scale = 4.0,
    Rect? cropRect,
  }) async {
    final image = await renderToImage(strokes, scale: scale, cropRect: cropRect);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to generate PNG');
    return byteData.buffer.asUint8List();
  }

  Future<File> renderToFile(
    List<InkStroke> strokes, {
    double scale = 4.0,
    Rect? cropRect,
    String? fileName,
  }) async {
    final bytes = await renderToPngBytes(strokes, scale: scale, cropRect: cropRect);
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/${fileName ?? "ink_export_${DateTime.now().millisecondsSinceEpoch}"}.png',
    );
    await file.writeAsBytes(bytes);
    return file;
  }

  Rect calculateCropBounds(
    List<InkStroke> strokes, {
    double padding = 20.0,
    double minWidth = 100.0,
    double minHeight = 100.0,
  }) {
    final bounds = _renderer.calculateBounds(strokes);
    if (bounds == Rect.zero) {
      return Rect.fromLTWH(0, 0, minWidth, minHeight);
    }
    final w = math.max(bounds.width + padding * 2, minWidth);
    final h = math.max(bounds.height + padding * 2, minHeight);
    final cx = bounds.center.dx;
    final cy = bounds.center.dy;
    return Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
  }

  void dispose() {
    _renderer.dispose();
  }
}
