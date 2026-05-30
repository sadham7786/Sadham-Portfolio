import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/views/earning_screen.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class LaunchYourMemeScreen extends StatelessWidget {
  const LaunchYourMemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,

      /// ✅ Transparent AppBar (Back left + MoonLaunch logo right)
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        titleSpacing: mq.width * 0.05,
        title: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Row(
            children: [
              _topBackCircleButton(
                mq: mq,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/moon_launch_logo.png',
                width: 110,
                height: 35,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),

      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: mq.width * 0.06,
              right: mq.width * 0.06,
              top: mq.height * 0.055,
              bottom: mq.height * 0.06,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// ✅ Title
                Text(
                  'LAUNCH YOUR OWN MEME',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontSize: mq.width * 0.065,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    letterSpacing: 0.6,
                  ),
                ),

                SizedBox(height: mq.height * 0.015),

                /// ✅ Subtitle
                Text(
                  'Create a meme coin with a few taps that anyone can buy immediately.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Benne',
                    fontSize: mq.width * 0.045,
                    color: Colors.white.withOpacity(0.75),
                    height: 1.35,
                  ),
                ),

               
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: mq.width * 0.85,  
                      height: mq.height * 0.42, 
                      child: Image.asset(
                        'assets/images/bit_coin.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                _gradientButton(
                  mq: mq,
                  text: 'Next',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EarningIntroScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Back circle button (top-left)
  Widget _topBackCircleButton({
    required Size mq,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFFDB2519).withOpacity(0.20),
        ),
        child: const Padding(
          padding: EdgeInsets.only(right: 3),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Gradient button (Yellow -> Red)
  Widget _gradientButton({
    required Size mq,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: mq.height * 0.06,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2A1216),
              Color(0xFF9A1117),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Center(
          child: Text(
            'Next',
            style: TextStyle(
              fontFamily: 'BernardMTCondensed',
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
