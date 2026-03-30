import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/food_model.dart';

class FoodDetailScreen extends StatelessWidget {
  final FoodModel food;
  const FoodDetailScreen({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    final trafficColor = switch (food.trafficLight) {
      'GREEN'  => const Color(0xFF00C853),
      'YELLOW' => const Color(0xFFFFB300),
      _        => const Color(0xFFE53935),
    };
    final gradientColors = _categoryGradient(food.category);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: gradientColors[1],
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF0D1B2A), size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(food.emoji, style: const TextStyle(fontSize: 90)),
                    const SizedBox(height: 8),
                    // Traffic light badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: trafficColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: trafficColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                  color: trafficColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(food.trafficLightMessage,
                              style: TextStyle(
                                  color: trafficColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name + category ──
                  Text(food.name,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1B2A))),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _Badge(food.categoryLabel, const Color(0xFF00C853)),
                    if (food.subCategory != null)
                      _Badge(food.subCategory!, const Color(0xFF1E88E5)),
                    if (food.isVegetarian) _Badge('🌿 Vegetarian', Colors.green.shade700),
                    if (food.isVegan) _Badge('🌱 Vegan', Colors.teal),
                  ]),
                  const SizedBox(height: 20),

                  // ── Portion ──
                  _InfoCard(
                    child: Row(children: [
                      const Text('🍽️', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Portion Size',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(food.portionDescription,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0D1B2A))),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // ── Nutrition Stats Grid ──
                  const _SectionLabel('Nutrition Info'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      _StatTile('🔥', 'Calories', food.calorieRangeLabel,
                          const Color(0xFFFF6B35)),
                      _StatTile('💪', 'Protein Level', food.proteinLevel,
                          const Color(0xFF1E88E5)),
                      _StatTile('❤️', 'Health Score', '${food.healthScore} / 10',
                          const Color(0xFF00C853)),
                      _StatTile('📊', 'Calorie Range',
                          '${food.calorieRangeMin}–${food.calorieRangeMax} kcal',
                          const Color(0xFF8E24AA)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Allergens ──
                  const _SectionLabel('Allergens'),
                  const SizedBox(height: 10),
                  _InfoCard(
                    child: food.containsGluten || food.containsDairy ||
                            food.containsNuts || food.containsEggs
                        ? Wrap(spacing: 8, runSpacing: 8, children: [
                            if (food.containsGluten) _AllergenChip('⚠️ Gluten'),
                            if (food.containsDairy) _AllergenChip('⚠️ Dairy'),
                            if (food.containsNuts) _AllergenChip('⚠️ Nuts'),
                            if (food.containsEggs) _AllergenChip('⚠️ Eggs'),
                          ])
                        : Row(children: [
                            const Icon(Icons.check_circle,
                                color: Color(0xFF00C853), size: 18),
                            const SizedBox(width: 8),
                            Text('No common allergens',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500)),
                          ]),
                  ),

                  // ── Substitutes ──
                  if (food.substitutes != null && food.substitutes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const _SectionLabel('Healthy Substitutes'),
                    const SizedBox(height: 10),
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: food.substitutes!
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .map((s) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(children: [
                                    const Icon(Icons.swap_horiz_rounded,
                                        color: Color(0xFF00C853), size: 16),
                                    const SizedBox(width: 8),
                                    Text(s,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF0D1B2A))),
                                  ]),
                                ))
                            .toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Got it',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _categoryGradient(String cat) => switch (cat) {
    'BREAKFAST' => [const Color(0xFFFFF9C4), const Color(0xFFFFE082)],
    'LUNCH'     => [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)],
    'DINNER'    => [const Color(0xFFE3F2FD), const Color(0xFF90CAF9)],
    'SNACK'     => [const Color(0xFFFCE4EC), const Color(0xFFF48FB1)],
    'PROTEIN'   => [const Color(0xFFFFF3E0), const Color(0xFFFFCC80)],
    _           => [const Color(0xFFF3E5F5), const Color(0xFFCE93D8)],
  };
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)));
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2)),
      ],
    ),
    child: child,
  );
}

class _StatTile extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _StatTile(this.emoji, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.15)),
    ),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ]),
      ),
    ]),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Text(label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 12)),
  );
}

class _AllergenChip extends StatelessWidget {
  final String label;
  const _AllergenChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3))),
    child: Text(label,
        style: const TextStyle(
            color: Color(0xFFE53935),
            fontWeight: FontWeight.w600,
            fontSize: 12)),
  );
}
