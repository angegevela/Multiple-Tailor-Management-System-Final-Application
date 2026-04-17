import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_auth_result.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com",
  );

  /// Google Sign-In with Firebase + detects new users
  Future<GoogleAuthResult?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("Google sign-in cancelled");
        return null;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (user == null) return null;

      /// OPTIONAL: check Firestore profile
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists && isNewUser) {
        // New user → needs manual signup
        return GoogleAuthResult(user: user, isNewUser: true);
      }

      return GoogleAuthResult(user: user, isNewUser: false);
    } catch (e, st) {
      print("Google sign-in error: $e");
      print(st);
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
