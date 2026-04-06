import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/food_model.dart';
import '../../services/api_service.dart';
import '../../services/meal_cache_service.dart';

class FoodDetailScreen extends StatefulWidget {
  final FoodModel food;
  const FoodDetailScreen({super.key, required this.food});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  String? _actionInProgress; // Track which action is loading
  String? _actionCompleted; // Track completed action

  @override
  Widget build(BuildContext context) {
    final trafficColor = switch (widget.food.trafficLight) {
      'GREEN'  => const Color(0xFF00C853),
      'YELLOW' => const Color(0xFFFFB300),
      _        => const Color(0xFFE53935),
    };
    final gradientColors = _categoryGradient(widget.food.category);

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
                    Text(widget.food.emoji, style: const TextStyle(fontSize: 90)),
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
                          Text(widget.food.trafficLightMessage,
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
                  Text(widget.food.name,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1B2A))),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _Badge(widget.food.categoryLabel, const Color(0xFF00C853)),
                    if (widget.food.subCategory != null)
                      _Badge(widget.food.subCategory!, const Color(0xFF1E88E5)),
                    if (widget.food.isVegetarian) _Badge('🌿 Vegetarian', Colors.green.shade700),
                    if (widget.food.isVegan) _Badge('🌱 Vegan', Colors.teal),
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
                        Text(widget.food.portionDescription,
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
                      _StatTile('🔥', 'Calories', widget.food.calorieRangeLabel,
                          const Color(0xFFFF6B35)),
                      _StatTile('💪', 'Protein Level', widget.food.proteinLevel,
                          const Color(0xFF1E88E5)),
                      _StatTile('❤️', 'Health Score', '${widget.food.healthScore} / 10',
                          const Color(0xFF00C853)),
                      _StatTile('📊', 'Calorie Range',
                          '${widget.food.calorieRangeMin}–${widget.food.calorieRangeMax} kcal',
                          const Color(0xFF8E24AA)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Allergens ──
                  const _SectionLabel('Allergens'),
                  const SizedBox(height: 10),
                  _InfoCard(
                    child: widget.food.containsGluten || widget.food.containsDairy ||
                            widget.food.containsNuts || widget.food.containsEggs
                        ? Wrap(spacing: 8, runSpacing: 8, children: [
                            if (widget.food.containsGluten) _AllergenChip('⚠️ Gluten'),
                            if (widget.food.containsDairy) _AllergenChip('⚠️ Dairy'),
                            if (widget.food.containsNuts) _AllergenChip('⚠️ Nuts'),
                            if (widget.food.containsEggs) _AllergenChip('⚠️ Eggs'),
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
                  if (widget.food.substitutes != null && widget.food.substitutes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const _SectionLabel('Healthy Substitutes'),
                    const SizedBox(height: 10),
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.food.substitutes!
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
                  Row(
                    children: [
                      _buildActionButton('ate', 'Ate 🍽️', const Color(0xFF00C853)),
                      const SizedBox(width: 12),
                      _buildActionButton('skip', 'Skip ⏭️', const Color(0xFFFF9800)),
                      const SizedBox(width: 12),
                      _buildActionButton('substitute', 'Swap 🔄', const Color(0xFF1E88E5)),
                    ],
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

  Future<void> _handleMealAction(String action) async {
    setState(() => _actionInProgress = action);
    print('[FoodDetail] Starting meal action: $action for food: ${widget.food.id}');
    
    try {
      if (action == 'ate') {
        await ApiService.logMealAte(widget.food.id);
        print('[FoodDetail] Logged meal as eaten successfully');
      } else if (action == 'skip') {
        await ApiService.logMealSkip(widget.food.id);
        print('[FoodDetail] Logged meal as skipped successfully');
      } else if (action == 'substitute') {
        if (widget.food.substitutes == null || widget.food.substitutes!.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No substitutes available')),
            );
          }
          setState(() => _actionInProgress = null);
          return;
        }
        // Show substitute selection dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Choose a Substitute'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.food.substitutes!
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .map((substitute) => ListTile(
                            title: Text(substitute),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await ApiService.logMealSubstitute(
                                widget.food.id,
                                substitute,
                              );
                              print('[FoodDetail] Logged meal substitution successfully');
                              if (mounted) {
                                setState(() => _actionCompleted = 'substitute');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Substituted to $substitute')),
                                );
                                Future.delayed(const Duration(milliseconds: 500), () {
                                  if (mounted) Navigator.pop(context);
                                });
                              }
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
          );
        }
        setState(() => _actionInProgress = null);
        return;
      }

      // Mark action as completed for Ate and Skip
      if (mounted) {
        setState(() => _actionCompleted = action);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'ate'
                ? 'Logged as eaten ✓'
                : 'Logged as skipped ✓'),
            backgroundColor: const Color(0xFF00C853),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Invalidate cache and close after brief delay
        MealCacheService().invalidateCache();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      print('[FoodDetail] Error handling meal action: $e');
      if (mounted) {
        setState(() => _actionInProgress = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  Widget _buildActionButton(String action, String label, Color color) {
    final isLoading = _actionInProgress == action;
    final isCompleted = _actionCompleted == action;

    return Expanded(
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: isLoading || isCompleted ? null : () => _handleMealAction(action),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: color.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : isCompleted
                  ? const Icon(Icons.check_rounded)
                  : Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
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
