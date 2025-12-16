import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Only create GoogleSignIn for non-web platforms
  late final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  User? _user;
  bool _isLoading = true;
  String? _idToken;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String get username => _user?.displayName ?? _user?.email ?? '';
  String? get photoUrl => _user?.photoURL;
  String? get email => _user?.email;

  String get baseUrl {
    // For local development, always use localhost:8080
    // In production (Cloud Run), use same origin
    const isProduction = bool.fromEnvironment('dart.vm.product');
    if (isProduction && kIsWeb) {
      return ''; // Same origin in production
    }
    return 'http://localhost:8080';
  }

  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isLoading = false;
      _idToken = null; // Clear cached token on auth change
      notifyListeners();
    });
  }

  /// Get current ID token for API requests
  Future<String?> getIdToken() async {
    if (_user == null) return null;
    // Get fresh token (Firebase caches and refreshes automatically)
    _idToken = await _user!.getIdToken();
    return _idToken;
  }

  /// Attempt to restore session (Firebase handles this automatically)
  Future<void> tryRestoreSession() async {
    // Firebase Auth persists sessions automatically
    // Just wait for the auth state to settle
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoading = false;
    notifyListeners();
  }

  /// Sign in with Google
  Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web flow - use popup
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile flow
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          return 'Sign in cancelled';
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Authentication failed';
    } catch (e) {
      return 'Sign in failed: $e';
    }
  }

  /// Sign out
  Future<void> logout() async {
    await _googleSignIn?.signOut();
    await _auth.signOut();
  }
}
