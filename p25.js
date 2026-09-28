const fs = require('fs');
let mainCode = fs.readFileSync('lib/main.dart', 'utf8');
const imports = `import 'screens/email_verification_screen.dart';\nimport 'services/auth_service.dart';`;
mainCode = mainCode.replace(/import 'services\/auth_service\.dart';/, imports);

const wrapperCode = `
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
`;
mainCode += wrapperCode;

mainCode = mainCode.replace(/Widget initialScreen;[\s\S]*?\} else \{[\s\S]*?initialScreen = const HomeScreen\(\);\s*\}/, '');
mainCode = mainCode.replace(/home: initialScreen,/, 'home: showOnboarding ? const OnboardingScreen() : const AuthWrapper(),');

fs.writeFileSync('lib/main.dart', mainCode);
console.log('Main patched');
