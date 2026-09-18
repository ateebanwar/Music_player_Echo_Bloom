import 'package:flutter/material.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';

/// Versatile neumorphic surface container with optional tap interactions,
/// custom shape, and theme-adaptive shadows.
class NeumorphicContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final Color? color;
  final VoidCallback? onTap;
  final double elevation;
  final bool isPressed;
  final bool? isDark;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.color,
    this.onTap,
    this.elevation = 1.0,
    this.isPressed = false,
    this.isDark,
  });

  @override
  State<NeumorphicContainer> createState() => _NeumorphicContainerState();
}

class _NeumorphicContainerState extends State<NeumorphicContainer> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final isDown = _isDown || widget.isPressed;
    final scale = isDown ? 0.96 : 1.0;
    final currentElevation = isDown ? (widget.elevation * 0.4) : widget.elevation;

    final baseColor = widget.color ?? (isDark ? AppColors.darkSurfaceElevated : AppColors.surface);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap != null ? (_) => setState(() => _isDown = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isDown = false) : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isDown = false) : null,
        onTap: widget.onTap,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: baseColor,
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle ? null : widget.borderRadius,
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.05), width: 0.8)
                : null,
            boxShadow: [
              // Top-left soft highlight
              BoxShadow(
                color: isDark ? AppColors.darkShadowLight : AppColors.shadowLight,
                offset: Offset(-4 * currentElevation, -4 * currentElevation),
                blurRadius: 10 * currentElevation,
                spreadRadius: 0,
              ),
              // Bottom-right soft depth
              BoxShadow(
                color: isDark ? AppColors.darkShadowDark : AppColors.shadowDark,
                offset: Offset(4 * currentElevation, 7 * currentElevation),
                blurRadius: 14 * currentElevation,
                spreadRadius: 0,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
