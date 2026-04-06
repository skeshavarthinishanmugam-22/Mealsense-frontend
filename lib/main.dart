import 'package:flutter/material.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize session manager to load saved token
  await SessionManager().initialize();
  runApp(const MealSenseApp());
}

class MealSenseApp extends StatefulWidget {
  const MealSenseApp({super.key});

  @override
  State<MealSenseApp> createState() => _MealSenseAppState();
}

class _MealSenseAppState extends State<MealSenseApp> {
  final _userNotifier = UserNotifier();

  @override
  void initState() {
    super.initState();
    // Load user from saved session if exists
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final sessionManager = SessionManager();
    if (sessionManager.isLoggedIn() && !sessionManager.isTokenExpired()) {
      // User has valid token, try to load profile
      // This would be called from your UserProvider
    }
  }

  @override
  void dispose() {
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
        // Check if user is logged in, otherwise go to login screen
        initialRoute: SessionManager().isLoggedIn() 
          ? (SessionManager().isTokenExpired() ? '/login' : '/dashboard')
          : '/login',
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
