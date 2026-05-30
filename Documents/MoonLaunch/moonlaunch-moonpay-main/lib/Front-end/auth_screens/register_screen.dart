import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/views/privacy_policy_screen.dart';
import 'package:moon_launch/Front-end/views/term_condition_screen.dart';
import 'package:moon_launch/Back-end/Services/auth_service.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';
import 'package:moon_launch/Front-end/auth_screens/two_factor.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool termAndConditions = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController confirmCtrl = TextEditingController();

  String _tempName = "";
  String _tempEmail = "";
  String _tempPassword = "";

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size mqSize = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/moon_launch_logo.png',
                          width: mqSize.width * 0.7,
                        ),
                        SizedBox(height: mqSize.height * 0.07),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: mqSize.width * 0.08,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Sign Up',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontFamily: 'BernardMTCondensed',
                                  fontWeight: FontWeight.w400,
                                  fontSize: mqSize.width * 0.08,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: mqSize.height * 0.01),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: mqSize.width * 0.08,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Hello! Enter Your Account details',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontFamily: 'Benne',
                                  fontWeight: FontWeight.w400,
                                  fontSize: mqSize.width * 0.04,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: mqSize.height * 0.02),

                        _input(nameCtrl, "Username", mqSize),
                        _input(emailCtrl, "Email Address", mqSize),

                        _password(
                          controller: passCtrl,
                          hint: "Password",
                          visible: isPasswordVisible,
                          toggle: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                          mq: mqSize,
                        ),

                        _password(
                          controller: confirmCtrl,
                          hint: "Confirm Password",
                          visible: isConfirmPasswordVisible,
                          toggle: () {
                            setState(() {
                              isConfirmPasswordVisible =
                                  !isConfirmPasswordVisible;
                            });
                          },
                          mq: mqSize,
                        ),

                        SizedBox(height: mqSize.height * 0.03),

                        /// ✅ TERMS & PRIVACY (DESIGN SAME, OVERFLOW FIX ONLY)
                        Padding(
                          padding: EdgeInsets.only(
                            left: mqSize.width * 0.055,
                            right: mqSize.width * 0.08,
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    termAndConditions = !termAndConditions;
                                  });
                                },
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: termAndConditions
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFFFFE600),
                                              Color(0xFFDB2519),
                                            ],
                                          )
                                        : null,
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: termAndConditions
                                      ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              SizedBox(width: mqSize.width * 0.02),
                              Text(
                                'I agree with all ',
                                style: TextStyle(
                                  fontFamily: 'Benne',
                                  fontSize: mqSize.width * 0.028,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const TermConditionScreen(),
                                    ),
                                  );
                                },
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        Color(0xFFFFE600),
                                        Color(0xFFDB2519),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    'Terms & Conditions',
                                    style: TextStyle(
                                      fontFamily: 'Benne',
                                      fontSize: mqSize.width * 0.028,
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                ' and ',
                                style: TextStyle(
                                  fontFamily: 'Benne',
                                  fontSize: mqSize.width * 0.028,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PrivacyPolicyScreen(),
                                    ),
                                  );
                                },
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        Color(0xFFFFE600),
                                        Color(0xFFDB2519),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      fontFamily: 'Benne',
                                      fontSize: mqSize.width * 0.032,
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: mqSize.height * 0.025),

                        /// 🔘 SIGN UP BUTTON (LOADER INSIDE)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: mqSize.width * 0.05,
                          ),
                          child: InkWell(
                            onTap: isLoading ? null : _onSignup,
                            child: Container(
                              height: mqSize.height * 0.06,
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
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Sign Up',
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

                        SizedBox(height: mqSize.height * 0.03),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                fontFamily: 'BernardMTCondensed',
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: ShaderMask(
                                shaderCallback: (bounds) {
                                  return const LinearGradient(
                                    colors: [
                                      Color(0xFFFFE600),
                                      Color(0xFFDB2519),
                                    ],
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontFamily: 'Benne',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= LOGIC =================

  Future<void> _onSignup() async {
    final String name = nameCtrl.text.trim();
    final String email = emailCtrl.text.trim();
    final String pass = passCtrl.text;
    final String confirm = confirmCtrl.text;

    // 1) FIRST MESSAGE: if anything missing -> one generic msg
    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showSnackThemed("Please fill all the fields");
      return;
    }

    // 2) THEN detailed validations
    if (!email.contains("@")) {
      _showSnackThemed("Please enter a valid email");
      return;
    }

    if (pass.length < 8) {
      _showSnackThemed("Password must be at least 8 characters");
      return;
    }

    // ✅ Special char: any non-alphanumeric
    final RegExp specialChar = RegExp(r'[^a-zA-Z0-9]');
    if (!specialChar.hasMatch(pass)) {
      _showSnackThemed("Password must contain at least 1 special character");
      return;
    }

    if (pass != confirm) {
      _showSnackThemed("Passwords do not match");
      return;
    }

    if (!termAndConditions) {
      _showSnackThemed("Please accept Terms & Conditions");
      return;
    }

    setState(() => isLoading = true);

    _tempName = name;
    _tempEmail = email;
    _tempPassword = pass;

    try {
      print("📤 Signup OTP API hit: $_tempEmail");
      final res = await AuthService.sendOtp(_tempEmail);
      print("📥 Signup OTP API response: $res");

      setState(() => isLoading = false);

      if (mounted) {
        _showSuccessPopup(_tempName, _tempEmail, _tempPassword);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("❌ Signup OTP error: $e");
      final String msg = _extractMessage(e);
      _showSnackThemed(msg.isNotEmpty ? msg : "Signup failed");
    }
  }

  void _showSuccessPopup(String name, String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDB2519), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_read_outlined, color: Color(0xFFDB2519), size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Confirm Your Email',
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hello $name, we\'ve sent a verification code to $email. Please check your inbox (and spam/junk folder if you don’t see it) to proceed.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Benne',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TwoFactor.signup(
                          name: name,
                          email: email,
                          password: password,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 44,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE600), Color(0xFFDB2519)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: Text(
                        'CONTINUE',
                        style: TextStyle(
                          fontFamily: 'BernardMTCondensed',
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= THEMED SNACKBAR =================

  void _showSnackThemed(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(width: 1.2, color: const Color(0xFFDB2519)),
          ),
          child: Text(
            msg,
            style: const TextStyle(fontFamily: 'Benne', color: Colors.white),
          ),
        ),
      ),
    );
  }

  String _extractMessage(dynamic res) {
    try {
      if (res is Map) {
        if (res["message"] != null) return res["message"].toString();
        if (res["error"] != null) return res["error"].toString();
        if (res["msg"] != null) return res["msg"].toString();
      }
      final s = res.toString();
      return s;
    } catch (_) {
      return "";
    }
  }

  // ================= INPUT HELPERS (DESIGN SAME) =================

  Widget _input(TextEditingController c, String h, Size mq) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: mq.width * 0.07,
      vertical: mq.height * 0.01,
    ),
    child: TextField(
      controller: c,
      decoration: InputDecoration(
        hint: Text(
          h,
          style: const TextStyle(fontFamily: 'Benne', fontSize: 15),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mq.width * 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mq.width * 0.5),
          borderSide: const BorderSide(color: Color(0xFFDB2519)),
        ),
      ),
    ),
  );

  Widget _password({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback toggle,
    required Size mq,
  }) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: mq.width * 0.07,
      vertical: mq.height * 0.01,
    ),
    child: TextField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        hint: Text(
          hint,
          style: const TextStyle(fontFamily: 'Benne', fontSize: 15),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mq.width * 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mq.width * 0.5),
          borderSide: const BorderSide(color: Color(0xFFDB2519)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: toggle,
        ),
      ),
    ),
  );
}
