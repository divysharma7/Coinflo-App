import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import 'package:finance_buddy_app/design_system/design_system.dart';

/// Full-screen image viewer with pinch-zoom for receipt attachments.
class AttachmentViewerPage extends StatelessWidget {
  const AttachmentViewerPage({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: const Text('Receipt'),
        elevation: 0,
      ),
      body: PhotoView(
        imageProvider: FileImage(File(filePath)),
        backgroundDecoration: const BoxDecoration(color: AppColors.black),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
      ),
    );
  }
}
