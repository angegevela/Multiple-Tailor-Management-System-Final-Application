import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';

class UploadFile {
  final PlatformFile file;
  double progress;
  bool isUploading;
  bool isPaused;

  UploadFile(
    this.file, {
    this.progress = 0,
    this.isUploading = true,
    this.isPaused = false,
  });
}

class UploadMediaPage extends StatefulWidget {
  final List<UploadFile>? initialFiles;
  const UploadMediaPage({super.key, this.initialFiles});

  @override
  State<UploadMediaPage> createState() => _UploadMediaPageState();
}

class _UploadMediaPageState extends State<UploadMediaPage> {
  List<UploadFile> uploadedFiles = [];
  final Map<UploadFile, Timer> uploadTimers = {};

  File? _selectedImage;
  @override
  void initState() {
    super.initState();
    if (widget.initialFiles != null) {
      uploadedFiles = List.from(widget.initialFiles!);
    }
  }

  Future<void> _uploadImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final platformFile = PlatformFile(
        name: pickedFile.name,
        path: pickedFile.path,
        size: await File(pickedFile.path).length(),
      );

      final upload = UploadFile(platformFile);

      setState(() {
        uploadedFiles.add(upload);
      });

      simulateUpload(upload);
    } else {
      print('No image selected.');
    }
  }

  void simulateUpload(UploadFile uploadFile) {
    const duration = Duration(milliseconds: 100);
    Timer timer = Timer.periodic(duration, (timer) {
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
    });
  }

  @override
  void dispose() {
    for (var timer in uploadTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  String truncateFilename(String name, int maxLength) {
    if (name.length <= maxLength) return name;
    return "${name.substring(0, maxLength - 3)}...";
  }

  bool isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith(".png") ||
        lower.endsWith(".jpg") ||
        lower.endsWith(".jpeg") ||
        lower.endsWith(".gif") ||
        lower.endsWith(".webp");
  }

  @override
  Widget build(BuildContext context) {
    bool allUploaded = uploadedFiles.every((f) => !f.isUploading);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: const Color(0xFF262633),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xFFD9D9D9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Permit',
                style: GoogleFonts.chauPhilomeneOne(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Media Upload',
                  style: GoogleFonts.chauPhilomeneOne(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Center(
                child: Text(
                  'Add your pictures, you can upload up to 20 files max.',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(10),
                dashPattern: const [10, 4],
                strokeCap: StrokeCap.round,
                color: Color(0xFF1A2A99),
                child: Container(
                  width: double.infinity,
                  height: 190,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/icons/upload.png', height: 50),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _uploadImageFromGallery,
                        icon: const Icon(Icons.file_upload),
                        label: const Text('Browse Files'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
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
              ...uploadedFiles.map((upload) {
                final fileSizeInMB = upload.file.size / (1024 * 1024);
                final fileName = truncateFilename(upload.file.name, 25);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (upload.file.path != null &&
                          isImage(upload.file.path!))
                        Image.file(
                          File(upload.file.path!),
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
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        fileName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
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
                                          upload.isPaused
                                              ? Icons.play_arrow
                                              : Icons.pause,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            upload.isPaused = !upload.isPaused;
                                          });
                                        },
                                      ),
                                    GestureDetector(
                                      onTap: () => removeFile(upload),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red.shade100,
                                          border: Border.all(
                                            color: Colors.redAccent,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.close,
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
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
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
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            if (uploadedFiles.isNotEmpty && allUploaded)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, uploadedFiles);
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6082B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Continue'),
              ),
          ],
        ),
      ),
    );
  }
}
