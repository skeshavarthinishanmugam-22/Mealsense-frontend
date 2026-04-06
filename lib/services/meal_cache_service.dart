import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_model.dart';

/// Manages caching for meal data to reduce API calls with persistent storage
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
  
  // SharedPreferences keys
  static const String _foodsCacheKey = 'meal_cache_foods';
  static const String _planCacheKey = 'meal_cache_plan';
  static const String _timestampCacheKey = 'meal_cache_timestamp';
  
  SharedPreferences? _prefs;
  
  /// Initialize shared preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromDisk();
  }
  
  /// Load cache from disk
  void _loadFromDisk() {
    try {
      final timestampStr = _prefs?.getString(_timestampCacheKey);
      if (timestampStr == null) {
        print('[MealCache] No timestamp found on disk');
        return;
      }
      
      _cacheTimestamp = DateTime.parse(timestampStr);
      
      // Check if timestamp is still valid (same day)
      if (!_isCacheValid()) {
        print('[MealCache] Cache expired (different day)');
        _clearDisk();
        return;
      }
      
      // Load foods if available
      final foodsJson = _prefs?.getString(_foodsCacheKey);
      if (foodsJson != null) {
        try {
          final foodsList = (jsonDecode(foodsJson) as List)
              .map((f) => FoodModel.fromJson(f as Map<String, dynamic>))
              .toList();
          _cachedFoods = foodsList;
          print('[MealCache] ✓ Loaded ${foodsList.length} foods from disk');
        } catch (e) {
          print('[MealCache] Error parsing foods: $e');
        }
      }
      
      // Load meal plan if available
      final planJson = _prefs?.getString(_planCacheKey);
      if (planJson != null) {
        try {
          _cachedMealPlan = jsonDecode(planJson) as Map<String, dynamic>;
          print('[MealCache] ✓ Loaded meal plan from disk');
        } catch (e) {
          print('[MealCache] Error parsing meal plan: $e');
        }
      }
      
      print('[MealCache] ✓ Cache initialized from disk at ${_cacheTimestamp?.toLocal()}');
    } catch (e) {
      print('[MealCache] Error loading from disk: $e');
      _clearDisk();
    }
  }
  
  /// Save cache to disk
  Future<void> _saveToDisk() async {
    try {
      if (_cacheTimestamp != null) {
        await _prefs?.setString(_timestampCacheKey, _cacheTimestamp!.toIso8601String());
      }
      if (_cachedFoods != null) {
        final foodsJson = jsonEncode(_cachedFoods!.map((f) => f.toJson()).toList());
        await _prefs?.setString(_foodsCacheKey, foodsJson);
      }
      if (_cachedMealPlan != null) {
        final planJson = jsonEncode(_cachedMealPlan);
        await _prefs?.setString(_planCacheKey, planJson);
      }
      print('[MealCache] ✓ Saved to disk (foods: ${_cachedFoods != null}, plan: ${_cachedMealPlan != null})');
    } catch (e) {
      print('[MealCache] Error saving to disk: $e');
    }
  }
  
  /// Clear cache from disk
  Future<void> _clearDisk() async {
    try {
      await _prefs?.remove(_foodsCacheKey);
      await _prefs?.remove(_planCacheKey);
      await _prefs?.remove(_timestampCacheKey);
      print('[MealCache] ✓ Cleared from disk');
    } catch (e) {
      print('[MealCache] Error clearing disk: $e');
    }
  }

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
    // Fire and forget - save to disk in background
    _saveToDisk().then((_) {
      print('[MealCache] ✓ Saved ${foods.length} foods to disk (async)');
    });
    print('[MealCache] Loading ${foods.length} foods into memory');
  }

  /// Store meal plan in cache
  void cacheMealPlan(Map<String, dynamic> plan) {
    _cachedMealPlan = plan;
    _cacheTimestamp = DateTime.now();
    // Fire and forget - save to disk in background
    _saveToDisk().then((_) {
      print('[MealCache] ✓ Saved meal plan to disk (async)');
    });
    print('[MealCache] Loading meal plan into memory');
  }

  /// Store both foods and meal plan together
  void cacheAllMealData(List<FoodModel> foods, Map<String, dynamic> plan) {
    _cachedFoods = foods;
    _cachedMealPlan = plan;
    _cacheTimestamp = DateTime.now();
    // Fire and forget - save to disk in background
    _saveToDisk().then((_) {
      print('[MealCache] ✓ Saved all data to disk (async)');
    });
    print('[MealCache] Loading all data into memory (${foods.length} foods + plan)');
  }

  /// Invalidate cache (call after user actions or explicit refresh)
  void invalidateCache() {
    _cachedFoods = null;
    _cachedMealPlan = null;
    _cacheTimestamp = null;
    // Clear from disk in background
    _clearDisk().then((_) {
      print('[MealCache] ✓ Cleared from disk (async)');
    });
    print('[MealCache] Cache invalidated from memory');
  }

  /// Check if cache exists and is valid
  bool hasCachedData() => _isCacheValid();

  /// Get cache age in minutes
  int? getCacheAgeMinutes() {
    if (_cacheTimestamp == null) return null;
    return DateTime.now().difference(_cacheTimestamp!).inMinutes;
  }

  /// Get the timestamp when cache was last updated
  DateTime? getCachedMealPlanTime() => _cacheTimestamp;

  /// Clear all cache (for debugging or logout)
  void clearAll() {
    _cachedFoods = null;
    _cachedMealPlan = null;
    _cacheTimestamp = null;
    _clearDisk().then((_) {
      print('[MealCache] ✓ All cache cleared from disk (async)');
    });
    print('[MealCache] All cache cleared from memory');
  }
}
