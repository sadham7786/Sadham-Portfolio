import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/auth_screens/login_screen.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class GuidScreen extends StatefulWidget {
  const GuidScreen({super.key});

  @override
  State<GuidScreen> createState() => _GuidScreenState();
}

class _GuidScreenState extends State<GuidScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/images/moon_launch_roc.png",
      "title": "Launch Your Own Meme ",
      "description":
          "Create and trade your meme in minutes."
    },
    {
      "image": "assets/images/hand_coin.png",
      "title": "No Code. No Permissions. Just Launch.",
      "description":
          "Name your meme, give it a story, then add liquidity and it’s instantly deployed on the BNB blockchain."
    },
    {
      "image": "assets/images/coin_image.png",
      "title": "Trade Your Meme Freely",
      "description":
          "Trade and swap your meme with real time charts."
    },
    {
      "image": "assets/images/coins_image.png",
      "title": "Turn Hype Into Earnings",
      "description":
          "Earn MOONLX coins everytime someone buys or sells your meme."
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size mqSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 22.0),
                child: Image.asset(
                  'assets/images/moon_launch_logo.png',
                  width: mqSize.width * 0.5,
                  fit: BoxFit.contain,
                ),
              ),

              // ✅ PageView area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableH = constraints.maxHeight;

                    // Dynamic sizes based on AVAILABLE height (not full screen)
                    final double imageH = availableH * 0.52; // was causing overflow
                    final double titleSize =
                        (mqSize.width * 0.07).clamp(20.0, 34.0);
                    final double descSize =
                        (mqSize.width * 0.04).clamp(14.0, 20.0);

                    return PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (context, pageIndex) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: availableH),
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: imageH,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: mqSize.width * 0.06,
                                      ),
                                      child: Image.asset(
                                        _pages[pageIndex]['image']!,
                                        width: double.infinity,
                                        fit: BoxFit.contain, // ✅ safer than cover
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _pages.length,
                                      (i) => _buildDot(i),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: mqSize.width * 0.12,
                                    ),
                                    child: Text(
                                      _pages[pageIndex]['title']!,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: titleSize,
                                        fontFamily: 'BernardMTCondensed',
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: mqSize.width * 0.10,
                                    ),
                                    child: Text(
                                      _pages[pageIndex]['description']!,
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: descSize,
                                        fontFamily: 'Benne',
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey.shade400,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ✅ Bottom button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: mqSize.width * 0.05),
                child: InkWell(
                  onTap: () {
                    if (_currentIndex == _pages.length - 1) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    height: mqSize.height * 0.07,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE600), Color(0xFFDB2519)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Center(
                      child: Text(
                        _currentIndex == _pages.length - 1 ? 'Continue' : 'Next',
                        style: TextStyle(
                          fontFamily: 'BernardMTCondensed',
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          fontSize: (mqSize.width * 0.06).clamp(18.0, 28.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: mqSize.height * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final bool isActive = _currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: isActive ? 22 : 8,
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFFFFE600), Color(0xFFDB2519)],
              )
            : null,
        color: isActive ? null : Colors.grey.shade600,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
