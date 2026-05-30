import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image as background - fit completely to screen with no rounded corners
        ClipRRect(
          borderRadius: BorderRadius.zero, // Ensures no rounded corners
          child: Image.asset(
            'assets/images/bg_home_screen.png',
            fit: BoxFit.cover, // Make the image cover the entire screen
          ),
        ),
        child, // Place the child widget (content) on top of the background
      ],
    );
  }
}
