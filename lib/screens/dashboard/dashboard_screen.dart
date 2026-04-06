import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../models/food_model.dart';
import '../../services/api_service.dart';
import '../../services/meal_cache_service.dart';
import '../../widgets/food_card.dart';
import '../food/food_list_screen.dart';
import '../activity/activity_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_selectedIndex == index) return;
    _fadeController.reset();
    setState(() => _selectedIndex = index);
    _fadeController.forward();
  }

  late final List<Widget> _tabs = [
    const _HomeTab(),
    const FoodListScreen(),  // has its own Scaffold
    const ActivityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF0F4F8),
      // FoodListScreen has its own Scaffold, others need SafeArea wrapping
      body: FadeTransition(opacity: _fadeAnimation, child: _tabs[_selectedIndex]),
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ─── Floating Nav Bar ──────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _FloatingNavBar({required this.selectedIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.restaurant_rounded, Icons.restaurant_outlined, 'Meals'),
    (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Activity'),
    (Icons.person_rounded, Icons.person_outlined, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 18 : 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF00897B)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? item.$1 : item.$2,
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                    size: 22,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 7),
                    Text(
                      item.$3,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<FoodModel> _todayFoods = [];
  bool _foodsLoading = true;
  Map<String, dynamic> _mealPlan = {};
  bool _planLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayFoods();
    _loadMealPlan();
  }

  Future<void> _loadTodayFoods() async {
    setState(() => _foodsLoading = true);
    
    // Try to use cached data first
    final cache = MealCacheService();
    final cachedFoods = cache.getCachedFoods();
    
    if (cachedFoods != null) {
      print('[Dashboard] Using cached foods');
      if (mounted) {
        setState(() {
          _todayFoods = cachedFoods;
          _foodsLoading = false;
        });
      }
      return;
    }
    
    // Fetch from API if cache is empty/invalid
    print('[Dashboard] Cache miss, fetching from API');
    final raw = await ApiService.getAllFoodSuggestions(limit: 10);
    if (mounted) {
      final foods = raw.map((e) => FoodModel.fromJson(e as Map<String, dynamic>)).toList();
      cache.cacheFoods(foods);
      setState(() {
        _todayFoods = foods;
        _foodsLoading = false;
      });
    }
  }

  Future<void> _loadMealPlan() async {
    // Try to use cached data first
    final cache = MealCacheService();
    final cachedPlan = cache.getCachedMealPlan();
    
    if (cachedPlan != null) {
      print('[Dashboard] Using cached meal plan');
      if (mounted) setState(() { _mealPlan = cachedPlan; _planLoading = false; });
      return;
    }
    
    // Fetch from API if cache is empty/invalid
    print('[Dashboard] Cache miss, fetching meal plan from API');
    final plan = await ApiService.getDailyMealPlan();
    if (mounted) {
      cache.cacheMealPlan(plan);
      setState(() { _mealPlan = plan; _planLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final greetEmoji = hour < 12 ? '☀️' : hour < 17 ? '🌤️' : '🌙';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _Header(greeting: '$greeting $greetEmoji')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Nutrition Targets ──
              _NutritionTargetsCard(),
              const SizedBox(height: 20),

              // ── Today's Suggestions ──
              _SectionTitle(
                title: "Today's Picks",
                subtitle: 'Suggested for you',
                onSeeAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FoodListScreen(asRoute: true)),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 185,
                child: _foodsLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
                    : _todayFoods.isEmpty
                        ? const Center(child: Text('No suggestions available'))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _todayFoods.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 14),
                            itemBuilder: (_, i) => FoodCard(food: _todayFoods[i]),
                          ),
              ),
              const SizedBox(height: 24),

              // ── Daily Meal Plan ──
              if (!_planLoading && _mealPlan.isNotEmpty) ...[
                const _SectionTitle(title: 'Daily Meal Plan', subtitle: 'Personalised for your goal'),
                const SizedBox(height: 14),
                _MealPlanCard(plan: _mealPlan),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String greeting;
  const _Header({required this.greeting});

  @override
  Widget build(BuildContext context) {
    final u = UserProvider.of(context).user;
    final name = u?.name.isNotEmpty == true ? u!.name : dummyUser.name;
    final goal = u?.goalDisplay ?? '';
    final weight = u?.weightKg ?? 0.0;
    final height = u?.heightCm ?? 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 58, 22, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B4332), Color(0xFF00C853)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              _Avatar(name: name),
            ],
          ),
          const SizedBox(height: 20),
          // Stat chips — only show if data is loaded
          if (weight > 0 || height > 0 || goal.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (goal.isNotEmpty)
                  _StatChip(icon: Icons.flag_rounded, label: goal, color: const Color(0xFF00C853)),
                if (weight > 0)
                  _StatChip(
                      icon: Icons.monitor_weight_outlined,
                      label: '${weight.toStringAsFixed(1)} kg',
                      color: const Color(0xFF64B5F6)),
                if (height > 0)
                  _StatChip(
                      icon: Icons.height,
                      label: '${height.toStringAsFixed(0)} cm',
                      color: const Color(0xFFFFB300)),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00897B)]),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

// ─── Nutrition Targets Card ────────────────────────────────────────────────────

class _NutritionTargetsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final u = UserProvider.of(context).user;
    final calories = u?.dailyCalorieTarget ?? 0;
    final protein = u?.dailyProteinTarget ?? 0;
    final carbs = u?.dailyCarbsTarget ?? 0;
    final fat = u?.dailyFatTarget ?? 0;

    if (calories == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.local_fire_department_rounded, color: Color(0xFF00C853), size: 20),
            const SizedBox(width: 8),
            const Text('Daily Nutrition Targets',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _MacroTile(label: 'Calories', value: '$calories', unit: 'kcal',
                color: const Color(0xFFFF6B35), icon: '🔥'),
            const SizedBox(width: 10),
            _MacroTile(label: 'Protein', value: '${protein}g', unit: 'daily',
                color: const Color(0xFF1E88E5), icon: '💪'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _MacroTile(label: 'Carbs', value: '${carbs}g', unit: 'daily',
                color: const Color(0xFFFFB300), icon: '🌾'),
            const SizedBox(width: 10),
            _MacroTile(label: 'Fat', value: '${fat}g', unit: 'daily',
                color: const Color(0xFF8E24AA), icon: '🥑'),
          ]),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label, value, unit, icon;
  final Color color;
  const _MacroTile(
      {required this.label,
      required this.value,
      required this.unit,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title, subtitle;
  final VoidCallback? onSeeAll;
  const _SectionTitle({required this.title, required this.subtitle, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                    letterSpacing: 0.2)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('See all',
                  style: TextStyle(
                      color: Color(0xFF00C853),
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ),
      ],
    );
  }
}

// ─── Daily Meal Plan Card ──────────────────────────────────────────────────────

class _MealPlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _MealPlanCard({required this.plan});

  static const _slots = [
    ('🌅', 'Breakfast', 'breakfast'),
    ('☀️', 'Lunch', 'lunch'),
    ('🌙', 'Dinner', 'dinner'),
    ('🍎', 'Snacks', 'snacks'),
  ];

  @override
  Widget build(BuildContext context) {
    final targetCal = plan['targetCalories'] as int?;
    final targetProtein = plan['targetProtein'] as int?;

    // Debug: Log meal plan structure
    print('[Dashboard] Meal plan keys: ${plan.keys.toList()}');
    for (var slot in _slots) {
      final items = plan[slot.$3] as List<dynamic>?;
      print('[Dashboard] ${slot.$2} (${slot.$3}): ${items?.length ?? 0} items');
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Targets row
          if (targetCal != null || targetProtein != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1B2A), Color(0xFF1B4332)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (targetCal != null)
                    _PlanStat('🎯 $targetCal kcal', 'Target Calories'),
                  if (targetProtein != null)
                    _PlanStat('💪 ${targetProtein}g', 'Target Protein'),
                ],
              ),
            ),

          // Meal slots - show all slots, even if empty
          ..._slots.map((slot) {
            final items = plan[slot.$3] as List<dynamic>?;
            if (items == null || items.isEmpty) {
              return _MealSlot(emoji: slot.$1, label: slot.$2, items: []);
            }
            return _MealSlot(emoji: slot.$1, label: slot.$2, items: items);
          }),
        ],
      ),
    );
  }
}

class _PlanStat extends StatelessWidget {
  final String value, label;
  const _PlanStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    Text(label,
        style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]);
}

class _MealSlot extends StatelessWidget {
  final String emoji, label;
  final List<dynamic> items;
  const _MealSlot({required this.emoji, required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0D1B2A))),
          ]),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: const Text(
                'No items planned',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...items.map((item) {
              final food = item as Map<String, dynamic>;
              final name = food['name'] as String? ?? '';
              final cal = food['calorieRangeLabel'] as String?;
              final traffic = food['trafficLight'] as String? ?? 'GREEN';
              final trafficColor = switch (traffic) {
                'GREEN'  => const Color(0xFF00C853),
                'YELLOW' => const Color(0xFFFFB300),
                _        => const Color(0xFFE53935),
              };
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: trafficColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  if (cal != null)
                    Text(cal,
                        style: const TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                ]),
              );
            }),
        ],
      ),
    );
  }
}
