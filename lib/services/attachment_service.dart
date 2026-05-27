import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Picks and stores receipt images in the app's local documents directory.
class AttachmentService {
  final _picker = ImagePicker();

  static const _allowedExtensions = {'.jpg', '.jpeg', '.png', '.heic', '.webp'};
  static const _maxFileSize = 10 * 1024 * 1024; // 10 MB

  /// Pick an image from camera or gallery, copy to receipts folder.
  /// Returns the local file path, or null if cancelled or invalid.
  Future<String?> pickAndSave(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return null;

    final ext = p.extension(picked.path).toLowerCase();
    final safeExt = ext.isNotEmpty ? ext : '.jpg';
    if (!_allowedExtensions.contains(safeExt)) return null;

    final pickedFile = File(picked.path);
    if (await pickedFile.length() > _maxFileSize) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
    if (!receiptsDir.existsSync()) {
      receiptsDir.createSync(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final destPath = p.join(receiptsDir.path, fileName);

    await pickedFile.copy(destPath);
    return destPath;
  }

  /// Delete the attachment file at the given path.
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
