import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/utils/score_calculator.dart';

class ScoreRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final int score;
  final Animation<double>? repaint;

  ScoreRingPainter({
    required this.progress,
    required this.score,
    this.repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;

    // Outer glow
    final glowPaint = Paint()
      ..color = ScoreCalculator.primaryColor(score).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      glowPaint,
    );

    // Track ring
    final trackPaint = Paint()
      ..color = AppColors.white15
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc with gradient
    if (progress > 0) {
      final gradient = ScoreCalculator.gradient(score);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: gradient.colors,
          startAngle: -pi / 2,
          endAngle: -pi / 2 + 2 * pi * progress,
          transform: const GradientRotation(-pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }

    // Inner glow circle
    final innerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          ScoreCalculator.primaryColor(score).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 10));

    canvas.drawCircle(center, radius - 10, innerGlowPaint);
  }

  @override
  bool shouldRepaint(ScoreRingPainter old) =>
      old.progress != progress || old.score != score;
}

class AnimatedScoreRing extends StatefulWidget {
  final int score;
  final double size;
  final bool showLabel;
  final bool placeholder;

  const AnimatedScoreRing({
    super.key,
    required this.score,
    this.size = 200,
    this.showLabel = true,
    this.placeholder = false,
  });

  @override
  State<AnimatedScoreRing> createState() => _AnimatedScoreRingState();
}

class _AnimatedScoreRingState extends State<AnimatedScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  late Animation<int> _counter;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _counter = IntTween(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedScoreRing old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      final fromScore = _counter.value;
      _progress = Tween<double>(
        begin: old.score / 100,
        end: widget.score / 100,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _counter = IntTween(begin: fromScore, end: widget.score)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: ScoreRingPainter(
                  progress: widget.placeholder ? 0 : _progress.value,
                  score: widget.score,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.placeholder)
                    Text(
                      '—',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: widget.size * 0.32,
                        color: AppColors.white50,
                      ),
                    )
                  else
                    Text(
                      '${_counter.value}',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: widget.size * 0.24,
                        foreground: Paint()
                          ..shader = ScoreCalculator.gradient(widget.score)
                              .createShader(
                            Rect.fromLTWH(
                                0, 0, widget.size * 0.5, widget.size * 0.3),
                          ),
                      ),
                    ),
                  if (widget.showLabel)
                    Text(
                      widget.placeholder
                          ? 'NOT SCANNED'
                          : ScoreCalculator.label(widget.score),
                      style: AppTextStyles.scoreLabel.copyWith(
                        color: widget.placeholder
                            ? AppColors.white50
                            : ScoreCalculator.primaryColor(widget.score),
                        fontSize: widget.size * 0.07,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
