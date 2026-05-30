import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';
import 'package:moon_launch/Front-end/widgets/image_selector.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size mqSize = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        toolbarHeight: 65,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        title: Padding(
          padding: const EdgeInsets.only(top: 25.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
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
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontFamily: 'BernardMTCondensed',
                          fontWeight: FontWeight.w400,
                          fontSize: mqSize.width*0.07,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: mqSize.height*0.07,),
              
                  Stack(
                    children: [
                      Container(
                        width: mqSize.height*0.15,
                        height: mqSize.height*0.15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(98),
                            ),
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(
                                _profileImage!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                                  : Image(image: AssetImage('assets/images/s2.png',),height: 109,width: 109,fit: BoxFit.cover,)
                            ),
                          ),
                        ),
                      ),
              
                      Positioned(
                        bottom: 0,
                        right: 10,
                        child: InkWell(
                          onTap: () {
                            ImageSelector.show(
                              context: context,
                              onImageSelected: (source) {
                                _pickImage(source);
                              },
                            );
                          },
                          child: Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2A1216),
                                  Color(0xFF9A1117),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: mqSize.height*0.05,),
              
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.01),
                    child: TextField(
                      decoration: InputDecoration(
                        hint: Text(
                          "Username",
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
                  SizedBox(height: mqSize.height*0.01,),
              
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.01),
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
                  SizedBox(height: mqSize.height*0.01,),
                    Padding(
                    padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.01),
                    child: TextField(
                      decoration: InputDecoration(
                        hint: Text(
                          "Phone Number",
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
                  SizedBox(height: mqSize.height*0.05,),
              
                  InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: mqSize.width*0.01),
                      child: Container(
                        height: mqSize.height*0.07,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF2A1216),
                              Color(0xFF9A1117),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Center(
                          child: Text(
                            'Update',
                            style: TextStyle(
                              fontFamily: 'BernardMTCondensed',
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              fontSize: mqSize.width*0.06,
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
      ),
    );
  }
}
