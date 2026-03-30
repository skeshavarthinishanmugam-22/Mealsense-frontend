import 'package:flutter/material.dart';
import '../../models/diet_plan_model.dart';

class DietPlanScreen extends StatelessWidget {
  final DietPlanModel plan;
  const DietPlanScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final color = Color(plan.color);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: color,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(plan.title, style: const TextStyle(color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(child: Text(plan.icon, style: const TextStyle(fontSize: 70))),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Row
                  Row(
                    children: [
                      _SummaryChip(icon: '🔥', label: '${plan.totalCalories} kcal/day', color: color),
                      const SizedBox(width: 10),
                      _SummaryChip(icon: '🍽️', label: '3 meals/day', color: color),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(plan.description, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                  const SizedBox(height: 24),

                  _MealSection(title: '🌅 Breakfast', meals: plan.breakfast, color: color),
                  const SizedBox(height: 16),
                  _MealSection(title: '☀️ Lunch', meals: plan.lunch, color: color),
                  const SizedBox(height: 16),
                  _MealSection(title: '🌙 Dinner', meals: plan.dinner, color: color),
                  const SizedBox(height: 24),

                  // Calorie Breakdown
                  const Text('Calorie Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _CalorieBreakdown(plan: plan, color: color),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${plan.title} plan activated! 🎯'), backgroundColor: color),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Start This Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  const _SummaryChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String title;
  final List<MealEntry> meals;
  final Color color;
  const _MealSection({required this.title, required this.meals, required this.color});

  @override
  Widget build(BuildContext context) {
    final total = meals.fold(0, (sum, m) => sum + m.calories);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$total kcal', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 16),
          ...meals.map((m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.circle, size: 8, color: color),
                  const SizedBox(width: 8),
                  Text(m.name, style: const TextStyle(fontSize: 14)),
                ]),
                Text('${m.calories} kcal', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _CalorieBreakdown extends StatelessWidget {
  final DietPlanModel plan;
  final Color color;
  const _CalorieBreakdown({required this.plan, required this.color});

  @override
  Widget build(BuildContext context) {
    final bCal = plan.breakfast.fold(0, (s, m) => s + m.calories);
    final lCal = plan.lunch.fold(0, (s, m) => s + m.calories);
    final dCal = plan.dinner.fold(0, (s, m) => s + m.calories);
    final total = bCal + lCal + dCal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _BreakdownRow('Breakfast', bCal, total, color),
          const SizedBox(height: 10),
          _BreakdownRow('Lunch', lCal, total, color),
          const SizedBox(height: 10),
          _BreakdownRow('Dinner', dCal, total, color),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int calories;
  final int total;
  final Color color;
  const _BreakdownRow(this.label, this.calories, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? calories / total : 0.0;
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$calories kcal', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
