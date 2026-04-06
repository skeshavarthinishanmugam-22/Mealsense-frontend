# Meal Caching Implementation

## Overview
A lightweight caching system for today's meals to reduce redundant API calls and improve performance.

## Files Modified/Created

### New Files:
- **`lib/services/meal_cache_service.dart`** - Core caching service (singleton)

### Modified Files:
- **`lib/screens/dashboard/dashboard_screen.dart`** - Uses cache for today's meals
- **`lib/screens/food/food_list_screen.dart`** - Uses cache for "All" foods view
- **`lib/providers/user_provider.dart`** - Clears cache on logout

## How It Works

### Singleton Pattern
`MealCacheService` is implemented as a singleton, ensuring only one instance exists throughout the app lifecycle.

```dart
final cache = MealCacheService();
```

### Automatic Cache Validation
- Cache is **automatically invalidated** when a new day is detected
- **Same-day caching**: Data fetched today is reused until midnight
- **No manual expiration**: System tracks day changes automatically

```dart
// Automatically returns null if new day detected
final cachedFoods = cache.getCachedFoods();
```

### Cache Flow

#### Dashboard Screen (_HomeTab)
```
1. initState() -> _loadTodayFoods() & _loadMealPlan()
2. Check MealCacheService for cached data
3. If cache hit -> Use cached data (no API call)
4. If cache miss -> Fetch from API -> Store in cache
```

#### Food List Screen
```
1. When category = "All"
   - Check cache first
   - Use cached data if valid
   - Otherwise fetch and cache

2. When category = specific (BREAKFAST, etc.)
   - Fetch fresh from API (not cached)
   - Prevents stale category-specific data
```

## Cache Invalidation

### Automatic (No Action Required)
- ✅ **New day detected** - Cache automatically clears at midnight
- ✅ **Logout** - Cache cleared when user logs out

### Manual Invalidation (Call When Needed)
When user logs an action (ate, skip, substitute), invalidate cache:

```dart
// In your action handler (logged meal, skip, etc.)
MealCacheService().invalidateCache();

// Then reload meals
_loadTodayFoods();
_loadMealPlan();
```

### Example: Log a Meal Action
```dart
Future<void> _logMealAction(String action) async {
  try {
    // Call API to log the action
    await ApiService.logMealAction(action);
    
    // IMPORTANT: Invalidate cache after action
    MealCacheService().invalidateCache();
    print('Action logged and cache invalidated');
    
    // Reload meals with fresh data
    _loadTodayFoods();
    _loadMealPlan();
  } catch (e) {
    print('Error: $e');
  }
}
```

## API Reference

### Read Methods
```dart
final cache = MealCacheService();

// Get cached foods (returns null if invalid)
List<FoodModel>? foods = cache.getCachedFoods();

// Get cached meal plan (returns null if invalid)
Map<String, dynamic>? plan = cache.getCachedMealPlan();

// Check if cache exists and is valid
bool hasData = cache.hasCacheData();

// Get cache age in minutes
int? ageMinutes = cache.getCacheAgeMinutes();
```

### Write Methods
```dart
// Cache foods only
cache.cacheFoods(foodsList);

// Cache meal plan only
cache.cacheMealPlan(planMap);

// Cache both together
cache.cacheAllMealData(foodsList, planMap);

// Invalidate cache (triggered after user actions)
cache.invalidateCache();

// Clear all cache (triggered on logout)
cache.clearAll();
```

## Console Logging
All cache operations are logged with `[MealCache]` prefix:

```
[MealCache] Cached 10 foods at 2024-04-04T08:30:00.000000
[MealCache] Returning cached foods (10 items)
[MealCache] Cache invalidated: new day detected
[MealCache] Cache invalidated
```

## Performance Benefits

### Reduced API Calls
- **Before**: Multiple API calls when navigating between tabs/screens
- **After**: One API call per day, subsequent requests use cache

### Faster Load Times
- Cached data loads instantly (< 1ms)
- API calls only on cache miss or manual invalidation

### Bandwidth Savings
- Daily meal data fetched once instead of multiple times
- Significant savings on mobile data

## Testing the Cache

### Check Cache Status
```dart
final cache = MealCacheService();
print('Has data: ${cache.hasCachedData()}');
print('Age: ${cache.getCacheAgeMinutes()} minutes');
```

### Manual Cache Clear (for testing)
```dart
MealCacheService().clearAll();
```

### Monitor Cache Hits/Misses
Watch the console for `[MealCache]` and `[Dashboard]`/`[FoodList]` logs:
- `"Using cached..."` = Cache hit
- `"Cache miss..."` = API fetch

## Considerations

### Thread Safety
- Current implementation is single-threaded (UI thread only)
- Safe for Flutter's execution model

### Memory Usage
- Minimal memory footprint for cached meal data
- Automatically cleared on logout and new day

### Future Enhancements
- Add persistent cache (SharedPreferences) for offline access
- Add cache statistics and metrics
- Add TTL (time-to-live) with configurable expiration
- Add cache size limits

## Migration Path

If you have active meal logging features, add cache invalidation:

```dart
// After any action that modifies user state:
- Logged a meal
- Skipped a meal  
- Substituted an item
- Updated daily goals
- Changed dietary preferences

// Always call:
MealCacheService().invalidateCache();
```
