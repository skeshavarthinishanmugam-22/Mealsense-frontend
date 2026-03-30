import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../screens/food/food_detail_screen.dart';

class FoodCard extends StatefulWidget {
  final FoodModel food;
  const FoodCard({super.key, required this.food});

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _scaleController;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    return GestureDetector(
      onTapDown: (_) => _scaleController.reverse(),
      onTapUp: (_) => _scaleController.forward(),
      onTapCancel: () => _scaleController.forward(),
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FoodDetailScreen(food: food),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 145,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _categoryGradient(food.category),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Center(
                  child: Text(food.emoji, style: const TextStyle(fontSize: 42)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1A1A2E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            food.calorieRangeLabel,
                            style: const TextStyle(
                                color: Color(0xFF00C853),
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        _TrafficDot(food.trafficLight),
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

  List<Color> _categoryGradient(String category) {
    switch (category) {
      case 'BREAKFAST': return [const Color(0xFFFFF9C4), const Color(0xFFFFE082)];
      case 'LUNCH':     return [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)];
      case 'DINNER':    return [const Color(0xFFE3F2FD), const Color(0xFF90CAF9)];
      case 'SNACK':     return [const Color(0xFFFCE4EC), const Color(0xFFF48FB1)];
      case 'PROTEIN':   return [const Color(0xFFFFF3E0), const Color(0xFFFFCC80)];
      default:          return [const Color(0xFFF3E5F5), const Color(0xFFCE93D8)];
    }
  }
}

class _TrafficDot extends StatelessWidget {
  final String trafficLight;
  const _TrafficDot(this.trafficLight);

  @override
  Widget build(BuildContext context) {
    final color = switch (trafficLight) {
      'GREEN'  => const Color(0xFF00C853),
      'YELLOW' => const Color(0xFFFFB300),
      _        => const Color(0xFFE53935),
    };
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
