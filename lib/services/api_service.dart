import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static const String _tokenKey = 'jwt_token';

  static String get baseUrl =>
      'http://${AppConfig.host}:${AppConfig.port}/api/v1';

  // ── Token helpers ──────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
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
    if (data['token'] != null) await saveToken(data['token'] as String);
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
    if (res.statusCode == 200 && data['token'] != null) {
      await saveToken(data['token'] as String);
    }
    return {'statusCode': res.statusCode, ...data};
  }

  /// GET /v1/auth/me
  /// Response: UserDTO { id, email, displayName, profileImageUrl, emailVerified, createdAt, lastLoginAt }
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
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
    final res = await http.put(uri, headers: await _authHeaders());
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }

  // ── Onboarding ─────────────────────────────────────────────────────────────

  /// POST /v1/onboarding
  /// Body: { age, weightKg, heightCm, gender, goal, activityLevel, allergies }
  /// gender:        MALE | FEMALE
  /// goal:          LOSE_WEIGHT | MAINTAIN | GAIN_MUSCLE
  /// activityLevel: SEDENTARY | LIGHT | MODERATE | ACTIVE | VERY_ACTIVE
  /// Response: OnboardingResponse { userId, message, goalSummary,
  ///   dailyCalorieTarget, dailyProteinTarget, dailyCarbsTarget, dailyFatTarget }
  static Future<Map<String, dynamic>> completeOnboarding({
    required int age,
    required double weightKg,
    required double heightCm,
    required String gender,
    required String goal,
    required String activityLevel,
    List<String> allergies = const [],
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/onboarding'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'age': age,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'gender': gender,
        'goal': goal,
        'activityLevel': activityLevel,
        'allergies': allergies,
      }),
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
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
    );
    return res.statusCode;
  }

  // ── Food Suggestions ───────────────────────────────────────────────────────

  /// GET /v1/suggestions/foods?limit=20
  /// Response: List of IndianFood
  static Future<List<dynamic>> getAllFoodSuggestions({int limit = 20}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/suggestions/foods?limit=$limit'),
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    return [];
  }

  /// GET /v1/suggestions/meal-plan
  /// Response: Map (daily meal plan object)
  static Future<Map<String, dynamic>> getDailyMealPlan() async {
    final res = await http.get(
      Uri.parse('$baseUrl/suggestions/meal-plan'),
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
      body: jsonEncode({'substituteId': substituteId}),
    );
    return {
      'statusCode': res.statusCode,
      ...jsonDecode(res.body) as Map<String, dynamic>,
    };
  }
}
