import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

// class AppNotification {
//   final String id;
//   final String title;
//   final String subtitle;
//   final List<String> recipientIds;
//   final List<String> readBy;
//   final DateTime timestamp;

//   AppNotification({
//     required this.id,
//     required this.title,
//     required this.subtitle,
//     required this.recipientIds,
//     required this.readBy,
//     required this.timestamp,
//   });

//   factory AppNotification.fromFirestore(Map<String, dynamic> data, String id) {
//     return AppNotification(
//       id: id,
//       title: data['title'] ?? '',
//       subtitle: data['body'] ?? '',
//       recipientIds: List<String>.from(data['recipientIds'] ?? []),
//       readBy: List<String>.from(data['readBy'] ?? []),
//       timestamp: (data['timestamp'] is Timestamp)
//           ? (data['timestamp'] as Timestamp).toDate()
//           : DateTime.now(),
//     );
//   }
// }
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime? timestamp;
  final String appointmentId;
  final List<dynamic> readBy;
  final bool actionRequired;
  final String tailorId;
  final String actionRequiredTailorId;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.timestamp,
    required this.appointmentId,
    this.readBy = const [],
    this.actionRequired = false,
    this.tailorId = '',
    this.actionRequiredTailorId = '',
  });

  factory AppNotification.fromFirestore(Map<String, dynamic> data, String id) {
    final toUserId = data['toCustomerId'] ?? data['to'] ?? '';
    return AppNotification(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      appointmentId: data['appointmentId'] ?? '',
      readBy: data.containsKey('readBy')
          ? List.from(data['readBy'])
          : (data['read'] == true ? [toUserId] : []),
      actionRequired: data['actionRequired'] ?? false,
      tailorId: data['tailorId'] ?? '',
      actionRequiredTailorId: data['actionRequiredTailorId'] ?? '',
    );
  }
}

class NotificationService {
  static Future<void> sendNotification({
    required String title,
    required String body,
    required List<String> recipientIds,
    String? customerName,
    String? garmentSpec,
    String? service,
    String? customization,
    String? address,
    String? phone,
    String? email,
    String? message,
    String? price,
    String? priority,
    String? appointmentDate,
    String? neededBy,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'body': body,
      'recipientIds': recipientIds,
      'readBy': [],
      'timestamp': FieldValue.serverTimestamp(),
      'customerName': customerName,
      'garmentSpec': garmentSpec,
      'service': service,
      'customization': customization,
      'address': address,
      'phone': phone,
      'email': email,
      'message': message,
      'price': price,
      'priority': priority,
      'appointmentDate': appointmentDate,
      'neededBy': neededBy,
    });
  }
}

// Stream<List<AppNotification>> getNotifications(String userId) {
//   return FirebaseFirestore.instance
//       .collection('notifications')
//       .where('recipientIds', arrayContains: userId)
//       .orderBy('timestamp', descending: true)
//       .snapshots()
//       .map((snapshot) {
//         print("Notifications snapshot size: ${snapshot.docs.length}");
//         for (var d in snapshot.docs) {
//           print("Notification doc: ${d.data()}");
//         }
//         return snapshot.docs.map((doc) {
//           return AppNotification.fromFirestore(doc.data(), doc.id);
//         }).toList();
//       });
// }

Stream<List<AppNotification>> getNotifications(String customerId) {
  final stream1 = FirebaseFirestore.instance
      .collection('notifications')
      .where('recipientIds', arrayContains: customerId)
      .snapshots();

  final stream2 = FirebaseFirestore.instance
      .collection('notifications')
      .where('toCustomerId', isEqualTo: customerId)
      .snapshots();

  return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<AppNotification>>(
    stream1,
    stream2,
    (snap1, snap2) {
      final allDocs = [...snap1.docs, ...snap2.docs];

      allDocs.sort((a, b) {
        final aTime =
            (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
        final bTime =
            (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return allDocs
          .map(
            (doc) => AppNotification.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    },
  );
}

Future<void> markAsRead(String notificationId, String userId) async {
  await FirebaseFirestore.instance
      .collection('notifications')
      .doc(notificationId)
      .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
}
