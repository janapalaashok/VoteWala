import '../state/app_state.dart';

/// Why sign-in failed, mapped to a message key in l10n/strings.dart.
class AuthFailure implements Exception {
  const AuthFailure(this.messageKey, [this.detail = '']);

  final String messageKey;
  final String detail;

  @override
  String toString() => 'AuthFailure($messageKey) $detail';
}

/// Voter authentication. [FirebaseAuthService] (lib/services/
/// firebase_auth_service.dart) is used in the apps; [DemoAuthService] backs
/// widget tests.
abstract class AuthService {
  /// Whether "Continue with Google" is offered on this platform.
  bool get supportsGoogle;

  /// Whether mobile OTP sign-in is offered.
  bool get supportsPhone;

  /// The signed-in voter restored from the previous session, if any.
  Future<AppUser?> restore();

  Future<AppUser> signInWithGoogle();

  /// Sends an OTP to the Indian mobile number [phone] (10 digits). Returns
  /// the user when Android verifies the number automatically.
  Future<AppUser?> sendOtp(String phone);

  Future<AppUser> verifyOtp(String phone, String code);

  Future<void> signOut();

  /// Firebase ID token for database requests (null when signed out).
  Future<String?> idToken();
}

class DemoAuthService implements AuthService {
  const DemoAuthService();

  static const _delay = Duration(milliseconds: 300);

  @override
  bool get supportsGoogle => true;

  @override
  bool get supportsPhone => true;

  @override
  Future<AppUser?> restore() async => null;

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future<void>.delayed(_delay);
    return const AppUser(uid: 'demo-google', name: 'VoteWala User', email: 'user@gmail.com', provider: 'google');
  }

  @override
  Future<AppUser?> sendOtp(String phone) async {
    await Future<void>.delayed(_delay);
    return null;
  }

  @override
  Future<AppUser> verifyOtp(String phone, String code) async {
    await Future<void>.delayed(_delay);
    if (!RegExp(r'^\d{6}$').hasMatch(code)) throw const AuthFailure('invalidOtp');
    return AppUser(uid: 'demo-$phone', name: 'Voter', phone: '+91 $phone', provider: 'phone');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> idToken() async => null;
}

/// Used when Firebase could not start (e.g. no connection on first launch):
/// results still load, signing in reports a network error.
class UnavailableAuthService implements AuthService {
  const UnavailableAuthService();

  static Never _fail() => throw const AuthFailure('networkError');

  @override
  bool get supportsGoogle => true;

  @override
  bool get supportsPhone => false;

  @override
  Future<AppUser?> restore() async => null;

  @override
  Future<AppUser> signInWithGoogle() async => _fail();

  @override
  Future<AppUser?> sendOtp(String phone) async => _fail();

  @override
  Future<AppUser> verifyOtp(String phone, String code) async => _fail();

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> idToken() async => null;
}

AuthService authService = const DemoAuthService();
