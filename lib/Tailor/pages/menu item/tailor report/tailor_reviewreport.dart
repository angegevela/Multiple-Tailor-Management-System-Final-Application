import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Tailor/pages/menu%20item/tailor_profilesettings/tailor_fontprovider.dart';
import 'package:threadhub_system/Tailor/pages/tailorhomepage.dart';

import 'tailor_reportpage.dart';

class TailorReviewReport extends StatelessWidget {
  final String respondentName;
  final String reporteeName;
  final String reportDescription;
  final List<UploadFile> uploadedFiles;

  const TailorReviewReport({
    super.key,
    required this.respondentName,
    required this.reporteeName,
    required this.reportDescription,
    required this.uploadedFiles,
  });

  bool isImageFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }

  Future<void> submitReport(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final supabase = Supabase.instance.client;

    try {
      final List<String> storedFileNames = [];

      for (final file in uploadedFiles) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.file.name}';

        final fileBytes = await File(file.filePath).readAsBytes();

        await supabase.storage
            .from('reports_uploads')
            .uploadBinary(
              'reports/$fileName',
              fileBytes,
              fileOptions: const FileOptions(upsert: true),
            );
        storedFileNames.add('reports/$fileName');
      }

      final reportRef = await firestore.collection('Reports').add({
        'respondentName': respondentName,
        'reporteeName': reporteeName,
        'reportDescription': reportDescription,
        'uploadedFiles': storedFileNames,
        'status': 'No Action Yet',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await firestore.collection('notifications').add({
        'title': 'New Report Submitted',
        'body': '$reporteeName has submitted a report against $respondentName.',
        'reportId': reportRef.id,
        'toAdmin': true,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
      });
      final reportData = {
        'respondentName': respondentName,
        'reporteeName': reporteeName,
        'reportDescription': reportDescription,
        'uploadedFiles': storedFileNames,
        'timestamp': FieldValue.serverTimestamp(),
      };
      await firestore.collection('Reports').add(reportData);
    } catch (e, s) {
      debugPrint('submitReport failed: $e');
      debugPrint('$s');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tailorFontSize = context.watch<TailorFontprovider>().fontSize;
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF262633),
      ),
      backgroundColor: const Color(0xFFEEEEEE),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildLabelValue('Respondent Name', respondentName),
            const SizedBox(height: 10),
            buildLabelValue('Reportee Name', reporteeName),
            const SizedBox(height: 10),
            buildLabelValue('Description', reportDescription),
            const SizedBox(height: 20),
            if (uploadedFiles.isNotEmpty) ...[
              const Text(
                'Uploaded Files',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: uploadedFiles.length,
                itemBuilder: (context, index) {
                  final file = uploadedFiles[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isImageFile(file.filePath))
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            child: Image.file(
                              File(file.filePath),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            height: 160,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                            ),
                            child: const Icon(
                              Icons.insert_drive_file,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            file.file.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await submitReport(context);

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Dialog(
                          backgroundColor: const Color(0xFFA6AEBF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/gif/success.gif',
                                  height: 120,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Report submitted successfully!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'Please wait for the administrator to review your report. Thank you for you patience and insight.',
                                  style: TextStyle(
                                    fontSize: tailorFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TailorHomePage(showAccepted: false),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF2EED7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } catch (e) {
                    if (context.mounted) Navigator.pop(context);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to submit report: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6082B6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Submit Report',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
