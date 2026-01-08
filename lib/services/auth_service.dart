import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'database_service.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      NotificationService().logout(); // Ensure OneSignal logs out too
    } else {
      final role = await _db.getUserRole(firebaseUser.uid);
      _currentUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        role: role,
      );
      // Ensure OneSignal logs in when Firebase auth changes
      NotificationService().handleLogin(firebaseUser);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An error occurred";
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> signUp(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        // Auto-assign admin role if email starts with 'admin' (Demo logic)
        String role = email.toLowerCase().startsWith('admin')
            ? 'Admin'
            : 'User';
        await _db.createUserProfile(result.user!.uid, email, role);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An error occurred: $e";
    }
  }

  // Admin creating user (simpler version for client-side without cloud functions)
  // This will temporarily sign out the admin if used directly on 'createUserWithEmailAndPassword'
  // So we use a secondary app instance.
  Future<String?> createNewUser(
    String email,
    String password,
    String role, {
    String? fullName,
  }) async {
    try {
      // Using a temporary secondary app to create user without logging out current user
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'tempApp',
        options: Firebase.app().options,
      );

      UserCredential result = await FirebaseAuth.instanceFor(
        app: tempApp,
      ).createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        await _db.createUserProfile(
          result.user!.uid,
          email,
          role,
          fullName: fullName,
        );
        await result.user!.updateDisplayName(fullName ?? email.split('@')[0]);
      }

      await tempApp.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An error occurred: $e";
    }
  }
}
