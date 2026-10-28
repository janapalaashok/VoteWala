import '../state/app_state.dart';

/// Authentication boundary. [DemoAuthService] lets the app run end to end
/// without a backend; swap in a Firebase Auth (Google + phone OTP)
/// implementation for production.
abstract class AuthService {
  Future<AppUser> signInWithGoogle();
  Future<void> sendOtp(String phone);
  Future<AppUser> verifyOtp(String phone, String code);
}

class DemoAuthService implements AuthService {
  const DemoAuthService();

  static const _delay = Duration(milliseconds: 700);

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future<void>.delayed(_delay);
    return const AppUser(name: 'VoteWala User', email: 'user@gmail.com', provider: 'google');
  }

  @override
  Future<void> sendOtp(String phone) => Future<void>.delayed(_delay);

  @override
  Future<AppUser> verifyOtp(String phone, String code) async {
    await Future<void>.delayed(_delay);
    if (!RegExp(r'^\d{6}$').hasMatch(code)) throw const FormatException('invalid-otp');
    return AppUser(name: 'Voter', phone: '+91 $phone', provider: 'phone');
  }
}

AuthService authService = const DemoAuthService();
