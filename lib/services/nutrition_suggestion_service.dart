import '../models/food_model.dart';

/// Service to intelligently suggest foods based on nutritional requirements
class NutritionSuggestionService {
  /// Suggest foods for a specific meal based on calorie & protein targets
  /// 
  /// Args:
  ///   - availableFoods: List of all available food items
  ///   - targetCalories: Target calories for this meal
  ///   - targetProtein: Target protein grams for this meal
  ///   - mealType: Type of meal (breakfast, lunch, dinner, snack)
  ///   - count: Number of suggestions to return
  /// 
  /// Returns: List of foods sorted by how well they match the targets
  static List<FoodModel> suggestFoodsForMeal(
    List<FoodModel> availableFoods,
    int targetCalories,
    int targetProtein,
    String mealType,
    {int count = 2}
  ) {
    if (availableFoods.isEmpty) return [];

    // Filter foods appropriate for this meal type
    final appropriateFoods = _filterByMealType(availableFoods, mealType);
    
    // Score each food based on how well it matches the targets
    final scoredFoods = appropriateFoods.map((food) {
      // Use average of calorie range
      final avgCalories = (food.calorieRangeMin + food.calorieRangeMax) ~/ 2;
      
      // Map protein level to grams (LOW: 5g, MEDIUM: 15g, HIGH: 25g)
      final proteinGrams = switch (food.proteinLevel) {
        'LOW' => 5,
        'MEDIUM' => 15,
        'HIGH' => 25,
        _ => 10,
      };
      
      final calorieScore = _calculateScoreDifference(avgCalories, targetCalories);
      final proteinScore = _calculateScoreDifference(proteinGrams, targetProtein);
      
      // Combined score (lower is better)
      final combinedScore = (calorieScore * 0.6) + (proteinScore * 0.4);
      
      return {
        'food': food,
        'score': combinedScore,
      };
    }).toList();

    // Sort by score and return top matches
    scoredFoods.sort((a, b) => 
      (a['score'] as num).compareTo(b['score'] as num)
    );

    return scoredFoods
      .take(count)
      .map((item) => item['food'] as FoodModel)
      .toList();
  }

  /// Calculate how different a value is from target (lower error = better match)
  static num _calculateScoreDifference(num actual, num target) {
    if (target == 0) return 0;
    return ((actual - target).abs() / target * 100); // Percentage difference
  }

  /// Filter foods appropriate for meal type
  static List<FoodModel> _filterByMealType(
    List<FoodModel> foods,
    String mealType,
  ) {
    return foods.where((food) {
      final category = food.category?.toLowerCase() ?? '';
      final mealTypeLower = mealType.toLowerCase();
      
      // Direct category match
      if (category == mealTypeLower) return true;
      
      // Flexible matching
      switch (mealTypeLower) {
        case 'breakfast':
          return category.contains('breakfast') || 
                 category.contains('morning') ||
                 ['porridge', 'cereal', 'oats', 'eggs', 'toast'].any(
                   (item) => food.name?.toLowerCase().contains(item) ?? false
                 );
        case 'lunch':
          return category.contains('lunch') || 
                 category.contains('main') ||
                 ['rice', 'curry', 'salad', 'dal'].any(
                   (item) => food.name?.toLowerCase().contains(item) ?? false
                 );
        case 'dinner':
          return category.contains('dinner') || 
                 category.contains('main') ||
                 ['rice', 'curry', 'dal', 'soup'].any(
                   (item) => food.name?.toLowerCase().contains(item) ?? false
                 );
        case 'snack':
          return category.contains('snack') || 
                 ['snack', 'fruit', 'nuts', 'chips', 'bar'].any(
                   (item) => food.name?.toLowerCase().contains(item) ?? false
                 );
        default:
          return true; // Include all if no specific match
      }
    }).toList();
  }

  /// Calculate targets per meal (distribute daily targets across meals)
  static Map<String, Map<String, int>> calculatePerMealTargets({
    required int dailyCalories,
    required int dailyProtein,
    int mealsPerDay = 3,
    int snacksPerDay = 1,
  }) {
    final totalMeals = mealsPerDay + snacksPerDay;
    
    // Main meals get 30% of daily intake, snacks get 10%
    final mainMealCalories = (dailyCalories * 0.3).toInt();
    final snackCalories = (dailyCalories * 0.1).toInt();
    
    final mainMealProtein = (dailyProtein * 0.3).toInt();
    final snackProtein = (dailyProtein * 0.1).toInt();
    
    return {
      'breakfast': {
        'calories': mainMealCalories,
        'protein': mainMealProtein,
      },
      'lunch': {
        'calories': mainMealCalories,
        'protein': mainMealProtein,
      },
      'dinner': {
        'calories': mainMealCalories,
        'protein': mainMealProtein,
      },
      'snacks': {
        'calories': snackCalories,
        'protein': snackProtein,
      },
    };
  }

  /// Get meal category emoji
  static String getMealEmoji(String mealType) {
    return switch (mealType.toLowerCase()) {
      'breakfast' => '🌅',
      'lunch' => '☀️',
      'dinner' => '🌙',
      'snacks' => '🍎',
      _ => '🍽️',
    };
  }
}
