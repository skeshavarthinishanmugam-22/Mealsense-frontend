import '../models/food_model.dart';

/// Manages caching for meal data to reduce API calls
class MealCacheService {
  static final MealCacheService _instance = MealCacheService._internal();

  factory MealCacheService() {
    return _instance;
  }

  MealCacheService._internal();

  // Cache storage
  List<FoodModel>? _cachedFoods;
  Map<String, dynamic>? _cachedMealPlan;
  DateTime? _cacheTimestamp;

  /// Check if cache is valid (same day and within expiration)
  bool _isCacheValid() {
    if (_cacheTimestamp == null) return false;

    final now = DateTime.now();
    final cacheDate = _cacheTimestamp!;

    // Invalidate cache if it's a new day
    if (now.year != cacheDate.year ||
        now.month != cacheDate.month ||
        now.day != cacheDate.day) {
      print('[MealCache] Cache invalidated: new day detected');
      invalidateCache();
      return false;
    }

    // Cache is valid if fetched today
    return true;
  }

  /// Get cached foods or null if cache is invalid
  List<FoodModel>? getCachedFoods() {
    if (_isCacheValid() && _cachedFoods != null) {
      print('[MealCache] Returning cached foods (${_cachedFoods!.length} items)');
      return _cachedFoods;
    }
    return null;
  }

  /// Get cached meal plan or null if cache is invalid
  Map<String, dynamic>? getCachedMealPlan() {
    if (_isCacheValid() && _cachedMealPlan != null) {
      print('[MealCache] Returning cached meal plan');
      return _cachedMealPlan;
    }
    return null;
  }

  /// Store foods in cache
  void cacheFoods(List<FoodModel> foods) {
    _cachedFoods = foods;
    _cacheTimestamp = DateTime.now();
    print('[MealCache] Cached ${foods.length} foods at ${_cacheTimestamp!.toIso8601String()}');
  }

  /// Store meal plan in cache
  void cacheMealPlan(Map<String, dynamic> plan) {
    _cachedMealPlan = plan;
    _cacheTimestamp = DateTime.now();
    print('[MealCache] Cached meal plan at ${_cacheTimestamp!.toIso8601String()}');
  }

  /// Store both foods and meal plan together
  void cacheAllMealData(List<FoodModel> foods, Map<String, dynamic> plan) {
    _cachedFoods = foods;
    _cachedMealPlan = plan;
    _cacheTimestamp = DateTime.now();
    print('[MealCache] Cached all meal data (${foods.length} foods) at ${_cacheTimestamp!.toIso8601String()}');
  }

  /// Invalidate cache (call after user actions or explicit refresh)
  void invalidateCache() {
    _cachedFoods = null;
    _cachedMealPlan = null;
    _cacheTimestamp = null;
    print('[MealCache] Cache invalidated');
  }

  /// Check if cache exists and is valid
  bool hasCachedData() => _isCacheValid();

  /// Get cache age in minutes
  int? getCacheAgeMinutes() {
    if (_cacheTimestamp == null) return null;
    return DateTime.now().difference(_cacheTimestamp!).inMinutes;
  }

  /// Clear all cache (for debugging or logout)
  void clearAll() {
    _cachedFoods = null;
    _cachedMealPlan = null;
    _cacheTimestamp = null;
    print('[MealCache] All cache cleared');
  }
}
