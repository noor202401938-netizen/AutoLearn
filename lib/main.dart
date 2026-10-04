// lib/main.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'theme/app_theme.dart';
import 'screens/role_based_wrapper.dart';
import 'screens/reset_password_page.dart';
import 'widgets/notebook/notebook.dart';
import 'utils/preference_notifier.dart';
import 'backend/api_client.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
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
  final PreferenceNotifier _preferenceNotifier = PreferenceNotifier.instance;

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadPreferences() => _preferenceNotifier.load();

  @override
  Widget build(BuildContext context) {
    final themeMode = _preferenceNotifier.themeMode;
    final fontSizeMultiplier = _preferenceNotifier.fontSizeMultiplier;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(fontSizeMultiplier),
        disableAnimations: _preferenceNotifier.reduceMotion,
      ),
      child: MaterialApp(
        title: 'AutoLearn',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Title(
          title: 'AutoLearn',
          color: AppTheme.primary,
          child: const SplashScreen(),
        ), // Start with splash screen
        routes: {
          '/welcome': (context) => Title(
                title: 'Welcome - AutoLearn',
                color: AppTheme.primary,
                child: const WelcomePage(),
              ),
          '/login': (context) => Title(
                title: 'Login - AutoLearn',
                color: AppTheme.primary,
                child: const LoginPage(),
              ),
          '/signup': (context) => Title(
                title: 'Sign Up - AutoLearn',
                color: AppTheme.primary,
                child: const SignupPage(),
              ),
          '/home': (context) => Title(
                title: 'Dashboard - AutoLearn',
                color: AppTheme.primary,
                child: const RoleBasedWrapper(),
              ),
        },
      ),
    );
  }
}

// Splash Screen to decide where to navigate
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstLaunch());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    // Password-reset links land here: /reset-password?token=...
    final resetToken = Uri.base.queryParameters['token'];
    if (Uri.base.path.endsWith('/reset-password') && resetToken != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResetPasswordPage(token: resetToken)));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    final isLoggedIn = await ApiClient.instance.getToken() != null;

    if (!mounted) return;
    if (isFirstLaunch) {
      Navigator.pushReplacementNamed(context, '/welcome');
    } else if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(children: [
        const GraphPaper(),
        Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const NotebookMark(size: 120),
                const SizedBox(height: 20),
                Text('AutoLearn', style: theme.textTheme.displayMedium),
                const SizedBox(height: 4),
                const MarginNote('learn anything, in your own notes', tilt: 0, handwritten: true),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
