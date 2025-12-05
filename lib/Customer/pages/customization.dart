import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:threadhub_system/Customer/pages/font_provider.dart';

class CustomizationPage extends StatefulWidget {
  const CustomizationPage({super.key});

  @override
  State<CustomizationPage> createState() => _CustomizationPageState();
}

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

class _CustomizationPageState extends State<CustomizationPage> {
  final Map<UploadFile, Timer> uploadTimers = {};
  final List<UploadFile> uploadedFiles = [];
  final List<File> pickedImages = [];
  final List<String> imageNames = [];
  final List<String> imageSizes = [];
  final TextEditingController _customizationdescripController =
      TextEditingController();

  bool _wantsToUpload = false;
  bool isConfirmed = false;

  @override
  void dispose() {
    for (final timer in uploadTimers.values) {
      timer.cancel();
    }

    super.dispose();
  }

  Future<void> selectFile() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images == null || images.isEmpty) return;

    if (uploadedFiles.length + images.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can upload a maximum of 20 images.")),
      );
      return;
    }

    for (var img in images) {
      final file = File(img.path);
      final upload = UploadFile(
        PlatformFile(name: img.name, size: await file.length(), path: img.path),
        filePath: img.path,
      );
      setState(() {
        uploadedFiles.add(upload);
      });
      simulateUpload(upload);
    }
  }

  void simulateUpload(UploadFile uploadFile) {
    const duration = Duration(milliseconds: 100);
    final timer = Timer.periodic(duration, (timer) {
      if (!uploadFile.isPaused) {
        setState(() {
          if (uploadFile.progress >= 1) {
            uploadFile.isUploading = false;
            timer.cancel();
          } else {
            uploadFile.progress += 0.02;
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

  Widget buildFinalPreview() {
    final fontSize = context.watch<FontProvider>().fontSize;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Customization Details",
            style: GoogleFonts.chauPhilomeneOne(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Description box
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey, width: 1.5),
            ),
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _customizationdescripController,
              decoration: const InputDecoration(
                hintText: 'Enter any customization instructions here',
                border: InputBorder.none,
              ),
              maxLines: 4,
            ),
          ),

          const SizedBox(height: 16),
          Text(
            "File Upload",
            style: GoogleFonts.sometypeMono(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          //FILE UPLOAD CONTAINER
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9DC),
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: uploadedFiles.length,
                  itemBuilder: (context, index) {
                    final file = uploadedFiles[index];
                    final sizeMB = (file.file.size) / (1024 * 1024);
                    return ListTile(
                      leading: isImage(file.filePath)
                          ? Image.file(
                              File(file.filePath),
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.insert_drive_file, size: 50),
                      title: Text(
                        file.file.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("${sizeMB.toStringAsFixed(2)} MB"),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isConfirmed = false;
                      _wantsToUpload = true;
                    });
                  },
                  label: Text(
                    "Upload More?",
                    style: TextStyle(fontSize: fontSize),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    textStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                "description": _customizationdescripController.text,
                "files": uploadedFiles.map((f) => f.filePath).toList(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6082B6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allUploaded = uploadedFiles.every((f) => !f.isUploading);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: const Color(0xFF262633),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: isConfirmed ? buildFinalPreview() : _buildCustomizationForm(),
      ),
      bottomNavigationBar: isConfirmed ? null : _buildBottomBar(allUploaded),
    );
  }

  Widget _buildBottomBar(bool allUploaded) {
    final fontSize = context.watch<FontProvider>().fontSize;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (uploadedFiles.isNotEmpty && allUploaded)
            ElevatedButton(
              onPressed: () {
                final hasDescription = _customizationdescripController.text
                    .trim()
                    .isNotEmpty;
                final hasFile = uploadedFiles.isNotEmpty;

                if (!hasDescription || !hasFile) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please provide both a description and a file.",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Color(0xFF393E46),
                    ),
                  );
                  return;
                }

                setState(() {
                  isConfirmed = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6082B6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Confirm'),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomizationForm() {
    final fontSize = context.watch<FontProvider>().fontSize;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customization Details',
            style: GoogleFonts.chauPhilomeneOne(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey, width: 1.5),
            ),
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _customizationdescripController,
              decoration: InputDecoration(
                hintText: 'Enter any customization instructions here',
                hintStyle: TextStyle(fontSize: fontSize),
                border: InputBorder.none,
              ),
              maxLines: 4,
            ),
          ),
          const SizedBox(height: 20),
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
          if (_wantsToUpload) _buildFileUploadSection(),
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

  Widget _buildFileUploadSection() {
    final fontSize = context.watch<FontProvider>().fontSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media Upload',
          style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: selectFile,
                  icon: const Icon(Icons.file_upload),
                  label: Text(
                    'Browse Files',
                    style: TextStyle(fontSize: fontSize),
                  ),
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
        ...uploadedFiles.map(_buildUploadCard),
      ],
    );
  }

  Widget _buildUploadCard(UploadFile upload) {
    final sizeMB = (upload.file.size) / (1024 * 1024);
    final fileName = truncateFilename(upload.file.name, 25);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upload.filePath.isNotEmpty)
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
                        SizedBox(
                          width: 200,
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          upload.isUploading
                              ? '${((1 - upload.progress) * 50).round()} seconds remaining'
                              : '${sizeMB.toStringAsFixed(2)} MB',
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
}
