import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:threadhub_system/Customer/pages/Notification/notification%20process/customer_appointaccept.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';
import 'package:threadhub_system/Customer/pages/product%20status/receipt/appointmentdata.dart';
import 'package:threadhub_system/Customer/pages/product%20status/receipt/tailor_display.dart';
import 'package:threadhub_system/Customer/signup/customer_homepage.dart';
import 'package:threadhub_system/main.dart';

class CustomerNotification extends StatefulWidget {
  final String customerId;

  const CustomerNotification({super.key, required this.customerId});

  @override
  State<CustomerNotification> createState() => _CustomerNotificationState();
}

class _CustomerNotificationState extends State<CustomerNotification> {
  Future<void> markAsRead(AppNotification notif) async {
    final userId = widget.customerId;
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notif.id)
        .update({
          'readBy': FieldValue.arrayUnion([userId]),
        });
  }

  Future<void> markAllAsRead(List<AppNotification> notifs) async {
    final batch = FirebaseFirestore.instance.batch();
    final userId = widget.customerId;
    for (var n in notifs) {
      if (!n.readBy.contains(userId)) {
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
    final fontSize = context.watch<FontProvider>().fontSize;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF262633),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const CustomerHomePage()),
              (route) => false,
            );
          },
        ),
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
        stream: getNotifications(widget.customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          final hasUnread = notifications.any(
            (notif) => !notif.readBy.contains(widget.customerId),
          );

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
                        onTap: () => markAllAsRead(notifications),
                        child: Text(
                          "Mark all as read",
                          style: GoogleFonts.montserrat(
                            fontSize: fontSize,
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
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const BlackDivider(),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isRead = notif.readBy.contains(widget.customerId);

                    return NotificationTile(
                      notif: notif,
                      fontSize: fontSize,
                      isRead: isRead,
                      onTap: () async {
                        if (!isRead) {
                          await markAsRead(notif);
                        }

                        switch (notif.title) {
                          case "Appointment Declined":
                            final snap = await FirebaseFirestore.instance
                                .collection("Appointment Forms")
                                .doc(notif.appointmentId)
                                .get();
                            if (!snap.exists) return;
                            final appointmentData = AppointmentData.fromMap(
                              snap.data()!,
                            );
                            navigatorKey.currentState?.push(
                              MaterialPageRoute(
                                builder: (_) => TailorResultsPage(
                                  tailors: [],
                                  data: appointmentData,
                                  customerId: widget.customerId,
                                  customerLocation: GeoPoint(0, 0),
                                ),
                              ),
                            );
                            break;

                          case "Tailor responded to your request":
                            navigatorKey.currentState?.push(
                              MaterialPageRoute(
                                builder: (_) => UpdatedAppointmentPage(
                                  appointmentId: notif.appointmentId,
                                  customerId: widget.customerId,
                                ),
                              ),
                            );
                            break;

                          case "Request Sent":
                          case "Update from Tailor":
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(notif.title),
                                content: Text(notif.body),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK"),
                                  ),
                                ],
                              ),
                            );
                            break;

                          default:
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Notification read: ${notif.title}",
                                ),
                              ),
                            );
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
  final AppNotification notif;
  final double fontSize;
  final VoidCallback? onTap;
  final bool isRead;

  const NotificationTile({
    super.key,
    required this.notif,
    required this.fontSize,
    this.onTap,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? Colors.blue[100] : Colors.yellow[100],
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
                    notif.title,
                    style: GoogleFonts.notoSerifMyanmar(
                      fontSize: fontSize,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: GoogleFonts.montserrat(
                      fontSize: fontSize,
                      color: Colors.black87,
                    ),
                  ),
                  if (notif.timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat(
                          'h:mm a - MMMM d, yyyy',
                        ).format(notif.timestamp!.toLocal()),
                        style: GoogleFonts.montserrat(
                          fontSize: fontSize - 2,
                          color: Colors.grey[600],
                        ),
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
  Widget build(BuildContext context) =>
      Container(height: 1.5, color: Colors.black);
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime? timestamp;
  final String appointmentId;
  final List<dynamic> readBy;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.timestamp,
    required this.appointmentId,
    this.readBy = const [],
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
    );
  }
}

Stream<List<AppNotification>> getNotifications(String customerId) {
  final stream1 = FirebaseFirestore.instance
      .collection('notifications')
      .where('toCustomerId', isEqualTo: customerId)
      .snapshots();

  final stream2 = FirebaseFirestore.instance
      .collection('notifications')
      .where('to', isEqualTo: customerId)
      .snapshots();

  return Rx.combineLatest2(stream1, stream2, (
    QuerySnapshot snap1,
    QuerySnapshot snap2,
  ) {
    final allDocs = [...snap1.docs, ...snap2.docs];
    allDocs.sort((a, b) {
      final aTime =
          (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      final bTime =
          (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      return bTime!.compareTo(aTime!);
    });

    return allDocs
        .map(
          (doc) => AppNotification.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  });
}
