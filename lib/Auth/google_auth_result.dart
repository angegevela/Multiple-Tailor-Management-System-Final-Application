import 'package:firebase_auth/firebase_auth.dart';

class GoogleAuthResult {
  final User user;
  final bool isNewUser;

  GoogleAuthResult({required this.user, required this.isNewUser});
}