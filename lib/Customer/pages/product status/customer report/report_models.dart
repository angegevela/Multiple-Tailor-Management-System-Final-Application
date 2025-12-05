import 'package:file_picker/file_picker.dart';

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

bool isImageFile(String path) {
  final ext = path.split('.').last.toLowerCase();
  return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
}
