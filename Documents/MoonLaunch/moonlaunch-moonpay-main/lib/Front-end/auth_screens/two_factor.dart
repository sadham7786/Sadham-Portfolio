import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moon_launch/Back-end/Controllers/session_controller.dart';
import 'package:moon_launch/Back-end/Services/auth_service.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';
import 'package:moon_launch/Front-end/widgets/widget_tree.dart';

class TwoFactor extends StatefulWidget {
  final String? name;
  final String email;
  final String password;
  final bool isLoginFlow;
  final Widget? onSuccessNavigateTo;

  const TwoFactor._internal({
    super.key,
    required this.email,
    required this.password,
    required this.isLoginFlow,
    this.name,
    this.onSuccessNavigateTo,
  });

  factory TwoFactor.signup({
    required String name,
    required String email,
    required String password,
    Widget? onSuccessNavigateTo,
  }) {
    return TwoFactor._internal(
      email: email,
      password: password,
      name: name,
      isLoginFlow: false,
      onSuccessNavigateTo: onSuccessNavigateTo,
    );
  }

  factory TwoFactor.login({
    required String email,
    required String password,
    Widget? onSuccessNavigateTo,
  }) {
    return TwoFactor._internal(
      email: email,
      password: password,
      isLoginFlow: true,
      onSuccessNavigateTo: onSuccessNavigateTo,
    );
  }

  @override
  State<TwoFactor> createState() => _TwoFactorState();
}

class _TwoFactorState extends State<TwoFactor> {
  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocusNode = FocusNode();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(otpFocusNode);
      }
    });
  }

  @override
  void dispose() {
    otpController.dispose();
    otpFocusNode.dispose();
    super.dispose();
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
                  ),
                ),
              ),
              Image.asset(
                'assets/images/moon_launch_logo.png',
                width: 109,
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
                Image.asset(
                  'assets/images/verification_image.png',
                  height: 300,
                ),

                Text(
                  'Enter Code',
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontSize: mqSize.width * 0.07,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 10),

                Text(
                  'Enter your code to verify your identity',
                  style: TextStyle(
                    fontFamily: 'Benne',
                    fontSize: mqSize.width * 0.04,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 30),

                // ✅ SAFE OTP INPUT (VISIBLE)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mqSize.width * 0.05),
                  child: TextField(
                    controller: otpController,
                    focusNode: otpFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 20,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFFFE600).withOpacity(0.1),
                      hintText: '------',
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        letterSpacing: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: mqSize.width * 0.05),
                  child: InkWell(
                    onTap: isLoading ? null : _verifyOtp,
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Center(
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Verify Code',
                                style: TextStyle(
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

  Future<void> _verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) return;

    setState(() => isLoading = true);

    try {
      final res = widget.isLoginFlow
          ? await AuthService.verifyLoginOtp(
              email: widget.email,
              password: widget.password,
              otp: otp,
            )
          : await AuthService.verifyOtp(
              name: widget.name ?? "",
              email: widget.email,
              password: widget.password,
              otp: otp,
            );

      if (res['user'] != null) {
        await SessionController.instance
            .saveSession(Map<String, dynamic>.from(res['user']));
      }

      if (!mounted) return;
      setState(() => isLoading = false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => widget.onSuccessNavigateTo ?? const WidgetTree(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }
}