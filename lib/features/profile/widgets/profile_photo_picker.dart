import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme/app_colors.dart';

class ProfilePhotoPicker extends StatelessWidget {
  final String? photoUrl;
  final File? localFile;
  final VoidCallback onTap;

  const ProfilePhotoPicker({
    super.key,
    this.photoUrl,
    this.localFile,
    required this.onTap,
  });

  static Future<File?> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.inputFill,
              border: Border.all(color: AppColors.inputBorder, width: 2),
              image: _buildDecorationImage(),
            ),
            child: _buildPlaceholder(),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  DecorationImage? _buildDecorationImage() {
    if (localFile != null) {
      return DecorationImage(
          image: FileImage(localFile!), fit: BoxFit.cover);
    }
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return DecorationImage(
          image: NetworkImage(photoUrl!), fit: BoxFit.cover);
    }
    return null;
  }

  Widget? _buildPlaceholder() {
    if (localFile != null || (photoUrl != null && photoUrl!.isNotEmpty)) {
      return null;
    }
    return const Icon(Icons.person, size: 48, color: AppColors.inputBorder);
  }
}
