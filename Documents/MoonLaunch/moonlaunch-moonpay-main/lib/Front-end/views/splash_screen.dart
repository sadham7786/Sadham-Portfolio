import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moon_launch/Back-end/Controllers/session_controller.dart';
import 'package:moon_launch/Front-end/auth_screens/login_screen.dart';
import 'package:moon_launch/Front-end/tutorial_screen/guid_screen.dart';
import 'package:moon_launch/Front-end/widgets/widget_tree.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      final session = SessionController.instance;
      Widget next;
      if (session.isLoggedIn) {
        next = const WidgetTree();
      } else if (session.guideSeen) {
        next = const LoginScreen();
      } else {
        next = const GuidScreen();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => next),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mqSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black, // ✅ so empty space looks good
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// ✅ Background (NO CROP - full image visible)
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_splash_screen.png',
              fit: BoxFit.contain, // ✅ changed from cover to contain
              alignment: Alignment.center,
            ),
          ),

          /// Center Logo with scale animation
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SizedBox(
                width: mqSize.width * 0.8,
                height: mqSize.width * 0.8,
                child: Image.asset(
                  'assets/images/moon_launch_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
