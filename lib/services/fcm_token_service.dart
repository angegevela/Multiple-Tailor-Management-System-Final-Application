import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMTokenService {
  static Future<void> saveTokenToFirestore(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('Users').doc(userId).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
        print("✅ FCM token saved for $userId: $token");
      }
    } catch (e) {
      print("❌ Error saving FCM token: $e");
    }
  }

  static Future<void> listenToTokenRefresh(String userId) async {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': newToken,
      });
      print("🔁 Token refreshed for $userId: $newToken");
    });
  }
}
