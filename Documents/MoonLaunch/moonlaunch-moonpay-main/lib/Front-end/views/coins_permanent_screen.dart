import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/views/privacy_policy_screen.dart';
import 'package:moon_launch/Front-end/views/term_condition_screen.dart';
import 'package:moon_launch/Front-end/views/token_screen.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class CoinsPermanentScreen extends StatefulWidget {
  const CoinsPermanentScreen({super.key});

  @override
  State<CoinsPermanentScreen> createState() => _CoinsPermanentScreenState();
}

class _CoinsPermanentScreenState extends State<CoinsPermanentScreen> {

  /// ✅ default unchecked
  bool termAndConditions = false;

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
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
              children: [

                Text(
                  'MEMES ARE PERMANENT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontSize: mq.width * 0.070,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: mq.height * 0.015),

                Text(
                  'Once you create this meme you can not\n'
                  'delete or change anything about it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Benne',
                    fontSize: mq.width * 0.045,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/bit_coin.png',
                      width: 266,
                      height: 252,
                    ),
                  ),
                ),

                /// ✅ Terms row
                Padding(
                  padding: EdgeInsets.only(
                    right: mq.width * 0.17,
                    bottom: mq.height * 0.02,
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            termAndConditions = !termAndConditions;
                          });
                        },
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: termAndConditions
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFFE600),
                                      Color(0xFFDB2519),
                                    ],
                                  )
                                : null,
                            border: Border.all(
                              color: const Color(0xFFDB2519),
                              width: 1.5,
                            ),
                          ),
                          child: termAndConditions
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        'I agree with all ',
                        style: TextStyle(
                          fontFamily: 'Benne',
                          fontSize: mq.width * 0.025,
                          color: Colors.white,
                        ),
                      ),

                      _gradientLink(
                        text: 'Terms & Conditions',
                        fontSize: mq.width * 0.025,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TermConditionScreen(),
                            ),
                          );
                        },
                      ),

                      Text(
                        ' and ',
                        style: TextStyle(
                          fontFamily: 'Benne',
                          fontSize: mq.width * 0.025,
                          color: Colors.white,
                        ),
                      ),

                      _gradientLink(
                        text: 'Privacy Policy',
                        fontSize: mq.width * 0.025,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                /// ✅ BUTTON (b1 / b2)
                _gradientButton(
                  mq: mq,
                  text: 'Create Meme Coin',
                  isChecked: termAndConditions,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TokenScreen()),
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

  /// 🔘 BUTTON
  Widget _gradientButton({
    required Size mq,
    required String text,
    required bool isChecked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isChecked ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: mq.height * 0.06,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isChecked
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFFE600),
                    Color(0xFFDB2519),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: isChecked

            /// ✅ b2 – FILLED
            ? Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              )

            /// ✅ b1 – GRADIENT BORDER ONLY
            : CustomPaint(
                painter: _GradientBorderPainter(),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFFFFE600),
                          Color(0xFFDB2519),
                        ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontFamily: 'BernardMTCondensed',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// 🔗 Gradient Text Link
  Widget _gradientLink({
    required String text,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            colors: [
              Color(0xFFFFE600),
              Color(0xFFDB2519),
            ],
          ).createShader(bounds);
        },
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Benne',
            fontSize: fontSize,
            color: Colors.white,
            decoration: TextDecoration.underline,
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
          color: const Color(0xFFDB2519).withOpacity(0.20),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Icon(Icons.arrow_back_ios_new,
            color: Colors.white, size: 22),
      ),
    );
  }
}

/// 🎨 Gradient Border Painter (b1)
class _GradientBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFE600),
          Color(0xFFDB2519),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rRect =
        RRect.fromRectAndRadius(rect, const Radius.circular(999));
    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
