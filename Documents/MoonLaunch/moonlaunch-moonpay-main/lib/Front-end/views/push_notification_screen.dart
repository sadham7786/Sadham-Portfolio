import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class PushNotificationScreen extends StatelessWidget {
  const PushNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.black,
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // ===== TOP BAR (Back + Logo) =====
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: mq.width * 0.05,
                  vertical: mq.height * 0.018,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (circle)
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.12),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 24,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),

                      // Logo (top right)
                      Image.asset(
                        'assets/images/moon_launch_logo.png',
                        width: mq.width * 0.28,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),

              // ===== CONTENT =====
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: mq.height * 0.14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        'Push Notifications',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BernardMTCondensed',
                          fontWeight: FontWeight.w400,
                          fontSize: mq.width * 0.070,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: mq.height * 0.011),

                      // Subtitle
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: mq.width * 0.12),
                        child: Text(
                          'Customize your alerts to stay on top of\nthe meme market.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Benne',
                            fontWeight: FontWeight.w400,
                            fontSize: mq.width * 0.042,
                            height: 1.2,
                            color: const Color(0xFFC9C9C9),
                          ),
                        ),
                      ),

                      SizedBox(height: mq.height * 0.035),

                      // Bell image (CENTER)
                      // ✅ NOTE: Asset name apne project ke mutabiq rakh lena
                      // Screenshot jaisa bell arrow image yahan lagay ga.
                      Image.asset(
                        'assets/images/bellimage.png',
                        height: 322,
                        width: 322,
                        fit: BoxFit.contain,
                      ),

                      SizedBox(height: mq.height * 0.06),

                      // Enable button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: mq.width * 0.06),
                        child: InkWell(
                          onTap: () {
                            // TODO: enable push notification action
                          },
                          borderRadius: BorderRadius.circular(60),
                          child: Container(
                            height: mq.height * 0.070,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: Center(
                              child: Text(
                                'Enable Push Notifications',
                                style: TextStyle(
                                  fontFamily: 'BernardMTCondensed',
                                  fontWeight: FontWeight.w400,
                                  fontSize: mq.width * 0.052,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
