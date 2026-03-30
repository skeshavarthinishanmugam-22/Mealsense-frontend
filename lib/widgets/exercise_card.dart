import 'package:flutter/material.dart';
import '../screens/activity/activity_screen.dart';

class ExerciseCard extends StatefulWidget {
  final String emoji;
  final String name;
  final String duration;
  final int calories;
  final List<Color> gradientColors;
  final String difficulty;

  const ExerciseCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.duration,
    required this.calories,
    required this.gradientColors,
    required this.difficulty,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) => _controller.forward(),
      onTapCancel: () => _controller.forward(),
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, _) => const ActivityScreen(),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.last.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji in glass container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(widget.emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const Spacer(),
              Text(
                widget.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.duration,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.calories} kcal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.difficulty,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Exercise Data ─────────────────────────────────────────────────────────────

const List<ExerciseCard> exerciseCards = [
  ExerciseCard(
    emoji: '🏃',
    name: 'Running',
    duration: '30 min',
    calories: 280,
    gradientColors: [Color(0xFFE53935), Color(0xFFEF9A9A)],
    difficulty: 'Medium',
  ),
  ExerciseCard(
    emoji: '🚴',
    name: 'Cycling',
    duration: '45 min',
    calories: 350,
    gradientColors: [Color(0xFF1E88E5), Color(0xFF90CAF9)],
    difficulty: 'Medium',
  ),
  ExerciseCard(
    emoji: '🧘',
    name: 'Yoga',
    duration: '20 min',
    calories: 120,
    gradientColors: [Color(0xFF8E24AA), Color(0xFFCE93D8)],
    difficulty: 'Easy',
  ),
  ExerciseCard(
    emoji: '🏊',
    name: 'Swimming',
    duration: '30 min',
    calories: 300,
    gradientColors: [Color(0xFF00ACC1), Color(0xFF80DEEA)],
    difficulty: 'Hard',
  ),
  ExerciseCard(
    emoji: '🏋️',
    name: 'Weights',
    duration: '40 min',
    calories: 220,
    gradientColors: [Color(0xFFFF7043), Color(0xFFFFCCBC)],
    difficulty: 'Hard',
  ),
];
