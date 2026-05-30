import 'package:flutter/material.dart';

class WalletChart extends StatefulWidget {
  const WalletChart({super.key});

  @override
  State<WalletChart> createState() => _WalletChartState();
}

class _WalletChartState extends State<WalletChart> {
  double _scale = 1.0; // horizontal zoom
  double _lastScale = 1.0;

  double _verticalZoom = 1.0; // vertical zoom
  double _lastVerticalZoom = 1.0;

  double? _touchX; // for movable indicator

  final List<double> _values = [
    3.2, 3.1, 3.3, 3.6, 3.4, 3.8, 4.1, 4.0, 4.2, 4.5,
    4.7, 4.9, 5.0, 5.3, 5.1, 5.4, 5.7, 5.9, 6.1, 6.3,
    6.2, 6.5, 6.7, 6.9, 7.1, 7.3, 7.2, 7.5, 7.7, 7.9,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final visibleValues = _getVisibleValues();

        return GestureDetector(
          onScaleStart: (_) {
            _lastScale = _scale;
            _lastVerticalZoom = _verticalZoom;
          },
          onScaleUpdate: (details) {
            setState(() {
              _scale = (_lastScale * details.scale).clamp(1.0, 4.0);
              _verticalZoom = (_lastVerticalZoom * details.scale).clamp(1.0, 4.0);
              _touchX = details.localFocalPoint.dx;
            });
          },
          onTapDown: (d) {
            setState(() => _touchX = d.localPosition.dx);
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _WalletChartPainter(
              values: visibleValues,
              verticalZoom: _verticalZoom,
              scale: _scale,
              touchX: _touchX,
            ),
          ),
        );
      },
    );
  }

  List<double> _getVisibleValues() {
    final int total = _values.length;
    final double visibleRatio = 1 / _scale;
    final int visibleCount = (total * visibleRatio).clamp(10, total).toInt();
    return _values.sublist(total - visibleCount, total);
  }
}

class _WalletChartPainter extends CustomPainter {
  final List<double> values;
  final double verticalZoom;
  final double scale;
  final double? touchX;

  _WalletChartPainter({
    required this.values,
    required this.verticalZoom,
    required this.scale,
    this.touchX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    // --- MIN/MAX
    double minValue = values.reduce((a, b) => a < b ? a : b);
    double maxValue = values.reduce((a, b) => a > b ? a : b);

    final center = (minValue + maxValue) / 2;
    final baseRange = (maxValue - minValue).abs();
    final zoomedRange = baseRange / (verticalZoom == 0 ? 1 : verticalZoom);

    minValue = center - zoomedRange / 2;
    maxValue = center + zoomedRange / 2;
    final range = (maxValue - minValue == 0) ? 1 : maxValue - minValue;

    // --- PADDING
    const double topPadding = 16;
    const double bottomPadding = 18;
    final usableHeight = size.height - topPadding - bottomPadding;
    final chartBottom = size.height - bottomPadding;

    // --- POINTS
    final List<Offset> points = [];
    final double spacing = size.width / ((values.length - 1) * scale);

    for (int i = 0; i < values.length; i++) {
      final x = i * spacing;
      final normalized = ((values[i] - minValue) / range).clamp(0.0, 1.0);
      final y = chartBottom - (normalized * usableHeight);
      points.add(Offset(x, y));
    }

    // --- GRID (dashed like screenshot)
    final gridPaint = Paint()
      ..color = const Color(0xFF4EA2FF).withOpacity(0.35)
      ..strokeWidth = 1;

    const int gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final double y = topPadding + (usableHeight / gridLines) * i;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ✅ SHAPE FIX: Catmull-Rom smooth curve (image jaisi)
    final Path smoothPath = _catmullRomPath(points);

    // --- FILL (bottomPadding tak close, image jaisa)
    final fillPath = Path.from(smoothPath)
      ..lineTo(points.last.dx, chartBottom)
      ..lineTo(points.first.dx, chartBottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E88FF).withOpacity(0.85),
          const Color(0xFF1E88FF).withOpacity(0.10),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // --- TOP LINE
    final linePaint = Paint()
      ..color = const Color(0xFF58B0FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(smoothPath, linePaint);

    // --- INDICATOR POINT (closest to touchX)
    int focusIndex = (points.length / 2).round();
    if (touchX != null) {
      int closestIndex = 0;
      double minDistance = double.infinity;
      for (int i = 0; i < points.length; i++) {
        final d = (points[i].dx - touchX!).abs();
        if (d < minDistance) {
          minDistance = d;
          closestIndex = i;
        }
      }
      focusIndex = closestIndex;
    }

    final indicatorPoint = points[focusIndex];

    // --- VERTICAL LINE
    final verticalPaint = Paint()
      ..color = const Color(0xFF4EA2FF).withOpacity(0.65)
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(indicatorPoint.dx, topPadding),
      Offset(indicatorPoint.dx, chartBottom),
      verticalPaint,
    );

    // --- DOT (like screenshot)
    canvas.drawCircle(
      indicatorPoint,
      7,
      Paint()..color = const Color(0xFF0B3D91).withOpacity(0.35),
    );
    canvas.drawCircle(
      indicatorPoint,
      5.2,
      Paint()..color = const Color(0xFF1E88FF),
    );
    canvas.drawCircle(
      indicatorPoint,
      3.2,
      Paint()..color = Colors.white,
    );

    // --- VALUE
    final double displayValue = values[focusIndex] * 1000000;
    final valueText = _formatMoney(displayValue);

    // --- BUBBLE
    final tp = TextPainter(
      text: TextSpan(
        text: valueText,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bubblePaddingX = 10.0;
    final bubblePaddingY = 6.0;
    final bubbleW = tp.width + bubblePaddingX * 2;
    final bubbleH = tp.height + bubblePaddingY * 2;

    final bubbleX = (indicatorPoint.dx - bubbleW / 2)
        .clamp(6.0, size.width - bubbleW - 6.0);
    final bubbleY = (topPadding - bubbleH - 4).clamp(2.0, size.height - bubbleH);

    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bubbleX, bubbleY, bubbleW, bubbleH),
      const Radius.circular(16),
    );

    canvas.drawRRect(bubbleRect, Paint()..color = Colors.white);
    tp.paint(canvas, Offset(bubbleRect.left + bubblePaddingX,
        bubbleRect.top + bubblePaddingY));
  }

  // ✅ Catmull-Rom path generator (smooth like your image)
  Path _catmullRomPath(List<Offset> pts) {
    if (pts.length < 2) return Path();

    final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);

    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = (i + 2 < pts.length) ? pts[i + 2] : p2;

      // Catmull-Rom to Bezier conversion
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 7.0;
    const dashSpace = 5.0;
    double x = start.dx;
    while (x < end.dx) {
      canvas.drawLine(
          Offset(x, start.dy), Offset(x + dashWidth, start.dy), paint);
      x += dashWidth + dashSpace;
    }
  }

  String _formatMoney(double value) {
    final int v = value.round();
    final s = v.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final left = s.length - i;
      buffer.write(s[i]);
      if (left > 1 && left % 3 == 1) buffer.write(',');
    }
    return '\$${buffer.toString()}';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
