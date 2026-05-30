import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class TermConditionScreen extends StatelessWidget {
  const TermConditionScreen({super.key});

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
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 24,
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
              horizontal: mqSize.width * 0.05,
              vertical: mqSize.height * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontWeight: FontWeight.w400,
                    fontSize: mqSize.width * 0.08,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: mqSize.height * 0.02),

                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      '''Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nec euismod lorem, a efficitur augue. Integer id vulputate sem. Integer lacinia ornare est, non sagittis sem commodo quis. Cras ut arcu varius, pharetra dui at, venenatis lectus. Nam dignissim tempor metus, quis vulputate mi tempor eget. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nec euismod lorem, a efficitur augue. Integer id vulputate sem. Integer lacinia ornare est, non sagittis sem commodo quis. Cras ut arcu varius, pharetra dui at, venenatis lectus. Nam dignissim tempor metus, quis vulputate mi tempor eget. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nec euismod lorem, a efficitur augue. Integer id vulputate sem. Integer lacinia ornare est, non sagittis sem commodo quis. Cras ut arcu varius, pharetra dui at, venenatis lectus. Nam dignissim tempor metus, quis vulputate mi tempor eget. Lorem ipsum dolor sit amet,

consectetur adipiscing elit. Sed nec euismod lorem, a efficitur augue. Integer id vulputate sem. Integer lacinia ornare est, non sagittis sem commodo quis. Cras ut arcu varius, pharetra dui at, venenatis lectus. Nam dignissim tempor metus, quis vulputate mi tempor eget. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nec euismod lorem, a efficitur augue. Integer id vulputate sem. Integer lacinia ornare est, non sagittis sem commodo quis. Cras ut arcu varius, pharetra dui at, venenatis lectus. Nam dignissim tempor metus, quis vulputate mi tempor eget. Lorem ipsum dolor sit amet, consectetur adipiscing elit.

Sed nec euismod lorem, a efficitur augue. Integer id vulputate sem. Integer lacinia ornare est, non sagittis sem commodo quis. Cras ut arcu varius, pharetra dui at, venenatis lectus. Nam dignissim tempor metus, quis vulputate mi tempor eget. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nec euismod lorem, a efficitur augue. Integer id vulputate sem. Integer lacinia ornare est, non sagittis sem commodo quis. Cras ut arcu varius, pharetra dui at, venenatis lectus. Nam dignissim tempor metus, quis vulputate mi tempor eget. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nec euismod lorem, a efficitur augue. Integer id vulputate sem. Integer lacinia ornare est, non sagittis sem commodo quis. Cras ut arcu varius, pharetra dui at, venenatis lectus. Nam dignissim tempor metus, quis vulputate mi tempor eget. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nec euismod lorem, a efficitur augue. Integer id vulputate sem. Integer lacinia ornare est, non sagittis sem commodo quis. Cras ut arcu varius, pharetra dui at, venenatis lectus. Nam dignissim tempor metus, quis vulputate mi tempor eget. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nec euismod lorem, a efficitur augue. Integer id vulputate sem. Integer lacinia ornare est, non sagittis sem commodo quis. Cras ut arcu varius, pharetra dui at, venenatis lectus. Nam dignissim tempor metus, quis vulputate mi tempor eget.''',
                      style: TextStyle(
                        fontFamily: 'Benne',
                        fontWeight: FontWeight.w400,
                        fontSize: mqSize.width * 0.045,
                        color: Colors.white,
                        height: 1.6,
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
}
