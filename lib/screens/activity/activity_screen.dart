import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../providers/user_provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _meals = [];
  List<dynamic> _favorites = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMeals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMeals() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load today's meal history from MealLog
      final res = await ApiService.getMealHistory();
      final history = res['history'] as List<dynamic>? ?? [];
      
      // For favorites, still load from old meals endpoint for now
      final favs = await ApiService.getFavoriteMeals();
      
      setState(() {
        _meals = history;
        _favorites = favs;
        _loading = false;
      });
    } catch (e) {
      print('Error loading meals: $e');
      setState(() { _error = 'Network error'; _loading = false; });
    }
  }

  Future<void> _toggleFavorite(String mealId) async {
    await ApiService.toggleFavorite(mealId);
    _loadMeals();
  }

  Future<void> _deleteMeal(String mealId) async {
    await ApiService.deleteMeal(mealId);
    _loadMeals();
  }

  @override
  Widget build(BuildContext context) {
    final u = UserProvider.of(context).user;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Meals', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (u != null && u.dailyCalorieTarget > 0)
                      Text('Target: ${u.dailyCalorieTarget} kcal/day',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showLogMealSheet(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Log Meal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF00C853),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF00C853),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'All Meals (${_meals.length})'),
              Tab(text: 'Favourites (${_favorites.length})'),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMealList(_meals),
                _buildMealList(_favorites),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealList(List<dynamic> meals) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)));
    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadMeals, child: const Text('Retry')),
        ],
      ));
    }
    if (meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('No meals here yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Tap "Log Meal" to add your first meal',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
    }

    // Group meals by category (mealCategory for MealLog, category for Meal)
    final grouped = <String, List<dynamic>>{};
    for (final m in meals) {
      final cat = (m['mealCategory'] as String? ?? m['category'] as String? ?? 'Other').toUpperCase();
      grouped.putIfAbsent(cat, () => []).add(m);
    }

    return RefreshIndicator(
      onRefresh: _loadMeals,
      color: const Color(0xFF00C853),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _SummaryBar(meals: meals),
          const SizedBox(height: 16),
          ...grouped.entries.map((entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryHeader(category: entry.key),
              const SizedBox(height: 8),
              ...entry.value.map((m) => _MealTile(
                meal: m,
                onDelete: () => _deleteMeal(m['id'] as String? ?? ''),
              )),
              const SizedBox(height: 12),
            ],
          )),
        ],
      ),
    );
  }

  void _showLogMealSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _LogMealSheet(onSaved: _loadMeals),
    );
  }

  void _showEditMealSheet(BuildContext context, Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _LogMealSheet(onSaved: _loadMeals, existingMeal: meal),
    );
  }
}

// ─── Summary Bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final List<dynamic> meals;
  const _SummaryBar({required this.meals});

  @override
  Widget build(BuildContext context) {
    // Handle both Meal and MealLog formats
    final totalCal = meals.fold<int>(0, (s, m) => s + ((m['calories'] as int?) ?? 0));
    final totalProtein = meals.fold<double>(0, (s, m) {
      final protein = m['proteinGrams'] as dynamic ?? m['protein'] as dynamic;
      return s + (protein is num ? protein.toDouble() : 0.0);
    });
    final u = UserProvider.of(context).user;
    final target = u?.dailyCalorieTarget ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SumStat(label: 'Total Calories', value: '$totalCal kcal', color: const Color(0xFFFF6B35)),
              _SumStat(label: 'Protein', value: '${totalProtein.toStringAsFixed(1)}g', color: const Color(0xFF64B5F6)),
              _SumStat(label: 'Meals', value: '${meals.length}', color: const Color(0xFFFFB300)),
            ],
          ),
          if (target > 0) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (totalCal / target).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      totalCal > target ? Colors.red : const Color(0xFF00C853),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$totalCal / $target kcal',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _SumStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SumStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
  ]);
}

// ─── Category Header ───────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final String category;
  const _CategoryHeader({required this.category});

  static const _emojis = {
    'BREAKFAST': '🌅', 'LUNCH': '☀️', 'DINNER': '🌙',
    'SNACK': '🍎', 'PROTEIN': '💪',
  };

  @override
  Widget build(BuildContext context) {
    final emoji = _emojis[category] ?? '🍽️';
    final label = category[0] + category.substring(1).toLowerCase();
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D1B2A))),
    ]);
  }
}

// ─── Meal Tile ─────────────────────────────────────────────────────────────────

class _MealTile extends StatelessWidget {
  final dynamic meal;
  final VoidCallback onDelete;
  const _MealTile({required this.meal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Handle both Meal and MealLog formats
    final name = meal['mealName'] as String? ?? meal['name'] as String? ?? '';
    final calories = meal['calories'] as int?;
    final protein = meal['proteinGrams'] as dynamic ?? meal['protein'] as dynamic;
    final carbs = meal['carbsGrams'] as dynamic;
    final fat = meal['fatGrams'] as dynamic;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(spacing: 8, children: [
              if (calories != null) _Chip('🔥 $calories kcal', const Color(0xFFFF6B35)),
              if (protein != null) _Chip('💪 ${(protein is num ? protein.toStringAsFixed(1) : protein)}g', const Color(0xFF1E88E5)),
              if (carbs != null) _Chip('🌾 ${(carbs is num ? carbs.toStringAsFixed(1) : carbs)}g', const Color(0xFFFFB300)),
            ]),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

// ─── Log Meal Bottom Sheet ─────────────────────────────────────────────────────

class _LogMealSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final Map<String, dynamic>? existingMeal;
  const _LogMealSheet({required this.onSaved, this.existingMeal});

  @override
  State<_LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends State<_LogMealSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _calCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatsCtrl;
  late String _category;
  bool _saving = false;

  bool get _isEdit => widget.existingMeal != null;

  static const _categories = ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK', 'PROTEIN'];

  @override
  void initState() {
    super.initState();
    final m = widget.existingMeal;
    _nameCtrl = TextEditingController(text: m?['name'] as String? ?? '');
    _descCtrl = TextEditingController(text: m?['description'] as String? ?? '');
    _calCtrl = TextEditingController(text: m?['calories']?.toString() ?? '');
    _proteinCtrl = TextEditingController(text: m?['protein']?.toString() ?? '');
    _carbsCtrl = TextEditingController(text: m?['carbs']?.toString() ?? '');
    _fatsCtrl = TextEditingController(text: m?['fats']?.toString() ?? '');
    _category = (m?['category'] as String? ?? 'BREAKFAST').toUpperCase();
    if (!_categories.contains(_category)) _category = 'BREAKFAST';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _calCtrl.dispose();
    _proteinCtrl.dispose(); _carbsCtrl.dispose(); _fatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final body = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'category': _category,
      if (_calCtrl.text.isNotEmpty) 'calories': int.tryParse(_calCtrl.text),
      if (_proteinCtrl.text.isNotEmpty) 'protein': int.tryParse(_proteinCtrl.text),
      if (_carbsCtrl.text.isNotEmpty) 'carbs': int.tryParse(_carbsCtrl.text),
      if (_fatsCtrl.text.isNotEmpty) 'fats': int.tryParse(_fatsCtrl.text),
    };
    if (_isEdit) {
      await ApiService.updateMeal(widget.existingMeal!['id'] as String, body);
    } else {
      await ApiService.createMeal(body);
    }
    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            Text(_isEdit ? 'Edit Meal' : 'Log a Meal',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Category chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final sel = cat == _category;
                  return ChoiceChip(
                    label: Text(cat[0] + cat.substring(1).toLowerCase()),
                    selected: sel,
                    onSelected: (_) => setState(() => _category = cat),
                    selectedColor: const Color(0xFF00C853),
                    labelStyle: TextStyle(color: sel ? Colors.white : Colors.black, fontSize: 12),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            _Field(ctrl: _nameCtrl, hint: 'Meal name *', icon: Icons.restaurant),
            const SizedBox(height: 10),
            _Field(ctrl: _descCtrl, hint: 'Description (optional)', icon: Icons.notes),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _Field(ctrl: _calCtrl, hint: 'Calories', icon: Icons.local_fire_department, type: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _Field(ctrl: _proteinCtrl, hint: 'Protein (g)', icon: Icons.fitness_center, type: TextInputType.number)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _Field(ctrl: _carbsCtrl, hint: 'Carbs (g)', icon: Icons.grain, type: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _Field(ctrl: _fatsCtrl, hint: 'Fats (g)', icon: Icons.opacity, type: TextInputType.number)),
            ]),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'Update Meal' : 'Save Meal',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType type;
  const _Field({required this.ctrl, required this.hint, required this.icon, this.type = TextInputType.text});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      isDense: true,
    ),
  );
}
