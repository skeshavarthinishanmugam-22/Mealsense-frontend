import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/session_manager.dart';
import 'services/session_refresh_manager.dart';
import 'services/meal_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize session manager to load saved token
  await SessionManager().initialize();
  // Initialize meal cache service to load persisted cache from disk
  await MealCacheService().initialize();
  runApp(const MealSenseApp());
}

class MealSenseApp extends StatefulWidget {
  const MealSenseApp({super.key});

  @override
  State<MealSenseApp> createState() => _MealSenseAppState();
}

class _MealSenseAppState extends State<MealSenseApp> {
  final _userNotifier = UserNotifier();
  bool _sessionLoaded = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Load user from saved session if exists
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final sessionManager = SessionManager();
    bool loggedIn = false;
    
    if (sessionManager.isLoggedIn()) {
      try {
        print('[App] Saved token found, validating...');
        
        // Try to load full profile - this validates the token with backend
        await _userNotifier.loadProfile();
        
        print('[App] ✓ Profile loaded successfully, session is valid');
        loggedIn = true;
        
        // Start automatic token refresh if logged in
        SessionRefreshManager().startAutoRefresh();
      } catch (e) {
        print('[App] ✗ Failed to load profile - token is invalid: $e');
        
        // Token is invalid/expired, clear it and force login
        await sessionManager.clearToken();
        loggedIn = false;
      }
    } else {
      print('[App] No saved token, going to login screen');
    }

    if (mounted) {
      setState(() {
        _sessionLoaded = true;
        _isLoggedIn = loggedIn;
      });
    }
  }

  @override
  void dispose() {
    SessionRefreshManager().stopAutoRefresh();
    _userNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UserProvider(
      notifier: _userNotifier,
      child: MaterialApp(
        title: 'MealSense',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00C853)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        // Show loading screen while checking session
        home: !_sessionLoaded
            ? const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              )
            : (_isLoggedIn ? const DashboardScreen() : const LoginScreen()),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignupScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/dashboard': (_) => const DashboardScreen(),
        },
      ),
    );
  }
}
