import 'dart:math';
import 'dart:ui' show Canvas, Paint, Offset, Path, Size;

import 'package:flutter/material.dart';

class EdgeRenderData {
  final String id;
  final Offset source;
  final Offset target;
  final Color color;

  const EdgeRenderData({
    required this.id,
    required this.source,
    required this.target,
    this.color = const Color(0xFF3B82F6),
  });
}

class CanvasEdgePainter extends CustomPainter {
  final List<EdgeRenderData> edges;

  CanvasEdgePainter({required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      _drawBezier(canvas, edge.source, edge.target, edge.color);
    }
  }

  void _drawBezier(Canvas canvas, Offset source, Offset target, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dy = (target.dy - source.dy).abs() * 0.5;
    final cp1 = Offset(source.dx, source.dy + dy);
    final cp2 = Offset(target.dx, target.dy - dy);

    final path = Path()
      ..moveTo(source.dx, source.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, target.dx, target.dy);
    canvas.drawPath(path, paint);

    _drawArrowhead(canvas, target, cp2, color);
  }

  void _drawArrowhead(Canvas canvas, Offset tip, Offset cp, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final angle = atan2(tip.dy - cp.dy, tip.dx - cp.dx);
    const arrowSize = 8.0;
    final p1 = Offset(
      tip.dx - arrowSize * cos(angle - pi / 6),
      tip.dy - arrowSize * sin(angle - pi / 6),
    );
    final p2 = Offset(
      tip.dx - arrowSize * cos(angle + pi / 6),
      tip.dy - arrowSize * sin(angle + pi / 6),
    );

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CanvasEdgePainter oldDelegate) => true;
}
