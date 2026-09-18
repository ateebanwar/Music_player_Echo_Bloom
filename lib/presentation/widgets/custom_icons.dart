import 'package:flutter/material.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';

/// Crisp custom vector icons matching the reference design.
abstract final class CustomIcons {
  /// Header 3-line Menu Icon (top long, middle medium, bottom short)
  static Widget menu({double size = 22.0, Color color = AppColors.iconNavy}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MenuIconPainter(color: color),
      ),
    );
  }

  /// Header 3-dot Vertical Menu
  static Widget moreVertical({double size = 22.0, Color color = AppColors.iconNavy}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoreVerticalPainter(color: color),
      ),
    );
  }

  /// Downward Expand Chevron
  static Widget expandChevron({double size = 15.0, Color color = AppColors.iconNavy}) {
    return SizedBox(
      width: size,
      height: size * 0.55,
      child: CustomPaint(
        painter: _ExpandChevronPainter(color: color),
      ),
    );
  }

  /// Previous Track Icon (|◀◀)
  static Widget skipPrevious({double size = 20.0, Color color = AppColors.iconNavy}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SkipPreviousPainter(color: color),
      ),
    );
  }

  /// Next Track Icon (▶▶|)
  static Widget skipNext({double size = 20.0, Color color = AppColors.iconNavy}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SkipNextPainter(color: color),
      ),
    );
  }

  /// Shuffle Icon (Crossed arrows)
  static Widget shuffle({double size = 18.0, Color color = AppColors.iconNavy}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShufflePainter(color: color),
      ),
    );
  }

  /// Repeat / Loop Icon with optional Repeat One indicator
  static Widget repeat({
    double size = 18.0,
    Color color = AppColors.iconNavy,
    bool isRepeatOne = false,
  }) {
    if (isRepeatOne) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _RepeatPainter(color: color),
            ),
            Center(
              child: Text(
                '1',
                style: TextStyle(
                  color: color,
                  fontSize: size * 0.44,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RepeatPainter(color: color),
      ),
    );
  }

  /// Pause Icon (Two vertical rounded bars)
  static Widget pause({double width = 17.0, double height = 19.0, Color color = AppColors.iconNavy}) {
    return SizedBox(
      width: width,
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 4.8,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            width: 4.8,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  /// Play Icon (Crisp rounded triangle)
  static Widget play({double size = 20.0, Color color = AppColors.iconNavy}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PlayTrianglePainter(color: color),
      ),
    );
  }

  /// Filled or Outline Heart Icon
  static Widget heart({
    double size = 22.0,
    required Color color,
    bool isFilled = true,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HeartPainter(color: color, isFilled: isFilled),
      ),
    );
  }

  /// Nav Bar: Beamed Music Note
  static Widget musicNote({double size = 22.0, Color color = AppColors.primaryPurple}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MusicNotePainter(color: color),
      ),
    );
  }

  /// Nav Bar: Concentric Disc (All Songs)
  static Widget disc({double size = 22.0, Color color = AppColors.iconNavy}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DiscPainter(color: color),
      ),
    );
  }

  /// Nav Bar: 4-Square Grid (Playlists)
  static Widget playlistGrid({double size = 20.0, Color color = AppColors.iconNavy}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PlaylistGridPainter(color: color),
      ),
    );
  }

  /// Nav Bar: Profile / User Icon
  static Widget profile({double size = 22.0, Color color = AppColors.iconNavy}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProfilePainter(color: color),
      ),
    );
  }
}

// --- Custom Painters for Exact Vector Icons ---

class _MenuIconPainter extends CustomPainter {
  final Color color;
  _MenuIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final ySpacing = size.height / 3.0;
    canvas.drawLine(Offset(0, ySpacing * 0.5), Offset(size.width, ySpacing * 0.5), paint);
    canvas.drawLine(Offset(0, ySpacing * 1.5), Offset(size.width * 0.72, ySpacing * 1.5), paint);
    canvas.drawLine(Offset(0, ySpacing * 2.5), Offset(size.width * 0.48, ySpacing * 2.5), paint);
  }

  @override
  bool shouldRepaint(covariant _MenuIconPainter oldDelegate) => oldDelegate.color != color;
}

class _MoreVerticalPainter extends CustomPainter {
  final Color color;
  _MoreVerticalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final radius = size.width * 0.095;
    final centerX = size.width / 2;
    canvas.drawCircle(Offset(centerX, size.height * 0.22), radius, paint);
    canvas.drawCircle(Offset(centerX, size.height * 0.5), radius, paint);
    canvas.drawCircle(Offset(centerX, size.height * 0.78), radius, paint);
  }

  @override
  bool shouldRepaint(covariant _MoreVerticalPainter oldDelegate) => oldDelegate.color != color;
}

class _ExpandChevronPainter extends CustomPainter {
  final Color color;
  _ExpandChevronPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.2)
      ..lineTo(size.width * 0.5, size.height * 0.8)
      ..lineTo(size.width * 0.85, size.height * 0.2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ExpandChevronPainter oldDelegate) => oldDelegate.color != color;
}

class _SkipPreviousPainter extends CustomPainter {
  final Color color;
  _SkipPreviousPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Left vertical bar
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.18, size.width * 0.18, size.height * 0.64),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(barRect, paint);

    // Triangle facing left
    final path = Path()
      ..moveTo(size.width * 0.95, size.height * 0.18)
      ..lineTo(size.width * 0.26, size.height * 0.5)
      ..lineTo(size.width * 0.95, size.height * 0.82)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SkipPreviousPainter oldDelegate) => oldDelegate.color != color;
}

class _SkipNextPainter extends CustomPainter {
  final Color color;
  _SkipNextPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Right vertical bar
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.82, size.height * 0.18, size.width * 0.18, size.height * 0.64),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(barRect, paint);

    // Triangle facing right
    final path = Path()
      ..moveTo(size.width * 0.05, size.height * 0.18)
      ..lineTo(size.width * 0.74, size.height * 0.5)
      ..lineTo(size.width * 0.05, size.height * 0.82)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SkipNextPainter oldDelegate) => oldDelegate.color != color;
}

class _ShufflePainter extends CustomPainter {
  final Color color;
  _ShufflePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Top-to-bottom crossing curve
    final path1 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.32)
      ..cubicTo(size.width * 0.42, size.height * 0.32, size.width * 0.58, size.height * 0.68, size.width * 0.84, size.height * 0.68);
    canvas.drawPath(path1, strokePaint);

    // Bottom-to-top crossing curve
    final path2 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.68)
      ..cubicTo(size.width * 0.42, size.height * 0.68, size.width * 0.58, size.height * 0.32, size.width * 0.84, size.height * 0.32);
    canvas.drawPath(path2, strokePaint);

    // Top arrow
    final arrow1 = Path()
      ..moveTo(size.width * 0.72, size.height * 0.18)
      ..lineTo(size.width * 0.94, size.height * 0.32)
      ..lineTo(size.width * 0.72, size.height * 0.46)
      ..close();
    canvas.drawPath(arrow1, fillPaint);

    // Bottom arrow
    final arrow2 = Path()
      ..moveTo(size.width * 0.72, size.height * 0.54)
      ..lineTo(size.width * 0.94, size.height * 0.68)
      ..lineTo(size.width * 0.72, size.height * 0.82)
      ..close();
    canvas.drawPath(arrow2, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _ShufflePainter oldDelegate) => oldDelegate.color != color;
}

class _RepeatPainter extends CustomPainter {
  final Color color;
  _RepeatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Rounded rectangle loop path
    final rect = Rect.fromLTWH(size.width * 0.14, size.height * 0.22, size.width * 0.72, size.height * 0.56);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    canvas.drawRRect(rrect, strokePaint);

    // Top right clockwise arrow
    final arrow1 = Path()
      ..moveTo(size.width * 0.68, size.height * 0.1)
      ..lineTo(size.width * 0.90, size.height * 0.22)
      ..lineTo(size.width * 0.68, size.height * 0.34)
      ..close();
    canvas.drawPath(arrow1, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _RepeatPainter oldDelegate) => oldDelegate.color != color;
}

class _PlayTrianglePainter extends CustomPainter {
  final Color color;
  _PlayTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.16)
      ..lineTo(size.width * 0.86, size.height * 0.5)
      ..lineTo(size.width * 0.28, size.height * 0.84)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PlayTrianglePainter oldDelegate) => oldDelegate.color != color;
}

class _HeartPainter extends CustomPainter {
  final Color color;
  final bool isFilled;
  _HeartPainter({required this.color, required this.isFilled});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final width = size.width;
    final height = size.height;

    final path = Path();
    path.moveTo(width / 2, height * 0.84);
    path.cubicTo(width * 0.08, height * 0.56, 0, height * 0.34, 0, height * 0.22);
    path.cubicTo(0, height * 0.04, width * 0.22, 0, width * 0.38, 0);
    path.cubicTo(width * 0.45, 0, width * 0.48, height * 0.07, width / 2, height * 0.17);
    path.cubicTo(width * 0.52, height * 0.07, width * 0.55, 0, width * 0.62, 0);
    path.cubicTo(width * 0.78, 0, width, height * 0.04, width, height * 0.22);
    path.cubicTo(width, height * 0.34, width * 0.92, height * 0.56, width / 2, height * 0.84);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isFilled != isFilled;
}

class _MusicNotePainter extends CustomPainter {
  final Color color;
  _MusicNotePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Stem 1
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.72), Offset(size.width * 0.3, size.height * 0.18), strokePaint);
    // Stem 2
    canvas.drawLine(Offset(size.width * 0.76, size.height * 0.62), Offset(size.width * 0.76, size.height * 0.10), strokePaint);
    // Top Beam
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.18), Offset(size.width * 0.76, size.height * 0.10), strokePaint..strokeWidth = 3.2);

    // Note heads
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.22, size.height * 0.74), width: size.width * 0.28, height: size.height * 0.22),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.68, size.height * 0.64), width: size.width * 0.28, height: size.height * 0.22),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MusicNotePainter oldDelegate) => oldDelegate.color != color;
}

class _DiscPainter extends CustomPainter {
  final Color color;
  _DiscPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    // Outer circle
    canvas.drawCircle(center, size.width * 0.42, strokePaint);
    // Center filled circle dot
    canvas.drawCircle(center, size.width * 0.14, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _DiscPainter oldDelegate) => oldDelegate.color != color;
}

class _PlaylistGridPainter extends CustomPainter {
  final Color color;
  _PlaylistGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final boxSize = size.width * 0.34;
    const r = Radius.circular(3.0);

    // Top-left
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.1, size.height * 0.1, boxSize, boxSize), r), strokePaint);
    // Top-right
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.56, size.height * 0.1, boxSize, boxSize), r), strokePaint);
    // Bottom-left
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.1, size.height * 0.56, boxSize, boxSize), r), strokePaint);
    // Bottom-right
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.56, size.height * 0.56, boxSize, boxSize), r), strokePaint);
  }

  @override
  bool shouldRepaint(covariant _PlaylistGridPainter oldDelegate) => oldDelegate.color != color;
}

class _ProfilePainter extends CustomPainter {
  final Color color;
  _ProfilePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height * 0.32);
    // Head circle
    canvas.drawCircle(center, size.width * 0.22, strokePaint);

    // Shoulders arch
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.88)
      ..cubicTo(size.width * 0.16, size.height * 0.65, size.width * 0.84, size.height * 0.65, size.width * 0.88, size.height * 0.88);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter oldDelegate) => oldDelegate.color != color;
}
