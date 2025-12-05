import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';
import 'package:threadhub_system/Customer/pages/product%20status/customer%20report/report_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Customer/pages/product%20status/product_status.dart';

class ReviewReport extends StatelessWidget {
  final String respondentName;
  final String reporteeName;
  final String reportDescription;
  final List<UploadFile> uploadedFiles;

  const ReviewReport({
    super.key,
    required this.respondentName,
    required this.reporteeName,
    required this.reportDescription,
    required this.uploadedFiles,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<FontProvider>().fontSize;

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
            _buildLabelValue('Respondent Name', respondentName),
            const SizedBox(height: 10),
            _buildLabelValue('Reportee Name', reporteeName),
            const SizedBox(height: 10),
            _buildLabelValue('Description', reportDescription),
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
                  return _buildFileCard(file, fontSize);
                },
              ),
            ],
            const SizedBox(height: 30),
            _buildSubmitButton(context, fontSize),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
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

  Widget _buildFileCard(UploadFile file, double fontSize) {
    final isImage = isImageFile(file.filePath);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage)
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
            padding: const EdgeInsets.all(12),
            child: Text(
              file.file.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, double fontSize) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not logged in.')),
            );
            return;
          }

          try {
            final supabase = Supabase.instance.client;
            final uploadedFileUrls = <String>[];

            for (var file in uploadedFiles) {
              if (isImageFile(file.filePath)) {
                final bytes = await File(file.filePath).readAsBytes();
                final fileName =
                    'reports/${DateTime.now().millisecondsSinceEpoch}_${file.file.name}';
                await supabase.storage
                    .from('reports_uploads')
                    .uploadBinary(
                      fileName,
                      bytes,
                      fileOptions: const FileOptions(upsert: true),
                    );
                final publicUrl = supabase.storage
                    .from('reports_uploads')
                    .getPublicUrl(fileName);
                uploadedFileUrls.add(publicUrl);
              } else {
                uploadedFileUrls.add(file.filePath);
              }
            }
            final reportData = {
              'respondentName': respondentName,
              'reporteeName': reporteeName,
              'reportDescription': reportDescription,
              'uploadedFiles': uploadedFileUrls,
              'customerId': user.uid,
              'timestamp': FieldValue.serverTimestamp(),
              'status': 'Pending',
            };
            final reportReference = await FirebaseFirestore.instance
                .collection('Reports')
                .add(reportData);

            await FirebaseFirestore.instance.collection('notifications').add({
              'title': 'New Report Submitted',
              'body':
                  'A new report was submitted by $respondentName about $reporteeName.',
              'timestamp': FieldValue.serverTimestamp(),
              'toAdmin': true,
              'readBy': [],
            });

            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    _successDialog(context, fontSize, user.uid),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to submit report: $e')),
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
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _successDialog(BuildContext context, double fontSize, String userId) {
    return Dialog(
      backgroundColor: const Color(0xFFA6AEBF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/gif/success.gif', height: 120),
            const SizedBox(height: 20),
            Text(
              'Report submitted successfully!',
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductStatusPage(customerId: userId),
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
  }

  bool isImageFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif');
  }
}
