import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSelector {
  static void show({
    required BuildContext context,
    required Function(ImageSource source) onImageSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 25),
          decoration: const BoxDecoration(
            color: Color(0xFF0E0E0E),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag indicator
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontFamily: 'BernardMTCondensed',
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _imageOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      onImageSelected(ImageSource.camera);
                    },
                  ),
                  _imageOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      onImageSelected(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _imageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(60),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFE600),
                  Color(0xFFDB2519),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Benne',
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
