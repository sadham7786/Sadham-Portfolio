import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moon_launch/Back-end/Controllers/session_controller.dart';
import 'package:moon_launch/Back-end/Services/auth_service.dart';
import 'package:moon_launch/Front-end/auth_screens/login_screen.dart';
import 'package:moon_launch/Front-end/views/privacy_policy_screen.dart';
import 'package:moon_launch/Front-end/views/transaction_history_screen.dart';
import 'package:moon_launch/Front-end/widgets/confirm_dialog.dart';
import 'package:moon_launch/Front-end/widgets/notifiers.dart';
import 'package:moon_launch/Front-end/widgets/profile_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool startNotification = true;
  double _selectedRating = 0;

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality:
            50, // Reduce quality to keep base64 string size reasonable
      );

      if (image != null) {
        final userId = SessionController.instance.userId;
        final userName = SessionController.instance.userName;

        if (userId != null && userName != null) {
          // Show loading indicator
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(color: Color(0xFFDB2519)),
              ),
            );
          }

          try {
            final bytes = await File(image.path).readAsBytes();
            final base64Image = base64Encode(bytes);

            // Upload to server
            var data = await AuthService.editProfile(
              userId: userId,
              name: userName,
              imageBase64: base64Image,
            );

            // Update local session and UI
            await SessionController.instance.updateProfileLocal(
              profilePick: '${data['data']['profile_pick']}',
            );

            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile picture updated successfully'),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update profile: $e')),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User information not found. Please log in again.'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;
    final Size mqSize = MediaQuery.of(context).size;

    // ✅ safe bottom for gesture bar / notch
    final double bottomSafe = MediaQuery.of(context).padding.bottom;

    // ✅ fixed bottom space (bottom nav height + safe)
    final double bottomSpace = kBottomNavigationBarHeight + bottomSafe;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,

        // ✅ Left side (Text + icon) perfectly centered vertically
        titleSpacing: mq.width * 0.045,

        // ✅ Right side (Logo) same top padding
        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: mq.width * 0.045,
              top: mq.height * 0.02, // ✅ SAME TOP as left
            ),
            child: Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/moon_launch_logo.png',
                width: 104,
                height: 31,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),

      body: ProfileBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(), // ✅ controlled scroll
                padding: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: 10, // ✅ reduced top gap
                  bottom: bottomSpace, // ✅ FIXED bottom gap
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - bottomSpace,
                  ),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _showImagePickerOptions,
                            child: Container(
                              width: mqSize.height * 0.13,
                              height: mqSize.height * 0.13,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Container(
                                  height: 109,
                                  width: 109,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    shape: BoxShape.circle,
                                    image:
                                        SessionController
                                                .instance
                                                .profilePick !=
                                            null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              'https://backend.moonlaunchapp.com/${SessionController.instance.profilePick!}',
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child:
                                      SessionController.instance.profilePick ==
                                          null
                                      ? const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                SessionController.instance.userName ?? 'User',
                                style: TextStyle(
                                  fontFamily: 'BernardMTCondensed',
                                  fontWeight: FontWeight.w400,
                                  fontSize: mqSize.width * 0.045,
                                  color: const Color(0xFFC9C9C9),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Image.asset(
                                "assets/images/tick.png",
                                height: 34,
                                width: 34,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            SessionController.instance.userEmail ?? '',
                            style: TextStyle(
                              fontFamily: 'Benne',
                              fontWeight: FontWeight.w400,
                              fontSize: mqSize.width * 0.045,
                              color: const Color(0xFFC9C9C9),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: mqSize.height * 0.02),

                      Column(
                        children: [
                          Container(
                            height: mqSize.height * 0.18,
                            width: mqSize.height * 0.4,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                color: const Color(0xffDB2519),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 12.0,
                                left: 15,
                                right: 15,
                              ),
                              child: Column(
                                children: [
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Wallet Address",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        fontSize: 16.5,
                                        fontFamily: "Benne",
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      SessionController
                                              .instance
                                              .walletAddress ??
                                          'No wallet',
                                      style: const TextStyle(
                                        fontFamily: "Benne",
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: GestureDetector(
                                      onTap: () {
                                        final addr = SessionController
                                            .instance
                                            .walletAddress;
                                        if (addr != null) {
                                          Clipboard.setData(
                                            ClipboardData(text: addr),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Address copied'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        height: 35,
                                        width: mqSize.height * 0.12,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xff2A1216),
                                              Color(0xff9A1117),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                        ),
                                        child: const Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            "Copy Address",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11,
                                              fontFamily: "BernardMTCondensed",
                                              color: Colors.white,
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

                          SizedBox(height: mqSize.height * 0.04),

                          _menuItem(
                            mqSize: mqSize,
                            title: 'Transaction History',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TransactionHistoryScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: mqSize.height * 0.04),

                          _menuItem(
                            mqSize: mqSize,
                            title: 'Legal and Privacy Policy',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: mqSize.height * 0.04),

                          InkWell(
                            onTap: () => _showRatingDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Rate MoonLaunch',
                                    style: TextStyle(
                                      fontFamily: 'Benne',
                                      fontWeight: FontWeight.w400,
                                      fontSize: mqSize.width * 0.045,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Image(
                                    image: AssetImage(
                                      "assets/images/solar_star-outline.png",
                                    ),
                                    height: 24,
                                    width: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: mqSize.height * 0.04),

                      InkWell(
                        onTap: () {
                          AppDialogs.showConfirmDialog(
                            context: context,
                            title: 'Delete Account',
                            message:
                                'This action cannot be undone. Are you sure?',
                            confirmText: 'Delete',
                            onConfirm: () {
                              _logOut();
                            },
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: mqSize.width * 0.05,
                          ),
                          child: Container(
                            height: mqSize.height * 0.06,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 2,
                                color: const Color(0xFFDB2519),
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: const Color(0xFFDB2519),
                                  size: mqSize.width * 0.07,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    fontFamily: 'BernardMTCondensed',
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFFDB2519),
                                    fontSize: mqSize.width * 0.05,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: mqSize.height * 0.02),

                      InkWell(
                        onTap: () {
                          AppDialogs.showConfirmDialog(
                            context: context,
                            title: 'Logout',
                            message: 'Are you sure you want to logout?',
                            onConfirm: () {
                              _logOut();
                            },
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: mqSize.width * 0.05,
                          ),
                          child: Container(
                            height: mqSize.height * 0.07,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Center(
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  fontFamily: 'BernardMTCondensed',
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  fontSize: mqSize.width * 0.06,
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required Size mqSize,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Benne',
                fontWeight: FontWeight.w400,
                fontSize: mqSize.width * 0.045,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: mqSize.width * 0.045,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    final Size mqSize = MediaQuery.of(context).size;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0C0C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDB2519), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Rate MoonLaunch",
                      style: TextStyle(
                        fontFamily: "BernardMTCondensed",
                        fontSize: mqSize.width * 0.06,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "How was your experience?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Benne",
                        fontSize: mqSize.width * 0.04,
                        color: const Color(0xFFC9C9C9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final isSelected = starValue <= _selectedRating;
                        return InkWell(
                          onTap: () {
                            setStateDialog(() {
                              _selectedRating = starValue.toDouble();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              isSelected ? Icons.star : Icons.star_border,
                              size: 34,
                              color: isSelected
                                  ? const Color(0xFFFFE600)
                                  : const Color(0xFFC9C9C9),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFDB2519),
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontFamily: "BernardMTCondensed",
                                    color: Color(0xFFDB2519),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF0C0C0C),
                                  content: Text(
                                    _selectedRating == 0
                                        ? "Please select a rating"
                                        : "Thanks! You rated $_selectedRating ⭐",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Benne",
                                    ),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFE600),
                                    Color(0xFFDB2519),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  "Submit",
                                  style: TextStyle(
                                    fontFamily: "BernardMTCondensed",
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _logOut() async {
    await SessionController.instance.logout();
    selectedPageNotifier.value = 0;
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
}
