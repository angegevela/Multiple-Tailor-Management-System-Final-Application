import 'package:file_picker/file_picker.dart';

class UploadFile {
  final PlatformFile file;
  String filePath;
  double progress = 0.0;
  bool isUploading = true;
  bool isPaused = false;

  String? storagePath; 
  String? signedUrl;   

  UploadFile(this.file, {required this.filePath});
}

bool isImageFile(String path) {
  final ext = path.split('.').last.toLowerCase();
  return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
}
