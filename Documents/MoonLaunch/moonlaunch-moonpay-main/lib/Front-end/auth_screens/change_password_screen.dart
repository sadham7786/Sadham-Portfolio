import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/auth_screens/login_screen.dart';
import '../widgets/app_background.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

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
                Image.asset('assets/images/crypto_security_icon.png', height: 295,width: 301,),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.05),
                  child: Row(
                    children: [
                      Text(
                        'Change Password',
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
                        'Enter new password',
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
                SizedBox(height: mqSize.height*0.015,),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.05),
                  child: TextField(
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      hint: Text(
                        "New Password",
                        style: TextStyle(fontFamily: 'Benne', fontSize: 15),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(mqSize.width*0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(mqSize.width*0.5),
                        borderSide: const BorderSide(color: Color(0xFFDB2519)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: mqSize.height*0.01,),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.05),
                  child: TextField(
                    obscureText: !isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      hint: Text(
                        "Confirm New Password",
                        style: TextStyle(fontFamily: 'Benne', fontSize: 15),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(mqSize.width*0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(mqSize.width*0.5),
                        borderSide: const BorderSide(color: Color(0xFFDB2519)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            isConfirmPasswordVisible = !isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: mqSize.height*0.03,),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.05),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );                    },
                    child: Container(
                      height: mqSize.height*0.06,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFE600), Color(0xFFDB2519),],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          'Update',
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

