import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../services/palette.dart';

class SilhouettePainter extends CustomPainter {
  final Puzzle puzzle;
  final Color color;

  SilhouettePainter({required this.puzzle, this.color = Palette.silhouette});

  @override
  void paint(Canvas canvas, Size size) {
    // loops are normalized so the larger of (width, height) is exactly
    // 1000 and the other is <= 1000. Compute the shape's actual bounding
    // box across all loops, then "contain"-fit it into the canvas with
    // padding, centering both axes.
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final loop in puzzle.loops) {
      for (final pt in loop) {
        if (pt[0] < minX) minX = pt[0];
        if (pt[0] > maxX) maxX = pt[0];
        if (pt[1] < minY) minY = pt[1];
        if (pt[1] > maxY) maxY = pt[1];
      }
    }
    if (minX.isInfinite) return;
    final shapeW = maxX - minX;
    final shapeH = maxY - minY;
    if (shapeW <= 0 || shapeH <= 0) return;

    const pad = 0.08;
    final availW = size.width * (1 - 2 * pad);
    final availH = size.height * (1 - 2 * pad);
    final scale = (availW / shapeW < availH / shapeH)
        ? availW / shapeW
        : availH / shapeH;

    final scaledW = shapeW * scale;
    final scaledH = shapeH * scale;
    final offsetX = (size.width - scaledW) / 2 - minX * scale;
    final offsetY = (size.height - scaledH) / 2 - minY * scale;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final loop in puzzle.loops) {
      if (loop.length < 3) continue;
      final path = Path();
      final first = loop.first;
      path.moveTo(offsetX + first[0] * scale, offsetY + first[1] * scale);
      for (int i = 1; i < loop.length; i++) {
        final pt = loop[i];
        path.lineTo(offsetX + pt[0] * scale, offsetY + pt[1] * scale);
      }
      path.close();
      canvas.drawPath(path, paint);
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SilhouettePainter old) =>
      old.puzzle != puzzle || old.color != color;
}
