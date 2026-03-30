import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/food_model.dart';
import '../../services/api_service.dart';
import 'food_detail_screen.dart';

class FoodListScreen extends StatefulWidget {
  final String? initialCategory;
  /// Set to true when pushing as a full route (not embedded as a tab)
  final bool asRoute;
  const FoodListScreen({super.key, this.initialCategory, this.asRoute = false});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  late String _selectedCategory;
  List<FoodModel> _foods = [];
  bool _isLoading = true;
  String? _error;

  static const _categories = ['All', 'BREAKFAST', 'LUNCH', 'DINNER', 'SNACK', 'PROTEIN'];
  static const _categoryLabels = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Protein'];
  static const _categoryEmojis = ['🥗', '🌅', '☀️', '🌙', '🍎', '💪'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    _fetchFoods();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchFoods() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final List<dynamic> raw;
      if (_selectedCategory == 'All') {
        raw = await ApiService.getAllFoodSuggestions(limit: 50);
      } else {
        raw = await ApiService.getFoodSuggestionsByCategory(_selectedCategory, limit: 30);
      }
      if (mounted) {
        setState(() {
          _foods = raw.map((e) => FoodModel.fromJson(e as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load foods'; _isLoading = false; });
    }
  }

  List<FoodModel> get _filtered => _foods
      .where((f) => f.name.toLowerCase().contains(_search.toLowerCase()))
      .toList();

@override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        // Search bar header
        Container(
          color: const Color(0xFF0D1B2A),
          padding: EdgeInsets.fromLTRB(16, widget.asRoute ? 0 : 48, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.asRoute) ...[  
                const Text('Food & Nutrition',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${_filtered.length} items',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search foods...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                          onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        // Category chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final sel = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    _fetchFoods();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: sel
                          ? const LinearGradient(
                              colors: [Color(0xFF00C853), Color(0xFF00897B)])
                          : null,
                      color: sel ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_categoryEmojis[i], style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(_categoryLabels[i],
                            style: TextStyle(
                                color: sel ? Colors.white : Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildBody()),
      ],
    );

    if (widget.asRoute) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1B2A),
          foregroundColor: Colors.white,
          title: Text(
            _selectedCategory == 'All'
                ? 'All Foods'
                : _selectedCategory[0] + _selectedCategory.substring(1).toLowerCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        body: body,
      );
    }
    return body;
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchFoods,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ]),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(_search.isNotEmpty ? 'No results for "$_search"' : 'No foods in this category',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchFoods,
      color: const Color(0xFF00C853),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _FoodListTile(food: _filtered[i]),
      ),
    );
  }
}

// ─── Premium Food List Tile ────────────────────────────────────────────────────

class _FoodListTile extends StatelessWidget {
  final FoodModel food;
  const _FoodListTile({required this.food});

  @override
  Widget build(BuildContext context) {
    final trafficColor = switch (food.trafficLight) {
      'GREEN'  => const Color(0xFF00C853),
      'YELLOW' => const Color(0xFFFFB300),
      _        => const Color(0xFFE53935),
    };

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => FoodDetailScreen(food: food),
          transitionsBuilder: (_, a, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Emoji block
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: _categoryGradient(food.category),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16)),
              ),
              child: Center(
                  child: Text(food.emoji, style: const TextStyle(fontSize: 30))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0D1B2A))),
                    const SizedBox(height: 3),
                    Text(food.portionDescription,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(children: [
                      _MiniChip(food.calorieRangeLabel, const Color(0xFF00C853)),
                      const SizedBox(width: 6),
                      _MiniChip(food.proteinLevel, const Color(0xFF1E88E5)),
                      if (food.isVegetarian) ...[
                        const SizedBox(width: 6),
                        _MiniChip('🌿 Veg', Colors.green.shade700),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: trafficColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(height: 4),
                  Text('${food.healthScore}/10',
                      style: TextStyle(
                          color: trafficColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ],
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

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6)),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}
