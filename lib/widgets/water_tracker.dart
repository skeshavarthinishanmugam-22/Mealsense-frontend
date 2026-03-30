import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaterTracker extends StatefulWidget {
  final int targetMl;
  const WaterTracker({super.key, required this.targetMl});

  @override
  State<WaterTracker> createState() => _WaterTrackerState();
}

class _WaterTrackerState extends State<WaterTracker>
    with TickerProviderStateMixin {
  int _glasses = 3;
  static const _mlPerGlass = 250;

  late AnimationController _progressController;
  late AnimationController _waveController;
  late Animation<double> _progressAnim;
  double _prevProgress = 0;

  @override
  void initState() {
    super.initState();
    _prevProgress = (_glasses * _mlPerGlass / widget.targetMl).clamp(0.0, 1.0);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnim = Tween<double>(begin: 0, end: _prevProgress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _update(int delta) {
    final next = (_glasses + delta).clamp(0, 20);
    if (next == _glasses) return;
    final newProg = (next * _mlPerGlass / widget.targetMl).clamp(0.0, 1.0);
    setState(() {
      _glasses = next;
      _progressAnim = Tween<double>(begin: _prevProgress, end: newProg).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
      );
      _prevProgress = newProg;
      _progressController
        ..reset()
        ..forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final consumed = _glasses * _mlPerGlass;
    final pct = ((consumed / widget.targetMl) * 100).clamp(0, 100).toInt();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative bubble
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    // Wave circle
                    AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (_, __) => SizedBox(
                        width: 72,
                        height: 72,
                        child: AnimatedBuilder(
                          animation: _waveController,
                          builder: (_, __) => CustomPaint(
                            painter: _WavePainter(
                              progress: _progressAnim.value,
                              wavePhase: _waveController.value,
                            ),
                            child: Center(
                              child: Text(
                                '$pct%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Water Intake',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$consumed ml of ${widget.targetMl} ml',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          AnimatedBuilder(
                            animation: _progressAnim,
                            builder: (_, __) => ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _progressAnim.value,
                                minHeight: 6,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Controls
                    Column(
                      children: [
                        _WaterBtn(icon: Icons.add, onTap: () => _update(1)),
                        const SizedBox(height: 6),
                        Text(
                          '$_glasses',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _WaterBtn(icon: Icons.remove, onTap: () => _update(-1)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Glass indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(10, (i) {
                    final filled = i < _glasses;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: filled ? 20 : 16,
                      height: filled ? 20 : 16,
                      decoration: BoxDecoration(
                        color: filled ? Colors.white : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: filled
                            ? [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 6)]
                            : null,
                      ),
                      child: Center(
                        child: Text('💧', style: TextStyle(fontSize: filled ? 10 : 8)),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _WaterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─── Wave Painter ──────────────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  _WavePainter({required this.progress, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(36)));

    // Background
    canvas.drawRect(
      rect,
      Paint()..color = Colors.white.withOpacity(0.15),
    );

    // Wave fill
    final fillHeight = size.height * (1 - progress);
    final path = Path();
    path.moveTo(0, fillHeight);

    for (double x = 0; x <= size.width; x++) {
      final y = fillHeight +
          math.sin((x / size.width * 2 * math.pi) + (wavePhase * 2 * math.pi)) * 4;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.6),
            Colors.white.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(36)),
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.wavePhase != wavePhase;
}
