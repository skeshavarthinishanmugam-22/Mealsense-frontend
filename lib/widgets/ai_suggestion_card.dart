import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AiSuggestionCard extends StatefulWidget {
  const AiSuggestionCard({super.key});

  @override
  State<AiSuggestionCard> createState() => _AiSuggestionCardState();
}

class _AiSuggestionCardState extends State<AiSuggestionCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  int _tipIndex = 0;
  bool _isAnimating = false;

  // ── Dynamic tips: keyed by goal + activityLevel ──────────────────────────────
  static const Map<String, List<Map<String, String>>> _tips = {
    'Weight Loss_Sedentary': [
      {'emoji': '🚶', 'title': 'Start moving today', 'body': 'Even a 15-min walk burns ~80 kcal. Start small and build consistency.'},
      {'emoji': '💧', 'title': 'Hydrate before meals', 'body': 'Drinking 500ml water before eating reduces calorie intake by ~13%.'},
      {'emoji': '🥗', 'title': 'Eat more fiber', 'body': 'High-fiber foods keep you full longer. Add veggies to every meal.'},
    ],
    'Weight Loss_Moderate': [
      {'emoji': '🔥', 'title': 'Calorie deficit on track', 'body': 'You\'re 560 kcal below target. Great job! Keep protein high to preserve muscle.'},
      {'emoji': '💧', 'title': 'Drink more water', 'body': 'You\'re 500ml behind your daily goal. Hydration boosts fat metabolism!'},
      {'emoji': '🏃', 'title': 'Add cardio today', 'body': 'A 30-min run burns ~280 kcal. Perfect to hit your weekly deficit goal.'},
    ],
    'Weight Loss_Active': [
      {'emoji': '🥩', 'title': 'Protect your muscle', 'body': 'High activity + deficit = muscle loss risk. Eat 1.6g protein per kg bodyweight.'},
      {'emoji': '😴', 'title': 'Recovery is key', 'body': 'Sleep 7-9 hours. Poor sleep increases hunger hormones by 24%.'},
      {'emoji': '⚡', 'title': 'Refeed day needed', 'body': 'After 5 days of deficit, a maintenance day resets leptin and boosts metabolism.'},
    ],
    'Muscle Gain_Sedentary': [
      {'emoji': '🏋️', 'title': 'Start resistance training', 'body': 'Muscle gain requires progressive overload. Start with 3 days/week lifting.'},
      {'emoji': '🍗', 'title': 'Hit your protein goal', 'body': 'You need ~126g protein today. Add chicken or paneer.'},
      {'emoji': '📈', 'title': 'Eat in a surplus', 'body': 'You need 300 kcal above maintenance to build muscle effectively.'},
    ],
    'Muscle Gain_Moderate': [
      {'emoji': '💪', 'title': 'Increase protein intake', 'body': 'You need 30g more protein today. Add a chicken breast or whey shake.'},
      {'emoji': '🍌', 'title': 'Pre-workout fuel', 'body': 'Eat a banana + peanut butter 30 min before training for optimal energy.'},
      {'emoji': '😴', 'title': 'Muscles grow at night', 'body': 'Aim for 8 hours sleep. Growth hormone peaks during deep sleep.'},
    ],
    'Muscle Gain_Active': [
      {'emoji': '🔄', 'title': 'Periodize your training', 'body': 'Alternate heavy and light weeks to avoid plateau and overtraining.'},
      {'emoji': '🥛', 'title': 'Post-workout window', 'body': 'Consume 40g protein + 60g carbs within 45 min of training for max recovery.'},
      {'emoji': '📊', 'title': 'Track your lifts', 'body': 'Progressive overload is the #1 driver of muscle growth. Add weight weekly.'},
    ],
    'Maintain Weight_Moderate': [
      {'emoji': '⚖️', 'title': 'Stay consistent', 'body': 'You\'re on track! Keep calorie intake within ±100 kcal of your target.'},
      {'emoji': '🥦', 'title': 'Micronutrients matter', 'body': 'Add a serving of leafy greens to maintain vitamin and mineral balance.'},
      {'emoji': '🧘', 'title': 'Manage stress', 'body': 'Cortisol from stress triggers fat storage. Try 10 min of meditation today.'},
    ],
  };

  List<Map<String, String>> get _currentTips {
    final key = '${dummyUser.goal}_${dummyUser.activityLevel}';
    return _tips[key] ??
        _tips['Maintain Weight_Moderate']!;
  }

  @override
  void initState() {
    super.initState();
    _tipIndex = DateTime.now().hour % _currentTips.length;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.015).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextTip() async {
    if (_isAnimating) return;
    _isAnimating = true;
    await _slideController.reverse();
    setState(() => _tipIndex = (_tipIndex + 1) % _currentTips.length);
    _slideController.forward();
    _isAnimating = false;
  }

  @override
  Widget build(BuildContext context) {
    final tip = _currentTips[_tipIndex];
    final total = _currentTips.length;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity != null && d.primaryVelocity! < -200) _nextTip();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFFAB47BC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🤖', style: TextStyle(fontSize: 12)),
                              SizedBox(width: 5),
                              Text(
                                'AI Insight',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Dot indicators
                        Row(
                          children: List.generate(total, (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: i == _tipIndex ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _tipIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Content with slide animation
                    SlideTransition(
                      position: _slideAnimation,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Center(
                              child: Text(
                                tip['emoji']!,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tip['title']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tip['body']!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Based on: ${dummyUser.goal} • ${dummyUser.activityLevel}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                        GestureDetector(
                          onTap: _nextTip,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Next tip',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
