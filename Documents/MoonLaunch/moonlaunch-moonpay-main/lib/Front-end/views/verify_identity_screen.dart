import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/auth_screens/otp_screen.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class VerifyIdentityScreen extends StatelessWidget {
  const VerifyIdentityScreen({super.key});

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
                    color: Color(0xFFDB2519).withOpacity(0.2),
                  ),
                  child: Padding(
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset('assets/images/verification_image.png', height: 311,width: 311,),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.07),
                  child: Row(
                    children: [
                      Text(
                        'Verify Your Identity',
                        style: TextStyle(
                          fontFamily: 'BernardMTCondensed',
                          fontWeight: FontWeight.w600,
                          fontSize: mqSize.width*0.07,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.07),
                  child: Row(
                    children: [
                      Text(
                        'Enter your mail to verify your identity',
                        style: TextStyle(
                          fontFamily: 'Benne',
                          fontWeight: FontWeight.w400,
                          fontSize: mqSize.width*0.040,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: mqSize.height*0.025,),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.07),
                  child: TextField(
                    decoration: InputDecoration(
                      hint: Text(
                        "Email Address",
                        style: TextStyle(fontFamily: 'Benne', fontSize: 15),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(mqSize.width*0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(mqSize.width*0.5),
                        borderSide: const BorderSide(color: Color(0xFFDB2519)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: mqSize.height*0.03,),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.05),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OtpScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0,right: 8),
                      child: Container(
                        height: mqSize.height*0.06,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFE600),
                              Color(0xFFDB2519),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            'Send Code',
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
                ),

              ],
            ),
          )
        ),
      ),
    );
  }
}
