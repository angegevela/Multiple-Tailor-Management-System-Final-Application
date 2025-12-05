import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';
import 'review_report.dart';
import 'report_models.dart';

class ReportPage extends StatefulWidget {
  final String customerName;
  final String shopName;

  const ReportPage({
    super.key,
    required this.customerName,
    required this.shopName,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<UploadFile> uploadedFiles = [];
  late TextEditingController respondentNameController;
  late TextEditingController reporteeNameController;
  final TextEditingController reportDescriptionController =
      TextEditingController();
  final Map<UploadFile, Timer> uploadTimers = {};
  bool _wantsToUpload = false;

  @override
  void initState() {
    super.initState();
    respondentNameController = TextEditingController(text: widget.customerName);
    reporteeNameController = TextEditingController(text: widget.shopName);
  }

  @override
  void dispose() {
    for (final timer in uploadTimers.values) {
      timer.cancel();
    }
    respondentNameController.dispose();
    reporteeNameController.dispose();
    reportDescriptionController.dispose();
    super.dispose();
  }

  Future<void> selectFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    if (uploadedFiles.length + result.files.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can upload a maximum of 20 files.")),
      );
      return;
    }

    for (var file in result.files) {
      final upload = UploadFile(file, filePath: file.path ?? '');
      setState(() => uploadedFiles.add(upload));
      simulateUpload(upload);
    }
  }

  void simulateUpload(UploadFile uploadFile) {
    const duration = Duration(milliseconds: 300);
    final timer = Timer.periodic(duration, (timer) {
      if (!uploadFile.isPaused) {
        setState(() {
          if (uploadFile.progress >= 1) {
            uploadFile.isUploading = false;
            timer.cancel();
          } else {
            uploadFile.progress += 0.05;
          }
        });
      }
    });
    uploadTimers[uploadFile] = timer;
  }

  void removeFile(UploadFile file) {
    uploadTimers[file]?.cancel();
    setState(() {
      uploadedFiles.remove(file);
      uploadTimers.remove(file);
    });
  }

  bool isImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }

  String truncateFilename(String filename, int maxLength) {
    if (filename.length <= maxLength) return filename;
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1) return '${filename.substring(0, maxLength - 3)}...';
    final extension = filename.substring(dotIndex);
    final base = filename.substring(0, dotIndex);
    final allowedLength = maxLength - extension.length - 3;
    return '${base.substring(0, allowedLength)}...$extension';
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<FontProvider>().fontSize;
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF262633),
      ),
      backgroundColor: const Color(0xFFEEEEEE),
      bottomNavigationBar: buildSubmitButton(fontSize),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            buildHeader(fontSize),
            const SizedBox(height: 10),
            buildTextField(
              context,
              "Respondent Name",
              respondentNameController,
            ),
            buildTextField(context, "Reportees Name", reporteeNameController),

            buildTextField(
              context,
              "Report Description",
              reportDescriptionController,
              maxLines: 5,
              hint: "Enter your message",
            ),
            const SizedBox(height: 20),
            buildFileUploadSection(fontSize),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget buildSubmitButton(double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            if (respondentNameController.text.isEmpty ||
                reporteeNameController.text.isEmpty ||
                reportDescriptionController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Please fill in all required fields.",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              );
              return;
            }

            final hasImage = uploadedFiles.any(
              (file) => isImage(file.filePath),
            );
            if (!hasImage) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Please upload at least one image file.",
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewReport(
                  respondentName: respondentNameController.text,
                  reporteeName: reporteeNameController.text,
                  reportDescription: reportDescriptionController.text,
                  uploadedFiles: uploadedFiles,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6082B6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Review Report',
            style: GoogleFonts.oswald(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeader(double fontSize) => Center(
    child: Container(
      height: 50,
      width: 330,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        'Product Report Form',
        style: GoogleFonts.sometypeMono(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
      ),
    ),
  );

  Widget buildFileUploadSection(double fontSize) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Would you like to upload a file?',
            style: GoogleFonts.sometypeMono(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _toggleUpload,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                _wantsToUpload ? 'Cancel Upload' : 'Yes, Upload File',
                style: GoogleFonts.sometypeMono(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_wantsToUpload) ...[
            Text(
              'Media Upload',
              style: GoogleFonts.lato(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Add your pictures, and you can upload up to 20 files max.',
              style: GoogleFonts.lato(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(10),
              dashPattern: const [10, 4],
              strokeCap: StrokeCap.round,
              color: const Color(0xFF4D6BFF),
              child: Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icons/upload.png', height: 50),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: selectFile,
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Browse Files'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                        textStyle: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFF4D6BFF),
                            width: 2,
                          ),
                        ),
                        foregroundColor: const Color(0xFF1A2A99),
                        backgroundColor: const Color(0xFFDDE4FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...uploadedFiles.map(
              (upload) => buildUploadedFileCard(upload, fontSize),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildUploadedFileCard(UploadFile upload, double fontSize) {
    final fileSizeInMB = upload.file.size / (1024 * 1024);
    final fileName = upload.file.name;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upload.filePath.isNotEmpty && File(upload.filePath).existsSync())
            isImage(upload.filePath)
                ? Image.file(
                    File(upload.filePath),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.insert_drive_file,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          truncateFilename(fileName, 25),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          upload.isUploading
                              ? '${((1 - upload.progress) * 50).round()} seconds remaining'
                              : '${fileSizeInMB.toStringAsFixed(2)} MB',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (upload.isUploading)
                          IconButton(
                            icon: Icon(
                              upload.isPaused ? Icons.play_arrow : Icons.pause,
                            ),
                            tooltip: upload.isPaused ? 'Resume' : 'Pause',
                            onPressed: () => setState(
                              () => upload.isPaused = !upload.isPaused,
                            ),
                          ),
                        GestureDetector(
                          onTap: () => removeFile(upload),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[350],
                              border: Border.all(
                                color: Colors.grey.shade500,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (upload.isUploading)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: upload.progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1849D6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleUpload() {
    setState(() {
      _wantsToUpload = !_wantsToUpload;
      if (!_wantsToUpload) {
        for (final timer in uploadTimers.values) {
          timer.cancel();
        }
        uploadTimers.clear();
        uploadedFiles.clear();
      }
    });
  }

  Widget buildTextField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
  }) {
    final fontSize = context.watch<FontProvider>().fontSize;
    return Column(
      children: [
        Container(
          width: 330,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            label,
            style: GoogleFonts.sometypeMono(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 330,
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
