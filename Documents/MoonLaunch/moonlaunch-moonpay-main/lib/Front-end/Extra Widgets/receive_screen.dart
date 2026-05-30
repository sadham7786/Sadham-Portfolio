import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moon_launch/Back-end/Controllers/session_controller.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});

  static const LinearGradient _btnGradient = LinearGradient(
    colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    final walletAddress = SessionController.instance.walletAddress ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: _topBar(context, mq),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * 0.07),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: mq.height * 0.02),
                Text(
                  "Receive",
                  style: TextStyle(
                    fontFamily: "BernardMTCondensed",
                    fontSize: mq.width * 0.085,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: mq.height * 0.02),

                // warning banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A0F0F).withOpacity(0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.info, color: Color(0xFFFF4B4B), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Only send BNB assets to this address. All other assets will be permanently lost.",
                          style: TextStyle(
                            fontFamily: "Benne",
                            color: Colors.white.withOpacity(.9),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: mq.height * 0.03),

                // QR big box
                Center(
                  child: Container(
                    width: mq.width * 0.78,
                    height: mq.width * 0.78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white.withOpacity(0.35),
                    ),
                    child: Center(
                      child: QrImageView(
                        data: walletAddress,
                        version: QrVersions.auto,
                        size: mq.width * 0.62,
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: mq.height * 0.03),

                // 3 circular gradient icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _gradCircleIcon(
                      icon: Icons.copy,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: walletAddress));
                      },
                    ),
                    const SizedBox(width: 14),
                    _gradCircleIcon(
                      icon: Icons.arrow_downward,
                      onTap: () {
                        // download placeholder
                      },
                    ),
                    const SizedBox(width: 14),
                    _gradCircleIcon(
                      icon: Icons.share,
                      onTap: () async {
                        await Share.share(walletAddress, subject: "MoonLaunch Wallet Address");
                      },
                    ),
                  ],
                ),

                const Spacer(),

                _bottomGradientButton(text: "Next", onTap: () {}),

                SizedBox(height: mq.height * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _topBar(BuildContext context, Size mq) {
    return AppBar(
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
            InkWell(
              onTap: () => Navigator.pop(context),
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
                  child: Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 24),
                ),
              ),
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
    );
  }

  Widget _gradCircleIcon({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _bottomGradientButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _btnGradient,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: "BernardMTCondensed",
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
