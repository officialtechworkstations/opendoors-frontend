// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';

/// A [CircularProgressIndicator] replacement that spins ~5× faster
/// (250 ms per revolution vs the default ~1 400 ms) to convey urgency and
/// encourage users to stay while content loads.
///
/// Drop-in: accepts the same named parameters as [CircularProgressIndicator].
class FastSpinner extends StatefulWidget {
  const FastSpinner({
    super.key,
    this.color,
    this.backgroundColor,
    this.valueColor,
    this.strokeWidth = 4.0,
    this.strokeCap,
    this.value,
    this.semanticsLabel,
    this.semanticsValue,
  });

  final Color? color;
  final Color? backgroundColor;

  /// Overrides [color] with an animated value — matches [CircularProgressIndicator.valueColor].
  final Animation<Color?>? valueColor;

  final double strokeWidth;
  final StrokeCap? strokeCap;

  /// When non-null the spinner shows a determinate arc (0..1).
  final double? value;

  final String? semanticsLabel;
  final String? semanticsValue;

  /// Mirrors the `.adaptive` constructor — on every platform this just
  /// returns a [FastSpinner], keeping the fast-spin behaviour consistent.
  static Widget adaptive({
    Key? key,
    Color? color,
    Color? backgroundColor,
    Animation<Color?>? valueColor,
    double strokeWidth = 4.0,
    StrokeCap? strokeCap,
    double? value,
    String? semanticsLabel,
    String? semanticsValue,
  }) {
    return FastSpinner(
      key: key,
      color: color,
      backgroundColor: backgroundColor,
      valueColor: valueColor,
      strokeWidth: strokeWidth,
      strokeCap: strokeCap,
      value: value,
      semanticsLabel: semanticsLabel,
      semanticsValue: semanticsValue,
    );
  }

  @override
  State<FastSpinner> createState() => _FastSpinnerState();
}

class _FastSpinnerState extends State<FastSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      // 250 ms per revolution ≈ 5× faster than the Flutter default (~1 400 ms)
      duration: const Duration(milliseconds: 250),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For determinate spinners just delegate directly — no rotation needed.
    if (widget.value != null) {
      return CircularProgressIndicator(
        value: widget.value,
        color: widget.color,
        backgroundColor: widget.backgroundColor,
        valueColor: widget.valueColor,
        strokeWidth: widget.strokeWidth,
        strokeCap: widget.strokeCap,
        semanticsLabel: widget.semanticsLabel,
        semanticsValue: widget.semanticsValue,
      );
    }

    return RotationTransition(
      turns: _ctrl,
      child: CircularProgressIndicator(
        // Use a small fixed arc so the rotation is clearly visible.
        value: 0.2,
        color: widget.color,
        backgroundColor: widget.backgroundColor,
        valueColor: widget.valueColor,
        strokeWidth: widget.strokeWidth,
        strokeCap: widget.strokeCap,
        semanticsLabel: widget.semanticsLabel,
        semanticsValue: widget.semanticsValue,
      ),
    );
  }
}
