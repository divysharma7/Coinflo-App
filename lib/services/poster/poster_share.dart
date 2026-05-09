import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PosterShare {
  /// Save PNG bytes to the device gallery.
  static Future<bool> saveToGallery(Uint8List pngBytes) async {
    try {
      await Gal.putImageBytes(pngBytes, name: 'pulse_${DateTime.now().millisecondsSinceEpoch}');
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Share PNG bytes via platform share sheet.
  static Future<void> share(Uint8List pngBytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pulse_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(pngBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'My week with Pulse',
    );
  }
}
