import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/views/Wallet%20for%20Liquidity%20Screen2.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class SelectWalletLiquidityScreen extends StatefulWidget {
  const SelectWalletLiquidityScreen({super.key});

  @override
  State<SelectWalletLiquidityScreen> createState() =>
      _SelectWalletLiquidityScreenState();
}

class _SelectWalletLiquidityScreenState
    extends State<SelectWalletLiquidityScreen> {
  int selectedIndex = 0;

  final LinearGradient _mainGradient = const LinearGradient(
    colors: [Color(0xFFFFE600), Color(0xFFDB2519)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.black,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ===== TOP BAR (Back + Logo) =====
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: mq.width * 0.05,
                  vertical: mq.height * 0.012,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFDB2519).withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 24,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
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

              SizedBox(height: mq.height * 0.045),

              // ===== TITLE =====
              Text(
                'SELECT WALLET FOR LIQUIDITY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BernardMTCondensed',
                  fontWeight: FontWeight.w600,
                  fontSize: mq.width * 0.064,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: mq.height * 0.010),

              // ===== SUBTITLE =====
              Padding(
                padding: EdgeInsets.symmetric(horizontal: mq.width * 0.12),
                child: Text(
                  'Choose which wallet to use for your\nmeme starting liquidity.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Benne',
                    fontWeight: FontWeight.w400,
                    fontSize: mq.width * 0.043,
                    height: 1.25,
                    color: const Color(0xFFC9C9C9),
                  ),
                ),
              ),

              SizedBox(height: mq.height * 0.055),

              // ===== 2x2 WALLET OPTIONS =====
              Padding(
                padding: EdgeInsets.symmetric(horizontal: mq.width * 0.08),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _walletCircle(
                            mq: mq,
                            index: 0,
                            title: "MOONLAUNCH",
                            child: Image.asset(
                              "assets/images/MoonLaunch 2D-3D Orange Rocket logo 3.png",
                              width: 158,
                              height: 108,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(width: mq.width * 0.07),
                        Expanded(
                          child: _walletCircle(
                            mq: mq,
                            index: 1,
                            title: "Meta Mask",
                            child: Image.asset(
                              "assets/images/images 1.png",
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: mq.height * 0.040),
                    Row(
                      children: [
                        Expanded(
                          child: _walletCircle(
                            mq: mq,
                            index: 2,
                            title: "Trust Wallet",
                            child: Image.asset(
                              "assets/images/images 2.png",
                              width: 380,
                              height: 380,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(width: mq.width * 0.07),
                        Expanded(
                          child: _walletCircle(
                            mq: mq,
                            index: 3,
                            title: "Base",
                            child: Image.asset(
                              "assets/images/Base Wallet 1.png",
                              width: 71,
                              height: 71,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ===== CONTINUE BUTTON =====
              Padding(
                padding: EdgeInsets.symmetric(horizontal: mq.width * 0.06),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>ConfirmLiquidityDetailsScreen()));
                  },
                  borderRadius: BorderRadius.circular(60),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      height: mq.height * 0.060,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: _mainGradient,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: 'BernardMTCondensed',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: mq.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _walletCircle({
    required Size mq,
    required int index,
    required String title,
    required Widget child,
  }) {
    final bool isSelected = selectedIndex == index;
    final double circleSize = mq.width * 0.39;

    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: SizedBox(
        height: circleSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ✅ Outer ring: ONLY BORDER gradient when selected
            Container(
              width: double.infinity,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected ? _mainGradient : null, // gradient ring
                border: isSelected
                    ? null
                    : Border.all(
                  color: Colors.white.withOpacity(0.55),
                  width: 1.2,
                ),
              ),
              child: Padding(
                // ring thickness (selected)
                padding: EdgeInsets.all(isSelected ? (circleSize * 0.022) : 0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // ✅ IMPORTANT: inner background NEVER gradient
                    // (selected/unselected dono me same)
                    color: Colors.black.withOpacity(0.28),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: circleSize * 0.55,
                        child: Center(child: child),
                      ),
                      SizedBox(height: mq.height * 0.010),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BernardMTCondensed',
                          fontWeight: FontWeight.w400,
                          fontSize: mq.width * 0.040,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // CHECK BADGE
            if (isSelected)
              Positioned(
                top: circleSize * 0.25,
                left: circleSize * 0.10,
                child: Container(
                  width: mq.width * 0.048,
                  height: mq.width * 0.048,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFE600),
                  ),
                  child: Icon(
                    Icons.check,
                    size: mq.width * 0.030,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
