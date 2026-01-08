import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await NotificationService().init();
  } catch (e) {
    debugPrint("Init error: $e");
  }

  runApp(const LeadsManagerApp());
}

class LeadsManagerApp extends StatelessWidget {
  const LeadsManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: MaterialApp(
        title: 'Leads Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AuthWrapper(),
        routes: {
          '/customers': (context) => const MainScreen(initialIndex: 1),
          '/labels': (context) => const MainScreen(initialIndex: 2),
          '/reminders': (context) => const MainScreen(initialIndex: 3),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  static bool _hasShownSplash = false;
  late bool _showSplash;

  @override
  void initState() {
    super.initState();
    _showSplash = !_hasShownSplash;
    if (_showSplash) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showSplash = false;
            _hasShownSplash = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Show splash if logically forced OR if auth is still loading
    if (_showSplash || authService.isLoading) {
      return const SplashScreen();
    }

    if (authService.currentUser == null) {
      return const LoginScreen();
    }

    return const MainScreen();
  }
}
