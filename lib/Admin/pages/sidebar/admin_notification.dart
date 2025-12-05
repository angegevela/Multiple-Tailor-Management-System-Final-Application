import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:threadhub_system/Admin/pages/sidebar/admin_reportdetails/admincard_report.dart';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  Future<void> markAsRead(String id) async {
    await FirebaseFirestore.instance.collection('notifications').doc(id).update(
      {
        'readBy': FieldValue.arrayUnion(['admin']),
      },
    );
  }

  Future<void> markAllAsRead(List<QueryDocumentSnapshot> notifs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in notifs) {
      final data = doc.data() as Map<String, dynamic>;
      if (!(data['readBy'] ?? []).contains('admin')) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion(['admin']),
        });
      }
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF262633),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const SizedBox(width: 150),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toAdmin', isEqualTo: true)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          final hasUnread = notifications.any((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return !(data['readBy'] ?? []).contains('admin');
          });

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
                            fontSize: 14,
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
                  separatorBuilder: (_, __) =>
                      Container(height: 1, color: Colors.black),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final data = notif.data() as Map<String, dynamic>;
                    final isRead = (data['readBy'] ?? []).contains('admin');

                    return InkWell(
                      onTap: () async {
                        if (!isRead) await markAsRead(notif.id);

                        final reportId = data['reportId'];

                        if (reportId != null &&
                            reportId.toString().isNotEmpty) {
                          try {
                            final doc = await FirebaseFirestore.instance
                                .collection('Reports')
                                .doc(reportId)
                                .get();

                            if (doc.exists) {
                              final reportData =
                                  doc.data() as Map<String, dynamic>;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReportDetailPage(report: reportData),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'This report no longer exists.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error opening report: $e'),
                              ),
                            );
                          }
                        } else {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(data['title'] ?? 'Notification'),
                              content: Text(data['body'] ?? ''),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        }
                      },

                      child: Container(
                        color: isRead ? Colors.blue[100] : Colors.yellow[100],
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isRead
                                  ? Icons.notifications_none
                                  : Icons.notifications_active,
                              color: Colors.black87,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['title'] ?? '',
                                    style: GoogleFonts.notoSerifMyanmar(
                                      fontSize: 16,
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['body'] ?? '',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (data['timestamp'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        DateFormat(
                                          'h:mm a - MMMM d, yyyy',
                                        ).format(
                                          (data['timestamp'] as Timestamp)
                                              .toDate()
                                              .toLocal(),
                                        ),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
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
