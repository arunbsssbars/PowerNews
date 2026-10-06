import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/news_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_signup_screen.dart';
import 'theme/app_theme.dart';
import 'screens/email_verification_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] Caught during runtime: ${details.exception}');
  };

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('[DotEnv] Notice: .env file could not be loaded ($e). Using default AppConfig.');
  }

  bool hasSeenOnboarding = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  } catch (e) {
    debugPrint('[Prefs] Failed reading SharedPreferences: $e');
  }

  final authService = AuthService();
  try {
    await authService.init();
  } catch (e) {
    debugPrint('[AuthService] Init error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider.value(value: authService),
      ],
      child: PowerNewsApp(showOnboarding: !hasSeenOnboarding),
    ),
  );
}

class PowerNewsApp extends StatelessWidget {
  final bool showOnboarding;

  const PowerNewsApp({
    super.key,
    this.showOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();

    

    return MaterialApp(
      title: 'PowerNews',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: newsProvider.themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child!,
        );
      },
      home: showOnboarding ? const OnboardingScreen() : const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.isAuthenticated) {
      return const LoginSignUpScreen();
    }
    if (!auth.currentUser!.isEmailVerified) {
      return const EmailVerificationScreen();
    }
    return const HomeScreen();
  }
}
