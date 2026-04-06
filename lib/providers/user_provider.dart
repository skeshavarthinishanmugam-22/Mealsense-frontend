import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/meal_cache_service.dart';

class AppUser {
  final String name;
  final String email;
  final String phone;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String goal;
  final String activityLevel;
  final List<String> medicalConditions;
  final int dailyCalorieTarget;
  final int dailyProteinTarget;
  final int dailyCarbsTarget;
  final int dailyFatTarget;
  final int waterTargetMl;

  // Backend fields
  final String? id;
  final String? token;
  final bool onboardingDone;

  const AppUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.activityLevel,
    required this.medicalConditions,
    required this.dailyCalorieTarget,
    required this.dailyProteinTarget,
    required this.dailyCarbsTarget,
    required this.dailyFatTarget,
    required this.waterTargetMl,
    this.id,
    this.token,
    this.onboardingDone = false,
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  String get goalDisplay => switch (goal) {
        'LOSE_WEIGHT' => 'Lose Weight',
        'GAIN_MUSCLE' => 'Gain Muscle',
        'MAINTAIN'    => 'Maintain Weight',
        _             => goal,
      };

  String get activityDisplay => switch (activityLevel) {
        'SEDENTARY'   => 'Sedentary',
        'LIGHT'       => 'Light',
        'MODERATE'    => 'Moderate',
        'ACTIVE'      => 'Active',
        'VERY_ACTIVE' => 'Very Active',
        _             => activityLevel,
      };

  String get goalEmoji => switch (goal) {
        'LOSE_WEIGHT'     => '🏃',
        'GAIN_MUSCLE'     => '💪',
        'MAINTAIN'        => '⚖️',
        'Lose Weight'     => '🏃',
        'Gain Muscle'     => '💪',
        'Maintain Weight' => '⚖️',
        _                 => '🎯',
      };

  // ── Mifflin-St Jeor BMR → TDEE → goal-adjusted calories ──────────────────
  static int calcCalories({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
  }) {
    final bmr = gender.toLowerCase() == 'female'
        ? (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161
        : (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;

    final multiplier = switch (activityLevel) {
      'Sedentary' => 1.2,
      'Light' => 1.375,
      'Moderate' => 1.55,
      'Active' => 1.725,
      'Very Active' => 1.9,
      _ => 1.55,
    };

    final tdee = bmr * multiplier;
    return switch (goal) {
      'Lose Weight' => (tdee - 500).round(),
      'Gain Muscle' => (tdee + 300).round(),
      _ => tdee.round(),
    };
  }

  static int calcProtein({required double weightKg, required String goal}) {
    final g = goal == 'Gain Muscle' ? 2.0 : goal == 'Lose Weight' ? 1.6 : 1.2;
    return (weightKg * g).round();
  }

  static int calcFat({required double weightKg, required String goal}) {
    final g = goal == 'Lose Weight' ? 0.7 : 1.0;
    return (weightKg * g).round();
  }

  static int calcCarbs({
    required int calories,
    required int protein,
    required int fat,
  }) {
    return ((calories - (protein * 4) - (fat * 9)) / 4).round().clamp(0, 9999);
  }

  static int calcWater({
    required double weightKg,
    required String activityLevel,
  }) {
    final base = weightKg * 35;
    final bonus =
        (activityLevel == 'Active' || activityLevel == 'Very Active') ? 500 : 0;
    return (base + bonus).round();
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class UserNotifier extends ChangeNotifier {
  AppUser? _user;
  bool _profileCached = false; // Track if profile has been fetched this session

  AppUser? get user => _user;
  bool get hasUser => _user != null;
  bool get isProfileCached => _profileCached; // Getter to check cache status

  void setUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  void updateUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  /// Calls POST /v1/auth/login. Returns error message or null on success.
  Future<String?> login(String email, String password) async {
    try {
      final res = await ApiService.login(email: email, password: password);
      if (res['statusCode'] == 200) {
        final u = res['user'] as Map<String, dynamic>?;
        _user = AppUser(
          id: u?['id'] as String?,
          name: u?['displayName'] as String? ?? '',
          email: u?['email'] as String? ?? email,
          phone: '',
          age: 0,
          gender: '',
          heightCm: 0,
          weightKg: 0,
          goal: '',
          activityLevel: '',
          medicalConditions: const [],
          dailyCalorieTarget: 0,
          dailyProteinTarget: 0,
          dailyCarbsTarget: 0,
          dailyFatTarget: 0,
          waterTargetMl: 0,
          token: res['token'] as String?,
          onboardingDone: false,
        );
        notifyListeners();
        return null;
      }
      return res['message'] as String? ?? 'Login failed';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Calls POST /v1/auth/signup. Returns error message or null on success.
  Future<String?> signup({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final res = await ApiService.signup(
        displayName: displayName,
        email: email,
        password: password,
      );
      if (res['statusCode'] == 200 || res['statusCode'] == 201) {
        final u = res['user'] as Map<String, dynamic>?;
        _user = AppUser(
          id: u?['id'] as String?,
          name: u?['displayName'] as String? ?? displayName,
          email: u?['email'] as String? ?? email,
          phone: '',
          age: 0,
          gender: '',
          heightCm: 0,
          weightKg: 0,
          goal: '',
          activityLevel: '',
          medicalConditions: const [],
          dailyCalorieTarget: 0,
          dailyProteinTarget: 0,
          dailyCarbsTarget: 0,
          dailyFatTarget: 0,
          waterTargetMl: 0,
          token: res['token'] as String?,
          onboardingDone: false,
        );
        notifyListeners();
        return null;
      }
      return res['message'] as String? ?? 'Signup failed';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Calls POST /v1/onboarding and updates user with returned nutrition targets.
  Future<String?> completeOnboarding({
    required int age,
    required double weightKg,
    required double heightCm,
    required String gender,
    required String goal,
    required String activityLevel,
    String? dietaryPreference,
    List<String> allergies = const [],
  }) async {
    try {
      final res = await ApiService.completeOnboarding(
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
        gender: gender,
        goal: goal,
        activityLevel: activityLevel,
        dietaryPreference: dietaryPreference,
        allergies: allergies,
      );
      if (res['statusCode'] == 200 || res['statusCode'] == 201) {
        final water = AppUser.calcWater(weightKg: weightKg, activityLevel: activityLevel);
        _user = AppUser(
          id: _user?.id,
          name: _user?.name ?? '',
          email: _user?.email ?? '',
          phone: _user?.phone ?? '',
          age: age,
          gender: gender,
          heightCm: heightCm,
          weightKg: weightKg,
          goal: goal,
          activityLevel: activityLevel,
          medicalConditions: allergies,
          dailyCalorieTarget: res['dailyCalorieTarget'] as int? ?? 0,
          dailyProteinTarget: res['dailyProteinTarget'] as int? ?? 0,
          dailyCarbsTarget: res['dailyCarbsTarget'] as int? ?? 0,
          dailyFatTarget: res['dailyFatTarget'] as int? ?? 0,
          waterTargetMl: water,
          token: _user?.token,
          onboardingDone: true,
        );
        notifyListeners();
        return null;
      }
      return res['message'] as String? ?? 'Onboarding failed';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Loads full profile from GET /v1/auth/profile and updates user state.
  /// Caches the result in memory for the session; subsequent calls are no-ops unless cache is cleared.
  Future<void> loadProfile() async {
    // Skip if already cached this session
    if (_profileCached) {
      print('[UserProvider] Profile already cached this session, skipping API call');
      return;
    }
    try {
      print('[UserProvider] Fetching profile from API...');
      final res = await ApiService.getUserProfile();
      if (res['statusCode'] == 200) {
        _user = AppUser(
          id: res['id'] as String? ?? _user?.id,
          name: res['displayName'] as String? ?? _user?.name ?? '',
          email: res['email'] as String? ?? _user?.email ?? '',
          phone: _user?.phone ?? '',
          age: res['age'] as int? ?? _user?.age ?? 0,
          gender: res['gender'] as String? ?? _user?.gender ?? '',
          heightCm: (res['heightCm'] as num?)?.toDouble() ?? _user?.heightCm ?? 0,
          weightKg: (res['weightKg'] as num?)?.toDouble() ?? _user?.weightKg ?? 0,
          goal: res['goal'] as String? ?? _user?.goal ?? '',
          activityLevel: res['activityLevel'] as String? ?? _user?.activityLevel ?? '',
          medicalConditions: (res['allergies'] as List<dynamic>?)?.cast<String>() ?? _user?.medicalConditions ?? [],
          dailyCalorieTarget: res['dailyCalorieTarget'] as int? ?? _user?.dailyCalorieTarget ?? 0,
          dailyProteinTarget: res['dailyProteinTarget'] as int? ?? _user?.dailyProteinTarget ?? 0,
          dailyCarbsTarget: res['dailyCarbsTarget'] as int? ?? _user?.dailyCarbsTarget ?? 0,
          dailyFatTarget: res['dailyFatTarget'] as int? ?? _user?.dailyFatTarget ?? 0,
          waterTargetMl: _user?.waterTargetMl ?? 0,
          token: _user?.token,
          onboardingDone: res['onboardingDone'] as bool? ?? true,
        );
        _profileCached = true; // Mark profile as cached
        print('[UserProvider] Profile cached for session');
        notifyListeners();
      } else {
        print('[UserProvider] Profile fetch failed with status: ${res['statusCode']}');
        throw Exception('Failed to load profile: ${res['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('[UserProvider] Error loading profile: $e');
      rethrow; // Rethrow so caller knows about the failure
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    MealCacheService().clearAll(); // Clear meal cache on logout
    _profileCached = false; // Clear profile cache on logout
    _user = null;
    notifyListeners();
  }

  /// Checks onboarding status from backend.
  Future<bool> checkOnboardingStatus() async {
    if (_user == null) return false;
    return ApiService.getOnboardingStatus();
  }

  void clear() {
    _profileCached = false; // Clear cache on clear
    _user = null;
    notifyListeners();
  }

  /// Explicitly refresh the profile cache (called after profile updates)
  Future<void> refreshProfile() async {
    _profileCached = false; // Clear cache to force refresh
    await loadProfile();
  }
}

// ── InheritedNotifier wrapper ─────────────────────────────────────────────────

class UserProvider extends InheritedNotifier<UserNotifier> {
  const UserProvider({
    super.key,
    required UserNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static UserNotifier of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<UserProvider>()!
        .notifier!;
  }
}
