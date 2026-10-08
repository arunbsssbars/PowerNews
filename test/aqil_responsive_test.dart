import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:power_news/providers/news_provider.dart';
import 'package:power_news/services/auth_service.dart';
import 'package:power_news/services/database_service.dart';
import 'package:power_news/screens/login_signup_screen.dart';
import 'package:power_news/screens/email_verification_screen.dart';
import 'package:power_news/screens/home_screen.dart';
import 'package:power_news/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseService().close(deleteDb: false);
  });

  const viewports = <String, Size>{
    'Compact Mobile (320x568)': Size(320, 568),
    'Standard Mobile (393x852)': Size(393, 852),
    'Large Mobile (412x915)': Size(412, 915),
    'Tablet Portrait (800x1280)': Size(800, 1280),
    'Desktop Landscape (1280x800)': Size(1280, 800),
  };

  group('AQIL Multi-Viewport Responsive Verification', () {
    for (final entry in viewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('HomeScreen renders with zero overflow on $name at 1.0x and 1.5x font scale',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        SharedPreferences.setMockInitialValues({
          'has_seen_onboarding': true,
          'auth_user_id': 'aqil_test_id',
          'auth_user_email': 'aqil@powernews.com',
          'auth_user_name': 'AQIL Auditor',
          'auth_user_verified': true,
        });

        final authService = AuthService();
        await authService.init();

        for (final scale in [1.0, 1.5]) {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => NewsProvider()),
                ChangeNotifierProvider.value(value: authService),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const HomeScreen(),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull,
              reason: 'Zero layout overflow or crash expected on $name with font scale $scale');
        }
      });

      testWidgets('LoginSignUpScreen renders cleanly on $name at 1.0x and 1.5x font scale',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final authService = AuthService();

        for (final scale in [1.0, 1.5]) {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: authService),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const LoginSignUpScreen(),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull,
              reason: 'Zero overflow on Login screen on $name with scale $scale');
        }
      });
    }

    testWidgets('EmailVerificationScreen renders without overflow', (WidgetTester tester) async {
      final authService = AuthService();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authService),
          ],
          child: const MaterialApp(
            home: EmailVerificationScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
