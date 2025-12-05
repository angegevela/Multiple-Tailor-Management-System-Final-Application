import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_notificationprocess/tailor_pickcustomer.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_fontprovider.dart';
import 'package:threadhub_system/Tailor/pages/tailorhomepage.dart';

// Future<void> createNotificationForCustomer({
//   required String toCustomerId,
//   required String title,
//   required String body,
//   String appointmentId = '',
// }) async {
//   await FirebaseFirestore.instance.collection('notifications').add({
//     'title': title,
//     'body': body,
//     'appointmentId': appointmentId,
//     'toCustomerId': toCustomerId,
//     'recipientType': 'customer',
//     'recipientId': toCustomerId,
//     'timestamp': FieldValue.serverTimestamp(),
//     'readBy': <String>[],
//   });
// }
Future<void> createNotificationForTailor({
  required String toTailorId,
  required String title,
  required String body,
  String appointmentId = '',
}) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'title': title,
    'body': body,
    'appointmentId': appointmentId,
    'recipientType': 'tailor',
    'recipientId': toTailorId,
    'timestamp': FieldValue.serverTimestamp(),
    'readBy': <String>[], 
  });
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String appointmentId;
  final String customerId;
  final List<dynamic> recipientIds;
  final List<dynamic> readBy;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.appointmentId,
    required this.customerId,
    required this.recipientIds,
    required this.readBy,
    required this.timestamp,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      body: data['body'] ?? data['message'] ?? '',
      appointmentId: data['appointmentId'] ?? '',
      customerId: data['customerId'] ?? '',
      recipientIds: data.containsKey('recipientIds')
          ? List.from(data['recipientIds'])
          : data.containsKey('recipientId')
          ? [data['recipientId']]
          : [],
      readBy: List.from(data['readBy'] ?? []),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isReadByCurrentUser {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return readBy.contains(userId);
  }
}

Stream<List<AppNotification>> getNotifications(String tailorId) {
  final newNotifStream = FirebaseFirestore.instance
      .collection('notifications')
      .where('recipientType', isEqualTo: 'tailor')
      .where('recipientId', isEqualTo: tailorId)
      .snapshots();

  final oldNotifStream = FirebaseFirestore.instance
      .collection('notifications')
      .where('toTailorId', isEqualTo: tailorId)
      .snapshots();

  return Rx.combineLatest2(newNotifStream, oldNotifStream, (
    QuerySnapshot newSnap,
    QuerySnapshot oldSnap,
  ) {
    final allDocs = [...newSnap.docs, ...oldSnap.docs];
    allDocs.sort((a, b) {
      final aTime =
          (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      final bTime =
          (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      return bTime!.compareTo(aTime!);
    });
    return allDocs.map((doc) => AppNotification.fromDoc(doc)).toList();
  });
}

Future<void> markAsRead(String notifId, String userId) async {
  await FirebaseFirestore.instance
      .collection('notifications')
      .doc(notifId)
      .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
}

class TailorNotificationPage extends StatefulWidget {
  final String tailorId;

  const TailorNotificationPage({super.key, required this.tailorId});

  @override
  TailorNotificationPageState createState() => TailorNotificationPageState();
}

class TailorNotificationPageState extends State<TailorNotificationPage> {
  Future<void> markAllAsRead(List<AppNotification> notifs) async {
    final batch = FirebaseFirestore.instance.batch();
    final userId = widget.tailorId;
    for (var n in notifs) {
      if (!n.isReadByCurrentUser) {
        batch.update(
          FirebaseFirestore.instance.collection('notifications').doc(n.id),
          {
            'readBy': FieldValue.arrayUnion([userId]),
          },
        );
      }
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final tailorFontSize = context.watch<TailorFontprovider>().fontSize;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF262633),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.chauPhilomeneOne(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFD9D9D9),
      body: StreamBuilder<List<AppNotification>>(
        stream: getNotifications(widget.tailorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifs = snapshot.data ?? [];

          if (notifs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final hasUnread = notifs.any((n) => !n.isReadByCurrentUser);

          return Column(
            children: [
              if (hasUnread)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () async => await markAllAsRead(notifs),
                        child: Text(
                          "Mark all as read",
                          style: GoogleFonts.montserrat(
                            fontSize: tailorFontSize,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView.separated(
                  itemCount: notifs.length,
                  separatorBuilder: (_, __) => const BlackDivider(),
                  itemBuilder: (context, index) {
                    final notif = notifs[index];
                    final isRead = notif.isReadByCurrentUser;

                    final formattedTime = DateFormat(
                      'h:mm a - MMMM d, yyyy',
                    ).format(notif.timestamp.toLocal());

                    return NotificationTile(
                      title: notif.title,
                      subtitle: '${notif.body}\n$formattedTime',
                      tailorFontSize: tailorFontSize,
                      isRead: isRead,
                      onTap: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );
                        try {
                          await markAsRead(notif.id, widget.tailorId);
                          Navigator.of(context).pop();
                          switch (notif.title) {
                            case "Customer Accepted Appointment":
                              final doc = await FirebaseFirestore.instance
                                  .collection('Appointment Forms')
                                  .doc(notif.appointmentId)
                                  .get();
                              final data = doc.data();
                              if (data == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Appointment not found.'),
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TailorHomePage(showAccepted: true),
                                ),
                              );
                              break;

                            case "Waiting for Customer Response":
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Waiting for customer response.',
                                  ),
                                ),
                              );
                              break;

                            case "New Appointment Request":
                              final doc = await FirebaseFirestore.instance
                                  .collection('Appointment Forms')
                                  .doc(notif.appointmentId)
                                  .get();
                              final data = doc.data();
                              if (data == null) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TailorPickCustomer(
                                    appointmentData: data,
                                    customers: [data],
                                  ),
                                ),
                              );
                              break;

                            default:
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No navigation assigned.'),
                                ),
                              );
                          }
                        } catch (e) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isRead;
  final VoidCallback? onTap;
  final double tailorFontSize;

  const NotificationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tailorFontSize,
    required this.isRead,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? const Color(0xFFC6D7E5) : Colors.amber[100],
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isRead ? Icons.notifications_none : Icons.notifications_active,
              color: Colors.black87,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.notoSerifMyanmar(
                      fontSize: tailorFontSize,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: tailorFontSize - 1,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlackDivider extends StatelessWidget {
  const BlackDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1.5, color: Colors.black);
  }
}
