import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isFirebaseInitialized = false;
  String firebaseInitError = '';

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
  } catch (e) {
    firebaseInitError = e.toString();
    debugPrint("Init error: $e");
  }

  // Not awaited to avoid blocking the UI thread
  NotificationService().init();

  runApp(BookingApp(
    isFirebaseInitialized: isFirebaseInitialized,
    firebaseInitError: firebaseInitError,
  ));
}

class BookingApp extends StatelessWidget {
  final bool isFirebaseInitialized;
  final String firebaseInitError;

  const BookingApp({
    super.key,
    this.isFirebaseInitialized = true,
    this.firebaseInitError = '',
  });

  @override
  Widget build(BuildContext context) {
    if (!isFirebaseInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "App Initialization Failed",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Please check your connection and try again.\n\nError Details:\n$firebaseInitError",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: MaterialApp(
        title: 'Booking App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AuthWrapper(),
        routes: {
          '/customers': (context) => const MainScreen(initialIndex: 1),
          '/services': (context) => const MainScreen(initialIndex: 2),
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
