import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moon_launch/Front-end/views/luanch_your_meme_coin.dart';
import 'notifiers.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final Size mqSize = MediaQuery.of(context).size;

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: SizedBox(
          width: mqSize.width,
          height: 80,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ✅ Custom Painted Background
              CustomPaint(
                size: Size(mqSize.width, 80),
                painter: BNBCustomPainter(),
              ),

              // ✅ Center Button (Launch)
              /*Positioned(
                top: -20,
                left: mqSize.width / 2 - 35,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE600), Color(0xFFDB2519)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LaunchYourMemeScreen(),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/si_rocket-fill.png",
                          height: 22,
                          width: 22,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Launch",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: "BernardMTCondensed",
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),*/

              // ✅ Bottom Icons
              ValueListenableBuilder<int>(
                valueListenable: selectedPageNotifier,
                builder: (context, selectedIndex, _) {
                  return Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _navIcon(
                          index: 0,
                          selectedIndex: selectedIndex,
                          iconPath: 'assets/images/home.png', // ✅ PNG
                          label: "Home",
                        ),
                        _navIcon(
                          index: 1,
                          selectedIndex: selectedIndex,
                          iconPath: 'assets/images/Walleticon.svg', // ✅ SVG
                          label: "Wallet",
                        ),
                        SizedBox(width: mqSize.width * 0.20),
                        _navIcon(
                          index: 2,
                          selectedIndex: selectedIndex,
                          iconPath: 'assets/images/Rewardicon.svg', // ✅ SVG
                          label: "Reward",
                        ),
                        _navIcon(
                          index: 3,
                          selectedIndex: selectedIndex,
                          iconPath: 'assets/images/profileicon.svg', // ✅ SVG
                          label: "Profile",
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIcon({
    required int index,
    required int selectedIndex,
    required String iconPath,
    required String label,
  }) {
    final bool isSelected = index == selectedIndex;
    final Color iconColor = isSelected ? Colors.white : Colors.white54;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            selectedPageNotifier.value = index;
          },
          icon: _buildIcon(iconPath, iconColor),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: "BernardMTCondensed",
            color: isSelected ? Colors.white : Colors.white54,
          ),
        ),
      ],
    );
  }

  /// ✅ SVG -> SvgPicture.asset
  /// ✅ PNG/JPG -> Image.asset (tint supported)
  Widget _buildIcon(String iconPath, Color color) {
    final String lower = iconPath.toLowerCase();

    if (lower.endsWith('.svg')) {
      return SvgPicture.asset(
        iconPath,
        width: 28,
        height: 28,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    // ✅ For PNG/JPG etc.
    return Image.asset(
      iconPath,
      width: 28,
      height: 28,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      fit: BoxFit.contain,
    );
  }
}

class BNBCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2A1216),
          Color(0xFF9A1117),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, 20);

    // Left curve
    path.quadraticBezierTo(size.width * 0.18, 0, size.width * 0.30, 0);
    path.quadraticBezierTo(size.width * 0.35, 0, size.width * 0.38, 35);

    // Center dip
    path.cubicTo(
      size.width * 0.38,
      35,
      size.width * 0.42,
      70,
      size.width * 0.50,
      68,
    );

    path.cubicTo(
      size.width * 0.58,
      70,
      size.width * 0.62,
      35,
      size.width * 0.64,
      20,
    );

    // Right curve
    path.quadraticBezierTo(size.width * 0.67, 0, size.width * 0.72, 0);
    path.quadraticBezierTo(size.width * 0.82, 0, size.width, 20);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
