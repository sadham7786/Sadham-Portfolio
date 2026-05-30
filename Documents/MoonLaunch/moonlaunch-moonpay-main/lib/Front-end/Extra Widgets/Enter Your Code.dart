import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class EnterCodeScreen extends StatefulWidget {
  const EnterCodeScreen({super.key});

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  final TextEditingController _codeC = TextEditingController();

  @override
  void dispose() {
    _codeC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,

      /// ✅ Top: back circle left + MoonLaunch logo right (transparent)
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
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: mq.width * 0.06,
              right: mq.width * 0.06,
              top: mq.height * 0.02,
              bottom: mq.height * 0.06,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: mq.height * 0.06),

                /// ✅ Center image (same shield)
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/verification_image.png',
                    width: mq.width * 0.50,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: mq.height * 0.07),

                /// ✅ Title (Enter code)
                Text(
                  'Enter code',
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontWeight: FontWeight.w600,
                    fontSize: mq.width * 0.085,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),

                SizedBox(height: mq.height * 0.01),

                /// ✅ Subtitle
                Text(
                  'Enter your code to verify your identity',
                  style: TextStyle(
                    fontFamily: 'Benne',
                    fontWeight: FontWeight.w400,
                    fontSize: mq.width * 0.043,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),

                SizedBox(height: mq.height * 0.06),

                /// ✅ (Image me input field nahi dikh raha, is liye remove)
                /// Agar aap chaho to code input add kar sakte ho:
                /// _codeField(mq),

                /// Button bottom jaisa feel (screen me neeche hai)
                SizedBox(height: mq.height * 0.28),

                /// ✅ Gradient Button (yellow -> red)
                _gradientButton(
                  mq: mq,
                  text: 'Send Code',
                  onTap: () {
                    // TODO: verify code
                    final code = _codeC.text.trim();
                    // ignore: avoid_print
                    print('Entered Code: $code');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Back circle button
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

  /// Gradient button
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
            style: TextStyle(
              fontFamily: 'BernardMTCondensed',
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: mq.width * 0.055,
            ),
          ),
        ),
      ),
    );
  }

  /// OPTIONAL: Code field (if you want to show it)
  // Widget _codeField(Size mq) {
  //   return TextField(
  //     controller: _codeC,
  //     keyboardType: TextInputType.number,
  //     style: TextStyle(
  //       fontFamily: 'Benne',
  //       fontSize: mq.width * 0.045,
  //       color: Colors.white,
  //     ),
  //     decoration: InputDecoration(
  //       hintText: "Enter Code",
  //       hintStyle: TextStyle(
  //         fontFamily: 'Benne',
  //         fontSize: mq.width * 0.04,
  //         color: Colors.white.withOpacity(0.55),
  //       ),
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(999),
  //         borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
  //       ),
  //       enabledBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(999),
  //         borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(999),
  //         borderSide: const BorderSide(color: Color(0xFFDB2519)),
  //       ),
  //     ),
  //   );
  // }
}
