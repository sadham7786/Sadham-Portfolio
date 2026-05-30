import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/views/Wallet%20for%20Liquidity%20Screen.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class TokenScreen extends StatelessWidget {
  const TokenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffF7931A33).withOpacity(0.3),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
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
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: mq.height * 0.04),
            child: Column(
              children: [
                SizedBox(height: mq.height * 0.05),

                /// ===== CREATE COIN TITLE (NEECHE SHIFTED) =====
                Text(
                  'CREATE COIN',
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontSize: mq.width * 0.075,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: mq.height * 0.03),

                /// ===== COIN ICON =====
                Container(
                  height: 132,
                  width: 132,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFE600),
                        Color(0xFFDB2519),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.7),
                      ),
                      child: Image(image: AssetImage(
                        'assets/images/picture_icon.png',
                      ),height: 42,width: 42,))
                    ),
                  ),


                const SizedBox(height: 10),

                Text(
                  'Select meme Icon',
                  style: TextStyle(
                    fontFamily: 'Benne',
                    fontSize: mq.width * 0.04,
                    color: const Color(0xFFC9C9C9),
                  ),
                ),

                const SizedBox(height: 20),

                /// ===== INPUTS =====
                _inputField(mq, 'Coin Name'),
                _inputField(mq, 'Ticker Symbol'),
                _inputField(
                  mq,
                  'Description',
                  maxLines: 3,
                  radius: mq.width * 0.08,
                ),
                _inputField(mq, 'Total Supply'),
                _inputField(
                  mq,
                  'Starting Liquidity (BNB) - min 0.025',
                ),

                const SizedBox(height: 24),

                /// ===== SUBMIT BUTTON =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mq.width * 0.07),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SelectWalletLiquidityScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: mq.height * 0.065,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFE600),
                            Color(0xFFDB2519),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Center(
                        child: Text(
                          'Submit',
                          style: TextStyle(
                            fontFamily: 'BernardMTCondensed',
                            fontSize: mq.width * 0.055,
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
      ),
    );
  }

  /// ===== INPUT FIELD WIDGET =====
  Widget _inputField(
      Size mq,
      String hint, {
        int maxLines = 1,
        double? radius,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mq.width * 0.07,
        vertical: 6,
      ),
      child: TextField(
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Benne',
            color: Color(0xFFC9C9C9),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(radius ?? mq.width * 0.5),
            borderSide: const BorderSide(color: Colors.white30),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(radius ?? mq.width * 0.5),
            borderSide: const BorderSide(color: Color(0xFFDB2519)),
          ),
        ),
      ),
    );
  }
}
