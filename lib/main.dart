// lib/main.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/welcome_screen.dart';
import 'screens/user_info_screen.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'theme.dart';
import 'screens/role_based_wrapper.dart';
import 'repository/user_preferences_repository.dart';
import 'utils/preference_notifier.dart';
import 'backend/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables
  await dotenv.load(fileName: '.env');

  runApp(const MyApp(
    initialRoute: '',
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required String initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final UserPreferencesRepository _preferencesRepository =
      UserPreferencesRepository();
  final PreferenceNotifier _preferenceNotifier = PreferenceNotifier.instance;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    // We will handle auth state changes via our custom ApiClient later
    _loadPreferences();
    // Listen to preference changes for real-time updates
    _preferenceNotifier.addListener(_onPreferencesChanged);
  }

  @override
  void dispose() {
    _preferenceNotifier.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void _onPreferencesChanged() {
    setState(() {
      // State will be updated from PreferenceNotifier
    });
  }

  Future<void> _loadPreferences() async {
      try {
        final prefs = await _preferencesRepository.getUserPreferences('local_preferences');
        _preferenceNotifier.loadPreferences(
          theme: prefs['theme'] as String? ?? 'system',
          fontSize: prefs['fontSize'] as String? ?? 'normal',
          highContrast: prefs['highContrast'] as bool? ?? false,
          reduceMotion: prefs['reduceMotion'] as bool? ?? false,
        );
      } catch (e) {
        print('Error loading preferences: $e');
      }
    }

  @override
  Widget build(BuildContext context) {
    final themeMode = _preferenceNotifier.themeMode;
    final fontSizeMultiplier = _preferenceNotifier.fontSizeMultiplier;
    final highContrast = _preferenceNotifier.highContrast;

    // Build theme with high contrast support
    final lightTheme = _buildTheme(Brightness.light, highContrast);
    final darkTheme = _buildTheme(Brightness.dark, highContrast);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: fontSizeMultiplier,
      ),
      child: MaterialApp(
        title: 'AI Tutor',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const SplashScreen(), // Start with splash screen
        routes: {
          '/welcome': (context) => const WelcomePage(),
          '/userinfo': (context) => const UserInfoPage(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/home': (context) => const RoleBasedWrapper(),
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness, bool highContrast) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4169E1), // Royal Blue
        brightness: brightness,
      ),
      useMaterial3: true,
    );

    if (highContrast) {
      // Apply high contrast modifications
      return baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: brightness == Brightness.light
              ? Colors.blue.shade900
              : Colors.blue.shade100,
          secondary: brightness == Brightness.light
              ? Colors.teal.shade900
              : Colors.teal.shade100,
          surface: brightness == Brightness.light ? Colors.white : Colors.black,
          onSurface:
              brightness == Brightness.light ? Colors.black : Colors.white,
        ),
        scaffoldBackgroundColor:
            brightness == Brightness.light ? Colors.white : Colors.black,
        cardColor: brightness == Brightness.light
            ? Colors.grey.shade100
            : Colors.grey.shade900,
      );
    }

    return baseTheme;
  }
}

// Splash Screen to decide where to navigate
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    await Future.delayed(
        const Duration(seconds: 2)); // Show splash for 2 seconds

    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    final hasCompletedUserInfo = prefs.getBool('hasCompletedUserInfo') ?? false;

    if (!mounted) return;

    // Check if user is already logged in via stored JWT token
    final token = await ApiClient.instance.getToken();
    final bool isLoggedIn = token != null;

    if (isFirstLaunch) {
      // First time opening the app - show welcome screen
      Navigator.pushReplacementNamed(context, '/welcome');
    } else if (!hasCompletedUserInfo) {
      // User has seen welcome but not completed user info
      Navigator.pushReplacementNamed(context, '/userinfo');
    } else if (isLoggedIn) {
      // User is logged in and completed all onboarding - go to home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // User completed onboarding but not logged in - go to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4169E1), // Royal Blue
              Color(0xFF1E3A8A), // Darker Blue
              Color(0xFF0F172A), // Very Dark Blue
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 80,
                  color: Color(0xFF4169E1),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'AI Tutor',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your Personal Learning Assistant',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
