import 'package:flutter/material.dart';

class ProfileBackground extends StatelessWidget {
  final Widget child;

  const ProfileBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        /*Image.asset(
          'assets/images/bg_create_coin.png',
          fit: BoxFit.cover,
        ),*/
        Container(
          color: Colors.black,
        ),
        child,
      ],
    );
  }
}
