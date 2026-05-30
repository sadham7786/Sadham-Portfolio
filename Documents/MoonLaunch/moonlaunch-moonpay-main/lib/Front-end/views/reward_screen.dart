import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/widgets/profile_background.dart';
import 'package:share_plus/share_plus.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key});

  Future<void> _shareInvite(BuildContext context) async {
    // ✅ Apna invite/referral link yahan set kar dein
    const String inviteLink = "https://yourapp.com/invite?ref=YOUR_CODE";
    const String message =
        "Join me on Moon Launch 🚀\nUse my invite link:\n$inviteLink";

    // Share sheet ko button ke around anchor dene ke liye (iPad etc.)
    final box = context.findRenderObject() as RenderBox?;

    await Share.share(
      message,
      subject: "Moon Launch Invite",
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,

        // ✅ Left side (Text + icon) perfectly centered vertically
        titleSpacing: mq.width * 0.045,
        title: Padding(
          padding: EdgeInsets.only(top: mq.height * 0.02), // ✅ SAME TOP as logo
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Life Time Rewards',
                style: TextStyle(
                  fontFamily: 'Benne',
                  fontSize: mq.width * 0.044,
                  color: const Color(0xFFC9C9C9),
                ),
              ),
            ],
          ),
        ),

        // ✅ Right side (Logo) same top padding
        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: mq.width * 0.045,
              top: mq.height * 0.02, // ✅ SAME TOP as left
            ),
            child: Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/moon_launch_logo.png',
                width: 104,
                height: 31,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),

      body: ProfileBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: mq.height * 0.01),

                // ===== TOP AMOUNT (LEFT) =====
                Padding(
                  padding: EdgeInsets.only(left: mq.width * 0.05),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'BernardMTCondensed',
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: '\$0.00',
                          style: TextStyle(fontSize: mq.width * 0.11),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Text(
                              'usd',
                              style: TextStyle(
                                fontFamily: 'BernardMTCondensed',
                                fontWeight: FontWeight.w400,
                                fontSize: mq.width * 0.045,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== CENTER COIN IMAGE =====
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/reward_coin.png',
                    height: 328,
                    width: 328,
                    fit: BoxFit.contain,
                  ),
                ),

                // ===== CENTER TEXT =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mq.width * 0.08),
                  child: Text(
                    'Earn BNB coins whenever your family, friends and their friends buy a meme.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Benne',
                      fontWeight: FontWeight.w400,
                      fontSize: mq.width * 0.070,
                      height: 1.15,
                      color: const Color(0xFFC9C9C9),
                    ),
                  ),
                ),

                SizedBox(height: mq.height * 0.035),

                // ===== INVITE BUTTON (SHARE SHEET) =====
               /* Padding(
                  padding: EdgeInsets.symmetric(horizontal: mq.width * 0.06),
                  child: InkWell(
                    onTap: () => _shareInvite(context), // ✅ share sheet open
                    borderRadius: BorderRadius.circular(60),
                    child: Container(
                      height: mq.height * 0.060,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: mq.width * 0.060,
                          ),
                          SizedBox(width: mq.width * 0.02),
                          const Text(
                            'Invite',
                            style: TextStyle(
                              fontFamily: 'BernardMTCondensed',
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),*/

                SizedBox(height: mq.height * 0.06),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
