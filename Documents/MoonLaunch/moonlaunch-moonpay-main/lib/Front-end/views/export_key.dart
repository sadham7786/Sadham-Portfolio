import 'package:flutter/material.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';
class ExportKey extends StatefulWidget {
  const ExportKey({super.key});

  @override
  State<ExportKey> createState() => _ExportKeyState();
}

class _ExportKeyState extends State<ExportKey> {
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
                    child: Center(
                      child: Image.asset("assets/images/back1.png",height: 24,width: 24,color: Colors.white,),
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
      body: AppBackground(child: SafeArea(child: Padding(padding:
      EdgeInsets.symmetric(horizontal: 20,vertical: 17),
        child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Export Keys',
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontWeight: FontWeight.w400,
                    fontSize: mqSize.width*0.07,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: mqSize.height*0.05,),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Your Wallet",style: TextStyle(
                fontFamily: "BernardMTCondensed",
                fontSize: mqSize.width*0.054,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),),
            ),
            SizedBox(height: 7,),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Your assets are held in a self-custodial cryptocurrency wallet that you own and control. Only you have access to your private keys and secret recovery phrase. MoonLaunch does not store or control your keys.",style: TextStyle(
                fontFamily: "Benne",
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),),
            ),SizedBox(height: 20,),
            Row(
              children: [
                Image(image: AssetImage("assets/images/s1.png"),height: 45,width: 47.28,),
                SizedBox(width: 7,),
                Text("Coin",style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  fontFamily: "Benne",
                  color: Colors.white,
                ),),
                Spacer(),
                Text("C39S..Ced8",style: TextStyle(
                  fontFamily: "Benne",
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),),
                SizedBox(width: 5,),
                ShaderMask(shaderCallback:(Rect bounds){
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xffDB2519),Color(0xffFFE600)]).createShader(bounds);
                },child: Icon(Icons.copy,size: 21,),
                ),
              ],
            ),
            const Divider(
              height: 30,
              thickness: 1,
              color: Colors.grey,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Advanced",style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                fontFamily: "BernardMTCondensed",
                color: Colors.white,
              ),),
            ),
            SizedBox(height: 8,),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Export your recovery phrase to access your wallet outside of MoonLaunch.",style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                fontFamily: "Benne",
                color: Colors.white,
              ),),
            ),
            SizedBox(height: 15,),
            Row(
              children: [
                Icon(Icons.lock,size: 31,color: Colors.white,),
                SizedBox(width: 5,),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Secret Phrase",style: TextStyle(
                    fontFamily: "Benne",
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),),
                ),
                Spacer(),
                Icon(Icons.chevron_right_sharp,size: 30,color: Colors.white,)
              ],
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
