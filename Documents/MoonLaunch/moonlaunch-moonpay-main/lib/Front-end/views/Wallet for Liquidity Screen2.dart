import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class ConfirmLiquidityDetailsScreen extends StatefulWidget {
  const ConfirmLiquidityDetailsScreen({super.key});

  @override
  State<ConfirmLiquidityDetailsScreen> createState() =>
      _ConfirmLiquidityDetailsScreenState();
}

class _ConfirmLiquidityDetailsScreenState
    extends State<ConfirmLiquidityDetailsScreen> {
  final LinearGradient _mainGradient = const LinearGradient(
    colors: [Color(0xFFFFE600), Color(0xFFDB2519)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  final TextEditingController _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + mq.height * 0.03,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== TOP BAR (Back + Logo) =====
                Padding(
                  padding: EdgeInsets.only(
                    left: mq.width * 0.05,
                    right: mq.width * 0.05,
                    top: 30,
                  ),
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
                        width: 109,
                        height: 31,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: mq.height * 0.055),

                // ===== TITLE =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mq.width * 0.08),
                  child: Text(
                    'CONFIRM LIQUIDITY DETAILS',
                    style: TextStyle(
                      fontFamily: 'BernardMTCondensed',
                      fontWeight: FontWeight.w400,
                      fontSize: mq.width * 0.060,
                      color: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: mq.height * 0.040),

                // ===== WALLET ADDRESS BOX =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mq.width * 0.07),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: mq.width * 0.05,
                      vertical: mq.height * 0.022,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFDB2519),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wallet Address',
                          style: TextStyle(
                            fontFamily: 'Benne',
                            fontWeight: FontWeight.w400,
                            fontSize: mq.width * 0.040,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                        SizedBox(height: mq.height * 0.010),
                        Text(
                          '0x21c086a2fd88a05f829989sdgjfgsakl3skgh546gyb3j5b345vw',
                          style: TextStyle(
                            fontFamily: 'Benne',
                            fontWeight: FontWeight.w400,
                            fontSize: mq.width * 0.036,
                            height: 1.25,
                            color: Colors.white.withOpacity(0.90),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: mq.height * 0.040),

                // ===== CURRENT BALANCE =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mq.width * 0.08),
                  child: Text(
                    'Your Current Balance',
                    style: TextStyle(
                      fontFamily: 'Benne',
                      fontWeight: FontWeight.w400,
                      fontSize: mq.width * 0.040,
                      color: Colors.white.withOpacity(0.80),
                    ),
                  ),
                ),

                SizedBox(height: mq.height * 0.003),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mq.width * 0.08),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'BernardMTCondensed',
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: '27.65431',
                          style: TextStyle(fontSize: mq.width * 0.085),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Text(
                              'BNB',
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

                SizedBox(height: mq.height * 0.040),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mq.width * 0.08),
                  child: Text(
                    'Your BNB Amount for Liquidity',
                    style: TextStyle(
                      fontFamily: 'Benne',
                      fontWeight: FontWeight.w400,
                      fontSize: mq.width * 0.040,
                      color: Colors.white.withOpacity(0.80),
                    ),
                  ),
                ),
                 Padding(
                  padding: EdgeInsets.symmetric(horizontal: mq.width * 0.08),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'BernardMTCondensed',
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: '1.25',
                          style: TextStyle(fontSize: mq.width * 0.085),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ Spacer hata diya, iski jagah fixed spacing
                SizedBox(height: mq.height * 0.20),

                // ===== CONFIRM BUTTON =====
                Padding(
                  padding: EdgeInsets.only(
                    left: mq.width * 0.08,
                    right: mq.width * 0.08,
                  ),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(60),
                    child: Container(
                      height: mq.height * 0.070,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: _mainGradient,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Center(
                        child: Text(
                          'Confirm Transaction',
                          style: TextStyle(
                            fontFamily: 'BernardMTCondensed',
                            fontWeight: FontWeight.w400,
                            fontSize: mq.width * 0.058,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: mq.height * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
