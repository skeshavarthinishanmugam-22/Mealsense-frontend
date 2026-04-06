import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/user_provider.dart';
import '../../models/food_model.dart';
import '../../services/api_service.dart';
import '../../services/meal_cache_service.dart';
import '../../services/nutrition_suggestion_service.dart';
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
    
    // Load profile and meals after first frame (safe context access)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UserProvider.of(context).loadProfile();
      }
    });
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
      backgroundColor: const Color(0xFFF0F4F8),
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
    return SizedBox(
      height: 80,
      child: Container(
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
          mainAxisSize: MainAxisSize.max,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final isSelected = i == selectedIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 14 : 10,
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.$1 : item.$2,
                            color: isSelected ? Colors.white : Colors.grey.shade500,
                            size: 22,
                          ),
                          if (isSelected) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.$3,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
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
  bool _planLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTodayFoods();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer meal plan loading to after build phase
    if (!_planLoaded) {
      _planLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('[Dashboard] Checking cache on startup...');
        
        // Check if cache exists first - don't load if it does
        final cache = MealCacheService();
        final cachedPlan = cache.getCachedMealPlan();
        final cachedTime = cache.getCachedMealPlanTime();
        
        print('[Dashboard] Cache status: plan=${cachedPlan != null}, time=$cachedTime');
        
        if (cachedPlan != null && cachedTime != null) {
          final now = DateTime.now();
          final cachedDay = DateTime(cachedTime.year, cachedTime.month, cachedTime.day);
          final today = DateTime(now.year, now.month, now.day);
          
          if (cachedDay == today) {
            print('[Dashboard] ✓ CACHE HIT - Using valid cache from today');
            if (mounted) {
              setState(() {
                _mealPlan = cachedPlan;
                _planLoading = false;
              });
            }
            return;
          } else {
            print('[Dashboard] Cache is from different day (${cachedDay.toLocal()} vs ${today.toLocal()})');
          }
        }
        
        print('[Dashboard] CACHE MISS - Will fetch from API');
        _loadMealPlan();
      });
    }
  }

  Future<void> _loadTodayFoods() async {
    try {
      // Try to use cached data first
      final cache = MealCacheService();
      final cachedFoods = cache.getCachedFoods();
      
      if (cachedFoods != null) {
        print("[Dashboard] ✓ Using CACHED today's picks (${cachedFoods.length} foods)");
        if (mounted) {
          setState(() {
            _todayFoods = cachedFoods;
            _foodsLoading = false;
          });
        }
        return;
      }
      
      // Fetch from API if cache is empty/invalid
      print('[Dashboard] ✗ Cache miss - fetching today\'s picks from API');
      final raw = await ApiService.getAllFoodSuggestions(limit: 10);
      if (mounted) {
        final foods = raw.map((e) => FoodModel.fromJson(e as Map<String, dynamic>)).toList();
        cache.cacheFoods(foods);
        setState(() {
          _todayFoods = foods;
          _foodsLoading = false;
        });
        print('[Dashboard] ✓ Fetched and cached ${foods.length} foods');
      }
    } catch (e) {
      print('[Dashboard] Error loading foods: $e');
      if (mounted) {
        setState(() => _foodsLoading = false);
      }
    }
  }

  Future<void> _loadMealPlan() async {
    try {
      print('[Dashboard] Loading meal plan...');
      
      // Check cache first - if cached today, use it
      final cache = MealCacheService();
      final cachedPlan = cache.getCachedMealPlan();
      final cachedTime = cache.getCachedMealPlanTime();
      
      if (cachedPlan != null && cachedTime != null) {
        final now = DateTime.now();
        final cachedDay = DateTime(cachedTime.year, cachedTime.month, cachedTime.day);
        final today = DateTime(now.year, now.month, now.day);
        
        if (cachedDay == today) {
          print('[Dashboard] ✓ Using CACHED meal plan from today (${cachedTime.hour}:${cachedTime.minute})');
          if (mounted) {
            setState(() {
              _mealPlan = cachedPlan;
              _planLoading = false;
            });
          }
          return;
        }
      }
      
      print('[Dashboard] ✗ Cache miss/expired - using HARDCODED meals');
      
      // Get user targets
      final userProvider = UserProvider.of(context);
      final user = userProvider.user;
      
      if (user == null) {
        print('[Dashboard] User profile not yet loaded');
        if (mounted) setState(() => _planLoading = false);
        return;
      }
      
      final dailyCalories = user.dailyCalorieTarget ?? 0;
      final dailyProtein = user.dailyProteinTarget ?? 0;
      
      if (dailyCalories == 0 || dailyProtein == 0) {
        print('[Dashboard] No targets - skipping meal plan');
        if (mounted) setState(() => _planLoading = false);
        return;
      }
      
      // HARDCODED MEALS - Replace with AI API later
      final transformedPlan = <String, dynamic>{
        'targetCalories': dailyCalories,
        'targetProtein': dailyProtein,
        'breakfast': [
          {
            'id': 'meal_breakfast_1',
            'name': 'Masala Dosa',
            'calorieRangeLabel': '320 cal',
            'trafficLight': 'GREEN',
            'servingGrams': 200,
            'protein': 8.0,
            'carbs': 52.0,
            'fat': 8.0,
            'fiber': 3.0,
          },
          {
            'id': 'meal_breakfast_2',
            'name': 'Poha with peanuts',
            'calorieRangeLabel': '280 cal',
            'trafficLight': 'GREEN',
            'servingGrams': 150,
            'protein': 9.0,
            'carbs': 48.0,
            'fat': 5.0,
            'fiber': 2.5,
          },
          {
            'id': 'meal_breakfast_3',
            'name': 'Idli with sambar',
            'calorieRangeLabel': '200 cal',
            'trafficLight': 'GREEN',
            'servingGrams': 180,
            'protein': 7.0,
            'carbs': 38.0,
            'fat': 2.0,
            'fiber': 2.0,
          },
        ],
        'lunch': [
          {
            'id': 'meal_lunch_1',
            'name': 'Chicken biryani',
            'calorieRangeLabel': '450 cal',
            'trafficLight': 'GREEN',
            'servingGrams': 250,
            'protein': 28.0,
            'carbs': 48.0,
            'fat': 12.0,
            'fiber': 1.5,
          },
          {
            'id': 'meal_lunch_2',
            'name': 'Dal makhani with roti',
            'calorieRangeLabel': '380 cal',
            'trafficLight': 'GREEN',
            'servingGrams': 280,
            'protein': 15.0,
            'carbs': 52.0,
            'fat': 8.0,
            'fiber': 4.0,
          },
          {
            'id': 'meal_lunch_3',
            'name': 'Fish curry with rice',
            'calorieRangeLabel': '420 cal',
            'trafficLight': 'GREEN',
            'servingGrams': 300,
            'protein': 32.0,
            'carbs': 45.0,
            'fat': 7.0,
            'fiber': 2.0,
          },
        ],
        'dinner': [
          {
            'id': 'meal_dinner_1',
            'name': 'Tandoori chicken',
            'calorieRangeLabel': '280 cal',
            'trafficLight': 'GREEN',
            'servingGrams': 200,
            'protein': 38.0,
            'carbs': 8.0,
            'fat': 6.0,
            'fiber': 0.5,
          },
          {
            'id': 'meal_dinner_2',
            'name': 'Paneer tikka',
            'calorieRangeLabel': '250 cal',
            'trafficLight': 'YELLOW',
            'servingGrams': 180,
            'protein': 20.0,
            'carbs': 12.0,
            'fat': 10.0,
            'fiber': 1.0,
          },
          {
            'id': 'meal_dinner_3',
            'name': 'Vegetable stir fry',
            'calorieRangeLabel': '180 cal',
            'trafficLight': 'GREEN',
            'servingGrams': 250,
            'protein': 6.0,
            'carbs': 28.0,
            'fat': 4.0,
            'fiber': 5.0,
          },
        ],
        'snacks': [
          {
            'id': 'meal_snack_1',
            'name': 'Greek yogurt with berries',
            'calorieRangeLabel': '120 cal',
            'trafficLight': 'GREEN',
            'servingGrams': 150,
            'protein': 15.0,
            'carbs': 14.0,
            'fat': 2.0,
            'fiber': 2.0,
          },
          {
            'id': 'meal_snack_2',
            'name': 'Roasted chickpeas',
            'calorieRangeLabel': '140 cal',
            'trafficLight': 'GREEN',
            'servingGrams': 30,
            'protein': 6.0,
            'carbs': 16.0,
            'fat': 4.0,
            'fiber': 3.5,
          },
          {
            'id': 'meal_snack_3',
            'name': 'Almonds & dates',
            'calorieRangeLabel': '160 cal',
            'trafficLight': 'YELLOW',
            'servingGrams': 40,
            'protein': 5.0,
            'carbs': 18.0,
            'fat': 8.0,
            'fiber': 2.0,
          },
        ],
      };
      
      print('[Dashboard] ✓ Hardcoded meals loaded: 3 breakfast + 3 lunch + 3 dinner + 3 snacks');
      
      if (mounted) {
        cache.cacheMealPlan(transformedPlan);
        setState(() { 
          _mealPlan = transformedPlan; 
          _planLoading = false;
        });
        print('[Dashboard] ✓ Meal plan SAVED to cache');
      }
    } catch (e) {
      print('[Dashboard] Error: $e');
      if (mounted) setState(() => _planLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final greetEmoji = hour < 12 ? '☀️' : hour < 17 ? '🌤️' : '🌙';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting $greetEmoji',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Track your nutrition journey',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Nutrition Targets ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _NutritionTargetsCard(),
            ),
            const SizedBox(height: 24),

            // ── Today's Suggestions ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Picks",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Suggested for you',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FoodListScreen(asRoute: true)),
                    ),
                    child: Text('See all',
                        style: TextStyle(fontSize: 12, color: const Color(0xFF00C853), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 185,
              child: _foodsLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
                  : _todayFoods.isEmpty
                      ? const Center(child: Text('No suggestions available'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _todayFoods.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (_, i) => FoodCard(food: _todayFoods[i]),
                        ),
            ),
            const SizedBox(height: 24),

            // ── Daily Meal Plan or Available Foods ──
            if (_mealPlan.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Daily Meal Plan',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Personalised for your goal',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _planLoading = true);
                        MealCacheService().invalidateCache();
                        _loadMealPlan();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF00C853)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _MealPlanCard(
                plan: _mealPlan,
                onRemoveMeal: (mealType, index) {
                  setState(() {
                    final items = _mealPlan[mealType] as List<dynamic>? ?? [];
                    if (index >= 0 && index < items.length) {
                      items.removeAt(index);
                      print('[Dashboard] Removed meal at index $index from $mealType');
                    }
                  });
                },
              ),
            ] else if (!_planLoading && _todayFoods.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Available Meals',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 220,
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _todayFoods.length,
                  itemBuilder: (_, i) => FoodCard(food: _todayFoods[i]),
                ),
              ),
            ],
            const SizedBox(height: 120), // Bottom padding for nav bar
          ],
        ),
      ),
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
    final name = u?.name.isNotEmpty == true ? u!.name : 'User';
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
  final Function(String mealType, int index)? onRemoveMeal;
  const _MealPlanCard({required this.plan, this.onRemoveMeal});

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
              return _MealSlot(emoji: slot.$1, label: slot.$2, items: [], mealType: slot.$3);
            }
            return _MealSlot(
              emoji: slot.$1,
              label: slot.$2,
              items: items,
              mealType: slot.$3,
              onRemoveMeal: onRemoveMeal,
            );
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

class _MealSlot extends StatefulWidget {
  final String emoji, label, mealType;
  final List<dynamic> items;
  final Function(String mealType, int index)? onRemoveMeal;
  const _MealSlot({
    required this.emoji,
    required this.label,
    required this.items,
    required this.mealType,
    this.onRemoveMeal,
  });

  @override
  State<_MealSlot> createState() => _MealSlotState();
}

class _MealSlotState extends State<_MealSlot> {
  final Set<int> _actionIndices = {}; // Track which items are in action

  /// Get current index of food item in widget items list
  int _getCurrentIndex(Map<String, dynamic> food) {
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i] as Map<String, dynamic>;
      if (item['id'] == food['id']) {
        return i;
      }
    }
    return -1;
  }

  /// Parse calories from calorieRangeLabel (e.g., "320 cal" -> 320)
  int _parseCalories(String? label) {
    if (label == null) return 0;
    final match = RegExp(r'(\d+)').firstMatch(label);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  Future<void> _handleAction(Map<String, dynamic> food, int index, String action) async {
    setState(() => _actionIndices.add(index));
    
    try {
      print('[Dashboard] Handling $action for ${food['name']}');
      
      String? foodId = food['id'] as String?;
      if (foodId == null) {
        throw Exception('Food ID not found');
      }
      
      if (action == 'ate') {
        // Log as eaten - register meal to MealLog table
        final name = food['name'] as String? ?? 'Meal';
        final category = widget.label.toUpperCase();
        final calories = _parseCalories(food['calorieRangeLabel'] as String?);
        final protein = (food['protein'] as num?)?.toDouble() ?? 0.0;
        final carbs = (food['carbs'] as num?)?.toDouble() ?? 0.0;
        final fat = (food['fat'] as num?)?.toDouble() ?? 0.0;
        final fiber = (food['fiber'] as num?)?.toDouble() ?? 0.0;
        
        await ApiService.registerMeal(
          mealName: name,
          mealCategory: category,
          calories: calories,
          proteinGrams: protein,
          carbsGrams: carbs,
          fatGrams: fat,
          fiberGrams: fiber,
        );
        print('[Dashboard] Logged as eaten to MealLog: $name');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ $name logged to activity'),
              duration: const Duration(seconds: 1),
              backgroundColor: const Color(0xFF00C853),
            ),
          );
        }
      } else if (action == 'notToday') {
        // Skip for today
        await ApiService.logMealSkip(foodId);
        print('[Dashboard] Skipped for today: ${food['name']}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⏭️ ${food['name']} hidden for today'),
              duration: const Duration(seconds: 1),
              backgroundColor: const Color(0xFFFF9800),
            ),
          );
        }
      } else if (action == 'dontLike') {
        // Mark as dislike
        await ApiService.rateFood(foodId, 'DISLIKE');
        print('[Dashboard] Marked as dislike: ${food['name']}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('👎 ${food['name']} noted, we\'ll avoid it'),
              duration: const Duration(seconds: 1),
              backgroundColor: const Color(0xFFE53935),
            ),
          );
        }
      }
      
      // Remove meal from daily plan after successful action
      widget.onRemoveMeal?.call(widget.mealType, _getCurrentIndex(food));
      
      // Don't invalidate cache automatically - let user click Refresh button to fetch new suggestions
      print('[Dashboard] Meal action logged, cache remains valid. Click Refresh to get new suggestions.');
    } catch (e) {
      print('[Dashboard] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionIndices.remove(index));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(widget.label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0D1B2A))),
          ]),
          const SizedBox(height: 6),
          if (widget.items.isEmpty)
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
            ...widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
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
                    const SizedBox(height: 8),
                    // Action buttons row
                    Row(
                      children: [
                        // Ate button
                        Expanded(
                          child: SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: _actionIndices.contains(index) ? null : () => _handleAction(food, index, 'ate'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C853),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                              child: _actionIndices.contains(index)
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                      ),
                                    )
                                  : const Text('Ate 🍽️', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Not Today button
                        Expanded(
                          child: SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: _actionIndices.contains(index) ? null : () => _handleAction(food, index, 'notToday'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9800),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                              child: _actionIndices.contains(index)
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                      ),
                                    )
                                  : const Text('Not Today', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Don't Like button
                        Expanded(
                          child: SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: _actionIndices.contains(index) ? null : () => _handleAction(food, index, 'dontLike'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                              child: _actionIndices.contains(index)
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                      ),
                                    )
                                  : const Text('👎', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
