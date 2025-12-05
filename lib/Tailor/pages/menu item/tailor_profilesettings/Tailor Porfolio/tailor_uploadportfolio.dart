import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadhub_system/Customer/pages/font_provider.dart';

class UploadFile {
  final PlatformFile file;
  final String filePath;
  double progress;
  bool isUploading;
  bool isPaused;

  UploadFile(
    this.file, {
    required this.filePath,
    this.progress = 0.0,
    this.isUploading = true,
    this.isPaused = false,
  });
}

class TailorUploadportfolio extends StatefulWidget {
  const TailorUploadportfolio({super.key});

  @override
  State<TailorUploadportfolio> createState() => _TailorUploadportfolioState();
}

class _TailorUploadportfolioState extends State<TailorUploadportfolio> {
  final Map<UploadFile, Timer> uploadTimers = {};
  final List<UploadFile> uploadedFiles = [];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool showUploadUI = false;
  bool isConfirmed = false;

  @override
  void dispose() {
    for (final timer in uploadTimers.values) {
      timer.cancel();
    }
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> selectFile() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images == null || images.isEmpty) return;

    if (uploadedFiles.length + images.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can upload up to 20 images.")),
      );
      return;
    }

    for (var img in images) {
      final file = File(img.path);
      final platformFile = PlatformFile(
        name: img.name,
        path: img.path,
        size: await file.length(),
      );
      final upload = UploadFile(platformFile, filePath: img.path);
      setState(() => uploadedFiles.add(upload));
      simulateUpload(upload);
    }
  }

  void simulateUpload(UploadFile uploadFile) {
    const duration = Duration(milliseconds: 100);
    final timer = Timer.periodic(duration, (t) {
      if (!uploadFile.isPaused) {
        setState(() {
          if (uploadFile.progress >= 1) {
            uploadFile.isUploading = false;
            t.cancel();
          } else {
            uploadFile.progress += 0.02;
            if (uploadFile.progress > 1) uploadFile.progress = 1.0;
          }
        });
      }
    });
    uploadTimers[uploadFile] = timer;
  }

  void removeFile(UploadFile file) {
    uploadTimers[file]?.cancel();
    uploadTimers.remove(file);
    setState(() => uploadedFiles.remove(file));
  }

  bool isImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }

  String truncateFilename(String filename, int maxLength) {
    if (filename.length <= maxLength) return filename;
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1) {
      return '${filename.substring(0, maxLength - 3)}...';
    }
    final extension = filename.substring(dotIndex);
    final base = filename.substring(0, dotIndex);
    final allowed = maxLength - extension.length - 3;
    if (allowed <= 0) return '${filename.substring(0, maxLength - 3)}...';
    return '${base.substring(0, allowed)}...$extension';
  }

  Widget _buildUploadCard(UploadFile upload, double fontSize) {
    final sizeMB = (upload.file.size / (1024 * 1024));
    final fileName = truncateFilename(upload.file.name, 28);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage(upload.filePath))
            Image.file(
              File(upload.filePath),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          else
            Container(
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize + 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            upload.isUploading
                                ? '${((1 - upload.progress) * 50).round()}s remaining'
                                : '${sizeMB.toStringAsFixed(2)} MB',
                            style: TextStyle(
                              fontSize: fontSize - 2,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
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
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red[450],
                              border: Border.all(
                                color: Colors.red.shade500,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Colors.red,
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
                      valueColor: const AlwaysStoppedAnimation(
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

  Widget _buildFileUploadSection(double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portfolio Upload',
          style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Upload your tailoring work images (max 20).',
          style: GoogleFonts.lato(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(10),
          dashPattern: const [10, 4],
          strokeCap: StrokeCap.round,
          color: const Color(0xFF1A2A99),
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
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double btnWidth = constraints.maxWidth * 0.7 > 360
                        ? 360
                        : constraints.maxWidth * 0.7;
                    return SizedBox(
                      width: btnWidth,
                      child: ElevatedButton.icon(
                        onPressed: selectFile,
                        icon: const Icon(Icons.file_upload),
                        label: Text(
                          'Browse Files',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: const Color(0xFF1A2A99),
                          backgroundColor: const Color(0xFFDDE4FF),
                          side: const BorderSide(
                            color: Color(0xFF4D6BFF),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...uploadedFiles.map((f) => _buildUploadCard(f, fontSize)),
      ],
    );
  }

  Widget _buildFinalPreview(double fontSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double horizontalPadding = 20;
        final double availableWidth =
            constraints.maxWidth - horizontalPadding * 2;

        final double itemWidth = (availableWidth - 12) / 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File Upload',
                style: GoogleFonts.cuteFont(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9DC),
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: uploadedFiles.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2,
                      ),
                      itemBuilder: (context, index) {
                        final file = uploadedFiles[index];
                        final sizeMB = (file.file.size / (1024 * 1024));

                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            children: [
                              if (isImage(file.filePath))
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(file.filePath),
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                const Icon(Icons.insert_drive_file, size: 42),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      truncateFilename(file.file.name, 20),
                                      style: GoogleFonts.lato(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${sizeMB.toStringAsFixed(2)} MB',
                                      style: GoogleFonts.lato(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            isConfirmed = false;
                            showUploadUI = true;
                          });
                          Future.microtask(() => selectFile());
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFD9D9D9),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Add More?',
                          style: GoogleFonts.cuteFont(
                            // fontSize: fontSize,
                            fontSize: 19,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              Text(
                'Product Name',
                style: GoogleFonts.cuteFont(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Please input a title for your product',
                  hintStyle: GoogleFonts.cuteFont(fontSize: fontSize + 5),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Product Description',
                style: GoogleFonts.cuteFont(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Please describe your product.',
                  hintStyle: GoogleFonts.cuteFont(fontSize: fontSize + 5),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isConfirmed = false;
                          showUploadUI = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: const BorderSide(color: Colors.black26),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.chauPhilomeneOne(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty ||
                            descriptionController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please fill title and description",
                              ),
                            ),
                          );
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Uploading portfolio..."),
                          ),
                        );

                        List<String> fileUrls = [];

                        for (var f in uploadedFiles) {
                          final url = await uploadToSupabase(File(f.filePath));
                          if (url != null) fileUrls.add(url);
                        }

                        if (fileUrls.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to upload files"),
                            ),
                          );
                          return;
                        }

                        await saveToFirestore(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          fileUrls: fileUrls,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Portfolio uploaded successfully!"),
                          ),
                        );

                        Navigator.pop(context);
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Upload',
                        style: GoogleFonts.chauPhilomeneOne(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  final supabase = Supabase.instance.client;
  final firestore = FirebaseFirestore.instance;

  Future<String?> uploadToSupabase(File file) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storagePath = 'Portfolio/$fileName';

      final result = await supabase.storage
          .from('Tailor')
          .upload(storagePath, file, fileOptions: FileOptions(upsert: true));

      // Get public URL
      final publicUrl = supabase.storage
          .from('Tailor')
          .getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase upload exception: $e');
      return null;
    }
  }

  Future<void> saveToFirestore({
    required String title,
    required String description,
    required List<String> fileUrls,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    print("Firebase User: $firebaseUser");

    if (firebaseUser == null) {
      throw Exception("Firebase user not logged in");
    }

    await firestore.collection('Portfolio').doc().set({
      'title': title,
      'description': description,
      'files': fileUrls,
      'tailorUid': firebaseUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<FontProvider>().fontSize;
    final allUploaded = uploadedFiles.every((f) => !f.isUploading);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: const Color(0xFF262633),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SafeArea(
        child: isConfirmed
            ? _buildFinalPreview(fontSize)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Would you like to upload a file?',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => setState(() => showUploadUI = !showUploadUI),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black26),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          showUploadUI ? 'Cancel Upload' : 'Yes, Upload File',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (showUploadUI) _buildFileUploadSection(fontSize),
                  ],
                ),
              ),
      ),
      bottomNavigationBar:
          (!isConfirmed && uploadedFiles.isNotEmpty && allUploaded)
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isConfirmed = true;

                    showUploadUI = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6082B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.lato(
                    fontSize: fontSize + 0.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
