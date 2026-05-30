import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/views/coin_selection_screen.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class EarningIntroScreen extends StatelessWidget {
  const EarningIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
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
                width: 104,
                height: 31,
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
                Text(
                  'EARN AS PEOPLE TRADE YOUR COIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontSize: mq.width * 0.063,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: mq.height * 0.015),
                Text(
                  'Everytime someone trades your coin\nyou receive MOONLX coins.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Benne',
                    
                    fontSize: mq.width * 0.045,
                    color: Colors.white.withOpacity(0.75),
                    height: 1.35,
                  ),
                ),

                /// ✅ IMAGE SIZE INCREASED A LOT (takes most of free space)
                Expanded(
                  flex: 8, // ✅ give more space to image
                  child: Center(
                    child: Transform.scale(
                      scale: 1.00, // ✅ FORCE BIGGER (increase more if needed: 1.5 / 1.7)
                      child: Image.asset(
                        'assets/images/referral_image.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                /// ✅ Button area slightly smaller so image can grow
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _gradientButton(
                      mq: mq,
                      text: 'Next',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CoinSelectionScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
              Color(0xFFFFE600),
              Color(0xFFDB2519),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
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
