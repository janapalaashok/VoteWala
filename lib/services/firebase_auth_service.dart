import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_rest.dart';
import '../state/app_state.dart';
import 'auth_service.dart';

/// Firebase project options for the apps (from the Firebase console; these
/// identifiers are public, access is controlled by the security rules).
FirebaseOptions firebaseOptions(FirebaseSettings s) => kIsWeb
    ? FirebaseOptions(
        apiKey: s.apiKey,
        appId: const String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: '1:596383314349:web:719240a1d80d3b14097124'),
        messagingSenderId: '596383314349',
        projectId: s.projectId,
        authDomain: '${s.projectId}.firebaseapp.com',
        storageBucket: s.storageBucket,
      )
    : FirebaseOptions(
        apiKey: const String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: 'AIzaSyBXXnLeDihaqbE4cWeRwFzL5TrKC1w7FTM'),
        appId: const String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '1:596383314349:android:0d2784fb21cd96d2097124'),
        messagingSenderId: '596383314349',
        projectId: s.projectId,
        storageBucket: s.storageBucket,
      );

/// Google sign-in (website and apps) with Firebase Auth. The first sign-in
/// creates the account, later ones log in. Mobile OTP is built in but off
/// until --dart-define=PHONE_LOGIN=true (needs Blaze and Phone sign-in on).
class FirebaseAuthService implements AuthService {
  FirebaseAuthService._();

  static Future<FirebaseAuthService> init(FirebaseSettings settings) async {
    await Firebase.initializeApp(options: firebaseOptions(settings));
    return FirebaseAuthService._();
  }

  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Web: the pending confirmation. Android: the verification id.
  ConfirmationResult? _confirmation;
  String? _verificationId;
  int? _resendToken;

  @override
  bool get supportsGoogle => true;

  @override
  bool get supportsPhone => const bool.fromEnvironment('PHONE_LOGIN');

  static AppUser _toUser(User u) => AppUser(
        uid: u.uid,
        name: u.displayName ?? 'Voter',
        email: u.email,
        phone: u.phoneNumber,
        provider: u.phoneNumber != null ? 'phone' : 'google',
      );

  @override
  Future<AppUser?> restore() async {
    // The web SDK restores the session asynchronously.
    final user = await _auth.authStateChanges().first.timeout(const Duration(seconds: 4), onTimeout: () => _auth.currentUser);
    return user == null ? null : _toUser(user);
  }

  @override
  Future<AppUser> signInWithGoogle() => _guard(() async {
        final provider = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
        // Web: popup. Android/iOS: the system browser's Google sign-in page.
        final cred = kIsWeb ? await _auth.signInWithPopup(provider) : await _auth.signInWithProvider(provider);
        return _toUser(cred.user!);
      });

  @override
  Future<AppUser?> sendOtp(String phone) => _guard(() async {
        final number = '+91$phone';
        if (kIsWeb) {
          // Invisible reCAPTCHA, as Firebase requires on the web.
          _confirmation = await _auth.signInWithPhoneNumber(number);
          return null;
        }
        final done = Completer<AppUser?>();
        await _auth.verifyPhoneNumber(
          phoneNumber: number,
          forceResendingToken: _resendToken,
          verificationCompleted: (credential) async {
            // Android read the SMS itself.
            try {
              final cred = await _auth.signInWithCredential(credential);
              if (!done.isCompleted) done.complete(_toUser(cred.user!));
            } catch (e) {
              if (!done.isCompleted) done.completeError(e);
            }
          },
          verificationFailed: (e) {
            if (!done.isCompleted) done.completeError(e);
          },
          codeSent: (id, resendToken) {
            _verificationId = id;
            _resendToken = resendToken;
            if (!done.isCompleted) done.complete(null);
          },
          codeAutoRetrievalTimeout: (id) => _verificationId = id,
        );
        return done.future;
      });

  @override
  Future<AppUser> verifyOtp(String phone, String code) => _guard(() async {
        final UserCredential cred;
        if (kIsWeb) {
          if (_confirmation == null) throw const AuthFailure('otpExpired');
          cred = await _confirmation!.confirm(code);
        } else {
          if (_verificationId == null) throw const AuthFailure('otpExpired');
          cred = await _auth.signInWithCredential(
              PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: code));
        }
        return _toUser(cred.user!);
      });

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();

  static Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth failed: ${e.code} ${e.message}');
      throw AuthFailure(switch (e.code) {
        'invalid-phone-number' => 'invalidPhone',
        'invalid-verification-code' || 'invalid-credential' => 'invalidOtp',
        'session-expired' || 'code-expired' => 'otpExpired',
        'too-many-requests' || 'quota-exceeded' => 'tooManyAttempts',
        'network-request-failed' => 'networkError',
        'popup-closed-by-user' || 'cancelled-popup-request' => 'signInCancelled',
        _ => 'signInFailed',
      }, '${e.code}: ${e.message}');
    }
  }
}
