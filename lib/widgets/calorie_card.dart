import 'package:flutter/material.dart';
import 'dart:math' as math;

class CalorieCard extends StatefulWidget {
  final int consumed;
  final int target;
  final int protein;
  final int carbs;
  final int fat;

  const CalorieCard({
    super.key,
    required this.consumed,
    required this.target,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  State<CalorieCard> createState() => _CalorieCardState();
}

class _CalorieCardState extends State<CalorieCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _progressAnim = Tween<double>(
      begin: 0,
      end: (widget.consumed / widget.target).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.target - widget.consumed;
    final burnedCal = 312;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF0D2137)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B2A).withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative glow
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C853).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Row(
                  children: [
                    // Circular progress
                    AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (_, __) => SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomPaint(
                          painter: _RingPainter(progress: _progressAnim.value),
                          child: Center(
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(_progressAnim.value * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const Text(
                                    'consumed',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Stats
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Calories',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${widget.consumed}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' /${widget.target}',
                                    style: const TextStyle(
                                      color: Colors.white30,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            _InfoRow(
                              icon: Icons.arrow_downward_rounded,
                              color: const Color(0xFF00C853),
                              text: '$remaining kcal left',
                            ),
                            const SizedBox(height: 4),
                            _InfoRow(
                              icon: Icons.local_fire_department_rounded,
                              color: const Color(0xFFFF7043),
                              text: '$burnedCal kcal burned',
                            ),
                            const SizedBox(height: 4),
                            _InfoRow(
                              icon: Icons.restaurant_rounded,
                              color: const Color(0xFFFFB300),
                              text: '3 meals logged',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Macro bars
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _MacroLabel(emoji: '💪', label: 'Protein', value: '${widget.protein}g', color: const Color(0xFF64B5F6)),
                            _MacroLabel(emoji: '🌾', label: 'Carbs', value: '${widget.carbs}g', color: const Color(0xFFFFB74D)),
                            _MacroLabel(emoji: '🧈', label: 'Fat', value: '${widget.fat}g', color: const Color(0xFFEF9A9A)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: _progressAnim,
                          builder: (_, __) => _MacroProgressBar(
                            proteinPct: (widget.protein / 150 * _progressAnim.value).clamp(0.0, 1.0),
                            carbsPct: (widget.carbs / 250 * _progressAnim.value).clamp(0.0, 1.0),
                            fatPct: (widget.fat / 70 * _progressAnim.value).clamp(0.0, 1.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _MacroLabel extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _MacroLabel({required this.emoji, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

class _MacroProgressBar extends StatelessWidget {
  final double proteinPct;
  final double carbsPct;
  final double fatPct;
  const _MacroProgressBar({required this.proteinPct, required this.carbsPct, required this.fatPct});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            Expanded(
              flex: (proteinPct * 100).toInt().clamp(1, 100),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF64B5F6)]),
                ),
              ),
            ),
            Expanded(
              flex: (carbsPct * 100).toInt().clamp(1, 100),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFFB74D)]),
                ),
              ),
            ),
            Expanded(
              flex: (fatPct * 100).toInt().clamp(1, 100),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFC62828), Color(0xFFEF9A9A)]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ring Painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const stroke = 9.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke,
    );

    // Glow shadow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = const Color(0xFF00C853).withValues(alpha: 0.3)
        ..strokeWidth = stroke + 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: const [Color(0xFF69F0AE), Color(0xFF00C853), Color(0xFF00897B)],
          startAngle: 0,
          endAngle: math.pi * 2,
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // End dot
    if (progress > 0.02) {
      final angle = -math.pi / 2 + 2 * math.pi * progress;
      final dotX = center.dx + radius * math.cos(angle);
      final dotY = center.dy + radius * math.sin(angle);
      canvas.drawCircle(
        Offset(dotX, dotY),
        5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
