import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/views/coins_permanent_screen.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';
import 'package:share_plus/share_plus.dart';

class CoinSelectionScreen extends StatefulWidget {
  const CoinSelectionScreen({super.key});

  @override
  State<CoinSelectionScreen> createState() => _CoinSelectionScreenState();
}

class _CoinSelectionScreenState extends State<CoinSelectionScreen> {
  int selectedIndex = -1;

  final List<String> coinImages =
      List.generate(20, (i) => 'assets/images/C${i + 1}.png');

  Future<void> _shareFromIcon() async {
    const String shareText =
        "Moon Launch 🚀\nCreate your meme coin now!\nhttps://yourapp.com";

    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      shareText,
      subject: "Moon Launch",
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size mqSize = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: const Color(0xFFDB2519).withOpacity(0.2),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 3),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 24,
                    ),
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
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: mqSize.width * 0.05,
                  vertical: mqSize.height * 0.03,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Coin Color',
                      style: TextStyle(
                        fontFamily: 'BernardMTCondensed',
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        fontSize: mqSize.width * 0.065,
                      ),
                    ),

                    // ✅ BIGGER SHARE BUTTON + CLICKABLE
                    InkWell(
                      onTap: _shareFromIcon,
                      borderRadius: BorderRadius.circular(999),
                      child:  Center(
                        child: Image.asset('assets/images/share_2.png',height: 45,width: 45,)
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ GRID
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: mqSize.width * 0.05),
                  child: GridView.builder(
                    itemCount: coinImages.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          // ✅ COIN CLICKABLE (100% working)
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: _coinItem(
                            isSelected: selectedIndex == index,
                            imagePath: coinImages[index],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: mqSize.width * 0.05),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CoinsPermanentScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: mqSize.height * 0.06,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE600), Color(0xFFDB2519)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Center(
                      child: Text(
                        'Select',
                        style: TextStyle(
                          fontFamily: 'BernardMTCondensed',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 16,
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

  // ✅ BIG COIN: fills full grid cell (screenshot like) + thin selected ring
  Widget _coinItem({
    required bool isSelected,
    required String imagePath,
  }) {
    const double borderWidth = 0.5; // thin ring

    const LinearGradient ringGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFE600), Color(0xFFDB2519)],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ coin will be as big as the cell
        final double size = constraints.maxWidth;

        return Center(
          child: Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(isSelected ? borderWidth : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected ? ringGradient : null,
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}
