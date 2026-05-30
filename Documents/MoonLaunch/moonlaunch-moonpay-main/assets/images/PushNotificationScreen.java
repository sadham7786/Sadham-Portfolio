import 'package:flutter/material.dart';
import 'package:moon_launch/widgets/app_background.dart';

class PushNotificationScreen extends StatelessWidget {
  const PushNotificationScreen({super.key});

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
        toolbarHeight: mq.height * 0.12,
        titleSpacing: mq.width * 0.05,
        title: Padding(
          padding: EdgeInsets.only(top: mq.height * 0.018),
          child: Row(
            children: [
              _topBackCircleButton(
                mq: mq,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/moon_launch_logo.png',
                width: mq.width * 0.32,
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
              top: mq.height * 0.02,
              bottom: mq.height * 0.06,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: mq.height * 0.10),

                /// ✅ Title
                Text(
                  'Push Notifications',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontSize: mq.width * 0.080,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    letterSpacing: 0.2,
                  ),
                ),

                SizedBox(height: mq.height * 0.015),

                /// ✅ Subtitle (2 lines)
                Text(
                  'Customize your alerts to stay on top of\n'
                  'the market',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Benne',
                    fontSize: mq.width * 0.042,
                    color: Colors.white.withOpacity(0.75),
                    height: 1.35,
                  ),
                ),

                SizedBox(height: mq.height * 0.08),

                /// ✅ Center bell image
                Expanded(
                  child: Center(
                    child: Image.asset(
                      // ✅ yahan aap bell wali image ka asset path dein
                      'assets/images/bellimage.png',
                      width: 322,
                      hight: 322,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                /// ✅ Bottom gradient button
                _gradientButton(
                  mq: mq,
                  text: 'Enable Push Notifications',
                  onTap: () {
                    // TODO: enable push notifications
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
        height: mq.width * 0.11,
        width: mq.width * 0.11,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFFDB2519).withOpacity(0.20),
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: mq.width * 0.045,
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
        height: mq.height * 0.075,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFE600), // yellow
              Color(0xFFDB2519), // red
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'BernardMTCondensed',
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: mq.width * 0.048,
            ),
          ),
        ),
      ),
    );
  }
}
