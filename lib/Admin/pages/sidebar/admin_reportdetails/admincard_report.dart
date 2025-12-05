import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;
  const ReportDetailPage({super.key, required this.report});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  bool showExtraButtons = false;

  final supabase = Supabase.instance.client;

  String getPublicUrl(String path) {
    return supabase.storage.from('reports_uploads').getPublicUrl(path);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> notifyUser(String userId) async {
    try {
      await _firestore.collection('notifications').add({
        'toCustomerId': userId,
        'title': 'You have been reported',
        'body': 'Another user has submitted a report against you.',
        'userType': 'user',
        'appointmentId': '',
        'createdAt': Timestamp.now(),
        'timestamp': Timestamp.now(),
        'readBy': [],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The reportee user has been notified')),
      );
    } catch (e) {
      debugPrint('Error notifying the user: $e');
    }
  }

  Future<void> disableUser(String userId) async {
    try {
      await _firestore.collection('Users').doc(userId).update({
        'isDisabled': true,
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User account disabled')));
    } catch (e) {
      debugPrint('Error disabling user: $e');
    }
  }

  Future<void> messageUser(String userId, String message) async {
    try {
      await _firestore.collection('messages').add({
        'receiverId': userId,
        'senderId': _auth.currentUser?.uid ?? 'Administrator',
        'content': message,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message sent to user')));
    } catch (e) {}
  }

  Widget buildStorageImage(String url) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 50),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200, minHeight: 100),
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.broken_image, size: 50)),
              );
            },
          ),
        ),
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "No Action Yet":
        return Colors.red;
      case "Pending Approval":
        return Colors.orange;
      case "Completed":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(widget.report["status"] ?? "Unknown");
    final uploadedFiles = List<String>.from(
      widget.report["uploadedFiles"] ?? [],
    );

    debugPrint('Uploaded files for this report: $uploadedFiles');
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF6082B6)),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                height: 50,
                width: 330,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white),
                child: Text(
                  'Information Report',
                  style: GoogleFonts.robotoMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reportee Name
            Text(
              "Reportee Name",
              style: GoogleFonts.robotoMono(fontWeight: FontWeight.w900),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Text(
                widget.report["reporteeName"] ?? "No name",
                style: GoogleFonts.robotoMono(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Respondent Name
            Text(
              "Respondent Name",
              style: GoogleFonts.robotoMono(fontWeight: FontWeight.w900),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Text(
                widget.report["respondentName"] ?? "No respondent",
                style: GoogleFonts.robotoMono(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),

            // Report Description
            Text(
              "Report Description",
              style: GoogleFonts.robotoMono(fontWeight: FontWeight.w900),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Text(
                widget.report["reportDescription"] ?? "No description",
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (uploadedFiles.isNotEmpty) ...[
              Text(
                "Attachments",
                style: GoogleFonts.robotoMono(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              ...uploadedFiles.map((file) {
                String url;
                if (file.startsWith('http')) {
                  url = file;
                } else {
                  url = getPublicUrl(file);
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: buildStorageImage(url),
                );
              }),
            ],
            const SizedBox(height: 20),

            // Row(
            //   mainAxisAlignment: MainAxisAlignment.end,
            //   children: [
            //     IconButton(
            //       icon: const Icon(Icons.report_off),
            //       onPressed: () {},
            //     ),
            //     IconButton(icon: const Icon(Icons.archive), onPressed: () {}),
            //   ],
            // ),
            // const SizedBox(height: 12),
            if (!showExtraButtons)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => setState(() => showExtraButtons = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                      side: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                    elevation: 6,
                  ),
                  child: Text(
                    "Take an Action",
                    style: GoogleFonts.robotoMono(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            if (showExtraButtons)
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  children: [
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => showExtraButtons = false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 1.5,
                            ),
                          ),
                          elevation: 6,
                        ),
                        child: Text(
                          "Hide Actions",
                          style: GoogleFonts.robotoMono(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[
                      "Notify This User",
                      "Disable Account of this User",
                      "Message This User",
                    ].map(
                      (text) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () async {
                              final respondentId =
                                  widget.report['respondentId'];

                              switch (text) {
                                case "Notify This User":
                                  await notifyUser(respondentId);
                                  break;
                                case "Disable Account of this User":
                                  await disableUser(respondentId);
                                  break;
                                case "Message This User":
                                  await messageUser(
                                    respondentId,
                                    'Admin: We received a report regarding your account.',
                                  );
                                  break;
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              shape: const RoundedRectangleBorder(),
                            ),
                            child: Text(
                              text,
                              style: GoogleFonts.robotoMono(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
