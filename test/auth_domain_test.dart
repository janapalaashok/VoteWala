import 'package:flutter_test/flutter_test.dart';
import 'package:votewala/services/firebase_auth_service.dart';

void main() {
  test('Google sign-in runs on votewala.in only on the custom domain', () {
    expect(webAuthDomain('votewala-a2dcd', 'votewala.in'), 'votewala.in');
    expect(webAuthDomain('votewala-a2dcd', 'www.votewala.in'), 'votewala.in');
    expect(webAuthDomain('votewala-a2dcd', 'votewala-a2dcd.web.app'), 'votewala-a2dcd.firebaseapp.com');
    expect(webAuthDomain('votewala-a2dcd', 'localhost'), 'votewala-a2dcd.firebaseapp.com');
  });
}
