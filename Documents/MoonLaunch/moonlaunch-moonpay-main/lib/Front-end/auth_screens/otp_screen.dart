import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/auth_screens/change_password_screen.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

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
                width: 109,
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
                    padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.05),
                    child: Row(
                      children: [
                        Text(
                          'Enter Code',
                          style: TextStyle(
                            fontFamily: 'BernardMTCondensed',
                            fontWeight: FontWeight.w400,
                            fontSize: mqSize.width*0.07,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.05),
                    child: Row(
                      children: [
                        Text(
                          'Enter your code to verify your identity',
                          style: TextStyle(
                            fontFamily: 'Benne',
                            fontWeight: FontWeight.w400,
                            fontSize: mqSize.width*0.04,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: mqSize.height*0.03,),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.05,),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 45,
                          height: 50,
                          child: TextField(
                            controller: otpControllers[index],
                            maxLength: 1,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Color(0xFFFFE600).withOpacity(0.1),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Color(0xFFFFE600).withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Color(0xFFFFE600).withOpacity(0.7)),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                FocusScope.of(context).nextFocus();
                              } else if (value.isEmpty && index > 0) {
                                FocusScope.of(context).previousFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: mqSize.height*0.04,),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.05),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
                        );
                      },
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
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Center(
                          child: Text(
                            'Send Code',
                            style: TextStyle(
                              fontFamily: 'BernardMTCondensed',
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              fontSize: 16,
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
}

