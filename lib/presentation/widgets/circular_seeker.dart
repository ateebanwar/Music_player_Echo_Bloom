import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';

/// Interactive circular progress seeker and Play/Pause center container.
/// Supports both normal tap for Play/Pause and press+hold+rotate for circular seeking.
class CircularSeeker extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Widget centerChild;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onPlayPauseTap;
  final double size;
  final double strokeWidth;

  /// The exact diameter of the central button, preserved without scaling or redesign.
  static const double buttonDiameter = 77.44;

  const CircularSeeker({
    super.key,
    required this.position,
    required this.duration,
    required this.centerChild,
    this.onSeek,
    this.onPlayPauseTap,
    this.size = 108.44,
    this.strokeWidth = 15.5,
  });

  @override
  State<CircularSeeker> createState() => _CircularSeekerState();
}

class _CircularSeekerState extends State<CircularSeeker> {
  double? _dragProgress;
  double _accumulatedSeekMs = 0.0;
  double? _lastAngle;
  bool _isRotating = false;

  double get _currentProgress {
    if (_dragProgress != null) return _dragProgress!;
    if (widget.duration.inMilliseconds <= 0) return 0.0;
    return (widget.position.inMilliseconds / widget.duration.inMilliseconds).clamp(0.0, 1.0);
  }

  void _handlePanStart(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final touchVector = localPosition - center;

    _lastAngle = math.atan2(touchVector.dy, touchVector.dx);
    _accumulatedSeekMs = widget.position.inMilliseconds.toDouble();
    _isRotating = false;
  }

  void _handlePanUpdate(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final touchVector = localPosition - center;
    final distance = touchVector.distance;

    // Prevent singularity at exact center point
    if (distance < 3.0) return;

    final currentAngle = math.atan2(touchVector.dy, touchVector.dx);

    if (_lastAngle != null) {
      var deltaAngle = currentAngle - _lastAngle!;

      // Normalize angular delta across the -pi / +pi boundary
      while (deltaAngle > math.pi) {
        deltaAngle -= 2 * math.pi;
      }
      while (deltaAngle < -math.pi) {
        deltaAngle += 2 * math.pi;
      }

      // If rotation threshold met, enter rotational seeking mode
      if (deltaAngle.abs() > 0.015 || _isRotating) {
        _isRotating = true;
        final totalDurationMs = widget.duration.inMilliseconds > 0
            ? widget.duration.inMilliseconds.toDouble()
            : 60000.0;

        // 1 full revolution (2*pi) maps smoothly across track duration
        final seekDeltaMs = (deltaAngle / (2 * math.pi)) * totalDurationMs;
        _accumulatedSeekMs = (_accumulatedSeekMs + seekDeltaMs).clamp(0.0, totalDurationMs);

        final progress = (_accumulatedSeekMs / totalDurationMs).clamp(0.0, 1.0);
        setState(() {
          _dragProgress = progress;
        });
      }
    }

    _lastAngle = currentAngle;
  }

  void _handlePanEnd() {
    if (_isRotating) {
      if (widget.onSeek != null && widget.duration.inMilliseconds > 0) {
        final finalSeekMs = _accumulatedSeekMs.clamp(0.0, widget.duration.inMilliseconds.toDouble()).round();
        widget.onSeek!(Duration(milliseconds: finalSeekMs));
      }
    } else {
      // Normal short tap without rotation triggers Play/Pause
      widget.onPlayPauseTap?.call();
    }

    setState(() {
      _dragProgress = null;
      _lastAngle = null;
      _isRotating = false;
    });
  }

  void _handlePanCancel() {
    setState(() {
      _dragProgress = null;
      _lastAngle = null;
      _isRotating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _currentProgress;
    final effectiveSize = math.max(widget.size, CircularSeeker.buttonDiameter + (widget.strokeWidth * 2));

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) => _handlePanStart(details.localPosition, Size(effectiveSize, effectiveSize)),
        onPanUpdate: (details) => _handlePanUpdate(details.localPosition, Size(effectiveSize, effectiveSize)),
        onPanEnd: (_) => _handlePanEnd(),
        onPanCancel: () => _handlePanCancel(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular Ring Painter displaying live or drag progress directly touching button boundary
            Positioned.fill(
              child: CustomPaint(
                painter: _CircularSeekerPainter(
                  progress: progress,
                  strokeWidth: widget.strokeWidth,
                  buttonDiameter: CircularSeeker.buttonDiameter,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),

            // Central Play/Pause Button Area - exactly preserved at its current size
            IgnorePointer(
              ignoring: true,
              child: SizedBox(
                width: CircularSeeker.buttonDiameter,
                height: CircularSeeker.buttonDiameter,
                child: widget.centerChild,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularSeekerPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final double buttonDiameter;
  final bool isDark;

  _CircularSeekerPainter({
    required this.progress,
    required this.strokeWidth,
    required this.buttonDiameter,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Radius chosen so the inner edge of the stroke directly touches the outer edge of the button
    final radius = (buttonDiameter / 2) + (strokeWidth / 2);

    // 1. Draw Inactive Background Ring with flat edges
    final bgPaint = Paint()
      ..color = isDark ? AppColors.darkSeekerTrack : AppColors.seekerTrackWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Draw Active Progress Arc with Echo Bloom Teal-to-Emerald Sweep Gradient and clean flat edges
    if (progress > 0.001) {
      const sweepGradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: (3 * math.pi) / 2,
        colors: [
          Color(0xFF176B5A), // Deep botanical teal
          Color(0xFF65B995), // Primary Echo Green
          Color(0xFF75C9A3), // Primary accent
          Color(0xFFA6DEC0), // Secondary mint
          Color(0xFF176B5A), // Seamless loop
        ],
        stops: [0.0, 0.35, 0.7, 0.92, 1.0],
        transform: GradientRotation(-math.pi / 2),
      );

      final rect = Rect.fromCircle(center: center, radius: radius);
      final activePaint = Paint()
        ..shader = sweepGradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      final sweepAngle = (2 * math.pi * progress).clamp(0.0, 2 * math.pi);
      canvas.drawArc(
        rect,
        -math.pi / 2, // Start at 12 o'clock
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularSeekerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.buttonDiameter != buttonDiameter ||
        oldDelegate.isDark != isDark;
  }
}
