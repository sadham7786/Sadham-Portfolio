import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/views/coin_detail_screen.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
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
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 10,
              horizontal: mqSize.width * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Featured',
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontWeight: FontWeight.w400,
                    fontSize: mqSize.width * 0.08,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: mqSize.height * 0.03),
                Text(
                  'highlight',
                  style: TextStyle(
                    fontFamily: 'Benne',
                    fontWeight: FontWeight.w400,
                    fontSize: mqSize.width * 0.05,
                    color: const Color(0xFFC9C9C9),
                  ),
                ),
                SizedBox(height: mqSize.height * 0.03),

                Expanded(
                  child: ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CoinDetailScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 15,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                width: 1.0,
                                color: Color(0xFFCDCDCD),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // ✅ FIX: Ab image ka size increase hoga, lekin spacing extra nahi legi
                              // (SizedBox fixes the width taken by image)
                              SizedBox(
                                width: 52,   // ✅ yahan change karke size barhao
                                height: 52,  // ✅ yahan change karke size barhao
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Image.asset(
                                    'assets/images/bit_coin.png',
                                  ),
                                ),
                              ),

                              SizedBox(width: mqSize.width * 0.02),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'MemeCoin',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'BernardMTCondensed',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '12.234',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Benne',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
                                        color: Color(0xFFC9C9C9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(
                                width: mqSize.width * 0.26,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      '\$43,250',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'BernardMTCondensed',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.arrow_drop_up_sharp,
                                          color: Colors.green,
                                          size: 22,
                                        ),
                                        Text(
                                          '0.67%',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'BernardMTCondensed',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
