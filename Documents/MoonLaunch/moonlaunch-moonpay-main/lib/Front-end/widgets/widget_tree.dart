import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/views/home_screen.dart';
import 'package:moon_launch/Front-end/views/profile_screen.dart';
import 'package:moon_launch/Front-end/views/reward_screen.dart';
import 'package:moon_launch/Front-end/views/wallet_screen.dart';
import 'package:moon_launch/Front-end/widgets/custom_bottom_navbar.dart';
import 'notifiers.dart';

List<Widget> pages = [
  HomeScreen(),
  WalletScreen(),
  RewardScreen(),
  ProfileScreen(),
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,

      // ✅ FIX: SafeArea added so content stays ABOVE system navigation buttons
      body: SafeArea(
        bottom: true,
        child: ValueListenableBuilder(
          valueListenable: selectedPageNotifier,
          builder: (context, selectedPage, child) {
            return pages[selectedPage];
          },
        ),
      ),

      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}
