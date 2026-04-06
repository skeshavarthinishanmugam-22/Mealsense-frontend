import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'session_manager.dart';

class ApiService {
  static String get baseUrl =>
      'http://${AppConfig.defaultHost}:${AppConfig.port}/api/v1';

  // ── Token helpers ──────────────────────────────────────────────────────────

  /// Save JWT token and user info using SessionManager
  static Future<void> saveToken(String token, String userId, String userEmail) async {
    final sessionManager = SessionManager();
    await sessionManager.saveToken(token, userId, userEmail);
  }

  /// Get token from SessionManager
  static String? getToken() {
    return SessionManager().getToken();
  }

  /// Clear token using SessionManager (logout)
  static Future<void> clearToken() async {
    await SessionManager().clearToken();
  }

  /// Get authorization headers with token
  static Map<String, String> _authHeaders() {
    final token = getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  /// POST /v1/auth/signup
  /// Body: { displayName, email, password }
  /// Response: AuthResponse { user: UserDTO, token, message }
  static Future<Map<String, dynamic>> signup({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'displayName': displayName,
        'email': email,
        'password': password,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['token'] != null && data['user'] != null) {
      final user = data['user'] as Map<String, dynamic>;
      await saveToken(
        data['token'] as String,
        user['id'] as String,
        email,
      );
    }
    return {'statusCode': res.statusCode, ...data};
  }

  /// POST /v1/auth/login
  /// Body: { email, password }
  /// Response: AuthResponse { user: UserDTO, token, message }
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['token'] != null && data['user'] != null) {
      final user = data['user'] as Map<String, dynamic>;
      await saveToken(
        data['token'] as String,
        user['id'] as String,
        email,
      );
    }
    return {'statusCode': res.statusCode, ...data};
  }

  /// POST /v1/auth/refresh
  /// Refreshes the JWT token before it expires
  /// Response: AuthResponse { user: UserDTO, token, message }
  static Future<Map<String, dynamic>> refreshToken() async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: _authHeaders(),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['token'] != null && data['user'] != null) {
      final user = data['user'] as Map<String, dynamic>;
      await saveToken(
        data['token'] as String,
        user['id'] as String,
        (data['user'] as Map)['email'] as String? ?? SessionManager().getUserEmail() ?? '',
      );
    }
    return {'statusCode': res.statusCode, ...data};
  }

  /// GET /v1/auth/me
  /// Response: UserDTO { id, email, displayName, profileImageUrl, emailVerified, createdAt, lastLoginAt }
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _authHeaders(),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// GET /v1/auth/profile
  /// Response: UserProfileDTO (full profile with onboarding data)
  static Future<Map<String, dynamic>> getUserProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _authHeaders(),
    );
    if (res.statusCode == 200) {
      return {
        'statusCode': res.statusCode,
        ...jsonDecode(res.body) as Map<String, dynamic>,
      };
    }
    return {'statusCode': res.statusCode};
  }

  /// PUT /v1/auth/profile?displayName=&profileImageUrl=&goal=
  /// Response: UserDTO
  static Future<Map<String, dynamic>> updateProfile({
    required String displayName,
    String? profileImageUrl,
    String? goal,
  }) async {
    final params = <String, String>{'displayName': displayName};
    if (profileImageUrl != null) params['profileImageUrl'] = profileImageUrl;
    if (goal != null) params['goal'] = goal;
    final uri = Uri.parse('$baseUrl/auth/profile')
        .replace(queryParameters: params);
    final res = await http.put(uri, headers: _authHeaders());
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// PUT /v1/auth/goal?goal=
  /// Recalculates nutrition targets based on new fitness goal
  /// Response: Map { message, oldGoal, newGoal, dailyCalorieTarget, dailyProteinTarget, dailyCarbsTarget, dailyFatTarget }
  static Future<Map<String, dynamic>> updateFitnessGoal({
    required String goal,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/goal')
        .replace(queryParameters: {'goal': goal});
    final res = await http.put(uri, headers: _authHeaders());
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  // ── Onboarding ─────────────────────────────────────────────────────────────

  /// POST /v1/onboarding
  /// Body: { age, weightKg, heightCm, gender, goal, activityLevel, dietaryPreference, allergies }
  /// gender:        MALE | FEMALE
  /// goal:          LOSE_WEIGHT | MAINTAIN | GAIN_MUSCLE
  /// activityLevel: SEDENTARY | LIGHT | MODERATE | ACTIVE | VERY_ACTIVE
  /// dietaryPreference: Vegetarian | Pescatarian | Non-Vegetarian | Vegan
  /// Response: OnboardingResponse { userId, message, goalSummary,
  ///   dailyCalorieTarget, dailyProteinTarget, dailyCarbsTarget, dailyFatTarget }
  static Future<Map<String, dynamic>> completeOnboarding({
    required int age,
    required double weightKg,
    required double heightCm,
    required String gender,
    required String goal,
    required String activityLevel,
    String? dietaryPreference,
    List<String> allergies = const [],
  }) async {
    final body = {
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'gender': gender,
      'goal': goal,
      'activityLevel': activityLevel,
      'dietaryPreference': ?dietaryPreference,
      'allergies': allergies,
    };
    final res = await http.post(
      Uri.parse('$baseUrl/onboarding'),
      headers: _authHeaders(),
      body: jsonEncode(body),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// GET /v1/onboarding/status
  /// Response: { onboardingDone: bool }
  static Future<bool> getOnboardingStatus() async {
    final res = await http.get(
      Uri.parse('$baseUrl/onboarding/status'),
      headers: _authHeaders(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['onboardingDone'] == true;
    }
    return false;
  }

  // ── Meals ──────────────────────────────────────────────────────────────────

  /// GET /v1/meals?page=0&size=20
  /// Response: PageMealDTO { content, totalElements, totalPages, ... }
  static Future<Map<String, dynamic>> getMeals({
    int page = 0,
    int size = 20,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/meals?page=$page&size=$size'),
      headers: _authHeaders(),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// GET /v1/meals/{mealId}
  /// Response: MealDTO
  static Future<Map<String, dynamic>> getMealById(String mealId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/meals/$mealId'),
      headers: _authHeaders(),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// GET /v1/meals/favorites
  /// Response: List of MealDTO
  static Future<List<dynamic>> getFavoriteMeals() async {
    final res = await http.get(
      Uri.parse('$baseUrl/meals/favorites'),
      headers: _authHeaders(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    return [];
  }

  /// GET /v1/meals/category/{category}?page=0&size=20
  /// Response: PageMealDTO
  static Future<Map<String, dynamic>> getMealsByCategory(
    String category, {
    int page = 0,
    int size = 20,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/meals/category/$category?page=$page&size=$size'),
      headers: _authHeaders(),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// POST /v1/meals
  /// Body: CreateMealRequest { name, description, category, calories, protein, carbs, fats, imageUrl, rating, servings }
  /// Response: MealDTO
  static Future<Map<String, dynamic>> createMeal(
      Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/meals'),
      headers: _authHeaders(),
      body: jsonEncode(body),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// PUT /v1/meals/{mealId}
  /// Body: CreateMealRequest
  /// Response: MealDTO
  static Future<Map<String, dynamic>> updateMeal(
    String mealId,
    Map<String, dynamic> body,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/meals/$mealId'),
      headers: _authHeaders(),
      body: jsonEncode(body),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// PUT /v1/meals/{mealId}/favorite
  /// Response: MealDTO
  static Future<Map<String, dynamic>> toggleFavorite(String mealId) async {
    final res = await http.put(
      Uri.parse('$baseUrl/meals/$mealId/favorite'),
      headers: _authHeaders(),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// DELETE /v1/meals/{mealId}
  /// Response: 200 OK
  static Future<int> deleteMeal(String mealId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/meals/$mealId'),
      headers: _authHeaders(),
    );
    return res.statusCode;
  }

  // ── Food Suggestions ───────────────────────────────────────────────────────

  /// GET /v1/suggestions/foods?limit=20
  /// Response: List of IndianFood
  static Future<List<dynamic>> getAllFoodSuggestions({int limit = 20}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/suggestions/foods?limit=$limit'),
      headers: _authHeaders(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    return [];
  }

  /// GET /v1/suggestions/foods/{category}?limit=10
  /// category: BREAKFAST | LUNCH | DINNER | SNACK | PROTEIN
  /// Response: List of IndianFood
  static Future<List<dynamic>> getFoodSuggestionsByCategory(
    String category, {
    int limit = 10,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/suggestions/foods/$category?limit=$limit'),
      headers: _authHeaders(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    return [];
  }

  /// GET /v1/suggestions/meal-plan
  /// Response: Map (daily meal plan object)
  static Future<Map<String, dynamic>> getDailyMealPlan() async {
    final res = await http.get(
      Uri.parse('$baseUrl/suggestions/meal-plan'),
      headers: _authHeaders(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return {};
  }

  // ── Meal Actions ───────────────────────────────────────────────────────────

  /// POST /v1/suggestions/foods/{foodId}/ate
  /// Logs that user ate this food
  /// Response: { success: bool, message: string }
  static Future<Map<String, dynamic>> logMealAte(String foodId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/suggestions/foods/$foodId/ate'),
      headers: _authHeaders(),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// POST /v1/suggestions/foods/{foodId}/skip
  /// Logs that user skipped this food
  /// Response: { success: bool, message: string }
  static Future<Map<String, dynamic>> logMealSkip(String foodId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/suggestions/foods/$foodId/skip'),
      headers: _authHeaders(),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// POST /v1/suggestions/foods/{foodId}/substitute
  /// Body: { substituteId: string }
  /// Response: { success: bool, message: string }
  static Future<Map<String, dynamic>> logMealSubstitute(
    String foodId,
    String substituteId,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/suggestions/foods/$foodId/substitute'),
      headers: _authHeaders(),
      body: jsonEncode({'substituteId': substituteId}),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// POST /v1/suggestions/rate-food
  /// Body: { foodId: string, preference: "LIKE" | "DISLIKE" }
  /// Response: UserFoodPreference
  static Future<Map<String, dynamic>> rateFood(String foodId, String preference) async {
    final res = await http.post(
      Uri.parse('$baseUrl/suggestions/rate-food'),
      headers: _authHeaders(),
      body: jsonEncode({'foodId': foodId, 'preference': preference}),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// GET /v1/suggestions/disliked-foods
  /// Response: List of IndianFood
  static Future<List<dynamic>> getDislikedFoods() async {
    final res = await http.get(
      Uri.parse('$baseUrl/suggestions/disliked-foods'),
      headers: _authHeaders(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    return [];
  }

  // ── AI Meal Management ─────────────────────────────────────────────────────

  /// DUMMY DATA - Avoiding AI API calls that generate 4+ requests per suggestion
  /// Returns local fallback suggestions instead of calling Gemini AI
  static Future<Map<String, dynamic>> getAiSuggestions({
    String mealType = 'breakfast',
    int targetCalories = 430,
    int targetProtein = 35,
    String? dietary,
  }) async {
    // Simulate small delay like a real API call
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Dummy data - no external API calls
    final suggestions = _getDummySuggestions(mealType, dietary);
    
    return {
      'statusCode': 200,
      'mealType': mealType,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'suggestions': suggestions,
      'count': suggestions.length,
      'generatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static List<Map<String, dynamic>> _getDummySuggestions(String mealType, String? dietary) {
    final List<Map<String, dynamic>> breakfastOptions = [
      {
        'name': 'Dosa with Sambar & Egg',
        'calories': 420,
        'protein': 18.0,
        'carbs': 52.0,
        'fat': 12.0,
        'description': 'Crispy fermented rice and lentil pancake',
      },
      {
        'name': 'Poha with Peanuts & Veggies',
        'calories': 350,
        'protein': 10.0,
        'carbs': 48.0,
        'fat': 12.0,
        'description': 'Flattened rice with groundnuts and vegetables',
      },
      {
        'name': 'Idli with Sambar & Omelette',
        'calories': 380,
        'protein': 16.0,
        'carbs': 50.0,
        'fat': 11.0,
        'description': 'Steamed rice cakes with lentil stew',
      },
    ];

    final List<Map<String, dynamic>> lunchOptions = [
      {
        'name': 'Rice with Chicken Curry & Salad',
        'calories': 580,
        'protein': 32.0,
        'carbs': 68.0,
        'fat': 18.0,
        'description': 'Basmati rice with spiced chicken curry',
      },
      {
        'name': 'Rice with Paneer Tikka & Dal',
        'calories': 520,
        'protein': 28.0,
        'carbs': 65.0,
        'fat': 16.0,
        'description': 'Cottage cheese tikka with lentil curry',
      },
      {
        'name': 'Rice with Fish Curry & Salad',
        'calories': 550,
        'protein': 36.0,
        'carbs': 60.0,
        'fat': 17.0,
        'description': 'Coconut fish curry with rice',
      },
    ];

    final List<Map<String, dynamic>> dinnerOptions = [
      {
        'name': 'Tandoori Chicken with Roti & Salad',
        'calories': 480,
        'protein': 48.0,
        'carbs': 20.0,
        'fat': 16.0,
        'description': 'Marinated grilled chicken with whole wheat bread',
      },
      {
        'name': 'Paneer Tikka with Rice & Veggies',
        'calories': 420,
        'protein': 26.0,
        'carbs': 48.0,
        'fat': 14.0,
        'description': 'Grilled cottage cheese with rice and vegetables',
      },
      {
        'name': 'Vegetable Khichdi with Dal & Raita',
        'calories': 380,
        'protein': 14.0,
        'carbs': 52.0,
        'fat': 10.0,
        'description': 'One-pot rice and lentil comfort meal',
      },
    ];

    final List<Map<String, dynamic>> snackOptions = [
      {
        'name': 'Samosa with Tea',
        'calories': 280,
        'protein': 6.0,
        'carbs': 35.0,
        'fat': 12.0,
        'description': 'Crispy fried pastry with spiced filling',
      },
      {
        'name': 'Bhel Puri with Mint Chutney',
        'calories': 320,
        'protein': 8.0,
        'carbs': 42.0,
        'fat': 14.0,
        'description': 'Savory corn and lentil mix',
      },
      {
        'name': 'Vegetable Pakora with Curd',
        'calories': 270,
        'protein': 7.0,
        'carbs': 32.0,
        'fat': 12.0,
        'description': 'Spiced vegetable fritters with yogurt',
      },
    ];

    // Filter by dietary preference if provided
    final options = switch (mealType.toLowerCase()) {
      'breakfast' => breakfastOptions,
      'lunch' => lunchOptions,
      'dinner' => dinnerOptions,
      'snack' => snackOptions,
      _ => breakfastOptions,
    };

    // Filter by dietary restriction
    if (dietary != null && dietary.isNotEmpty) {
      return options.where((food) {
        final name = (food['name'] as String).toLowerCase();
        return !_isRestrictedFood(name, dietary);
      }).toList();
    }

    return options;
  }

  static bool _isRestrictedFood(String foodName, String dietary) {
    final dietLower = dietary.toLowerCase();
    
    if (dietLower.contains('vegetarian')) {
      return foodName.contains('chicken') || 
             foodName.contains('fish') || 
             foodName.contains('meat') ||
             foodName.contains('egg');
    }
    if (dietLower.contains('vegan')) {
      return foodName.contains('paneer') || 
             foodName.contains('curd') ||
             foodName.contains('raita') ||
             foodName.contains('chicken') || 
             foodName.contains('fish') || 
             foodName.contains('meat') ||
             foodName.contains('egg');
    }
    if (dietLower.contains('pescatarian')) {
      return foodName.contains('chicken') || 
             foodName.contains('meat') ||
             foodName.contains('egg');
    }
    
    return false;
  }

  /// POST /v1/ai/meals/custom
  /// Body: { mealName, description, calories, proteinGrams, carbsGrams, fatGrams, fiberGrams, mealCategory }
  /// Response: { message, mealId, meal }
  static Future<Map<String, dynamic>> addCustomMeal({
    required String mealName,
    String? description,
    required int calories,
    required double proteinGrams,
    required double carbsGrams,
    required double fatGrams,
    double? fiberGrams,
    required String mealCategory,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/ai/meals/custom'),
      headers: _authHeaders(),
      body: jsonEncode({
        'mealName': mealName,
        'description': description ?? '',
        'calories': calories,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
        'fiberGrams': fiberGrams ?? 0.0,
        'mealCategory': mealCategory,
      }),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// POST /v1/ai/meals/register
  /// Body: { mealName, mealCategory, calories, proteinGrams, carbsGrams, fatGrams, fiberGrams, mealDate, notes }
  /// Response: { message, logId, meal }
  static Future<Map<String, dynamic>> registerMeal({
    required String mealName,
    required String mealCategory,
    required int calories,
    required double proteinGrams,
    required double carbsGrams,
    required double fatGrams,
    double? fiberGrams,
    String? mealDate,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/ai/meals/register'),
      headers: _authHeaders(),
      body: jsonEncode({
        'mealName': mealName,
        'mealCategory': mealCategory,
        'calories': calories,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
        'fiberGrams': fiberGrams ?? 0.0,
        'mealDate': mealDate,
        'notes': notes ?? '',
      }),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// GET /v1/ai/meals/custom
  /// Response: { meals: List<CustomMeal>, count }
  static Future<Map<String, dynamic>> getCustomMeals() async {
    final res = await http.get(
      Uri.parse('$baseUrl/ai/meals/custom'),
      headers: _authHeaders(),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// GET /v1/ai/meals/history?startDate=2024-01-01&endDate=2024-12-31
  /// Response: { history: List<MealLog>, count, totalCalories, totalProtein, dateRange }
  static Future<Map<String, dynamic>> getMealHistory({
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    final uri = Uri.parse('$baseUrl/ai/meals/history')
        .replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri, headers: _authHeaders());
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  /// DELETE /v1/ai/meals/custom/{mealId}
  /// Response: { message }
  static Future<int> deleteCustomMeal(String mealId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/ai/meals/custom/$mealId'),
      headers: _authHeaders(),
    );
    return res.statusCode;
  }
}
