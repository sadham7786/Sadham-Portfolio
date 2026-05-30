import 'package:flutter/material.dart';
import 'package:moon_launch/Back-end/Services/token_service.dart';
import 'package:moon_launch/Back-end/Services/wallet_service.dart';
import 'package:moon_launch/Front-end/Extra%20Widgets/buy_screen.dart';
import 'package:moon_launch/Front-end/Extra%20Widgets/sell_screen.dart';
import 'package:moon_launch/Front-end/Extra%20Widgets/swap_screen.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';
import 'package:moon_launch/Front-end/widgets/wallet_chart.dart';

class CoinDetailScreen extends StatefulWidget {
  final String? tokenAddress;
  const CoinDetailScreen({super.key, this.tokenAddress});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  final LinearGradient _circleGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2A1216),
      Color(0xFF9A1117),
    ],
  );

  final LinearGradient _topIconCircleGradient = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFFE600),
      Color(0xFFDB2519),
    ],
  );

  int _selectedRangeIndex = 0;
  final List<String> _ranges = ['Live', '1D', '1M', '3M', '1Y', 'All'];

  TokenModel? _token;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.tokenAddress != null) {
      _loadToken();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadToken() async {
    try {
      final token = await TokenService.getTokenDetail(widget.tokenAddress!);
      setState(() {
        _token = token;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: mq.height * 0.12,
        titleSpacing: mq.width * 0.05,
        title: Padding(
          padding: EdgeInsets.only(top: mq.height * 0.018),
          child: Row(
            children: [
              _topBackCircleButton(
                mq: mq,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/moon_launch_logo.png',
                width: mq.width * 0.32,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: mq.width * 0.05,
              right: mq.width * 0.05,
              top: mq.height * 0.02,
              bottom: mq.height * 0.06,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 COIN HEADER
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                   /* SizedBox(
                      width: mq.width * 0.15,
                      height: mq.width * 0.15,
                      child: Image.asset('assets/images/bit_coin.png'),
                    ),*/
                    //_tokenLogo(_token??TokenModel(tokenAddress: ''), size: mq.width * 0.15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(mq.width * 0.15),
                      child: _token?.logo != null && _token!.logo!.isNotEmpty
                          ? Image.network(
                        _token!.logo!,
                        width: mq.width * 0.15,
                        height: mq.width * 0.15,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _coinImage(
                          size: mq.width * 0.14,
                          text: _token?.displayName.isNotEmpty == true
                              ? getFirstValidChar(_token?.displayName)
                              : '',
                        ),
                      )
                          : _coinImage(
                        size: mq.width * 0.15,
                        text: _token?.displayName.isNotEmpty == true
                            ? getFirstValidChar(_token?.displayName ?? '')
                            : '',
                      ),
                    ),
                    SizedBox(width: mq.width * 0.03),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _token?.displayName??'',
                          style: TextStyle(
                            fontFamily: 'BernardMTCondensed',
                            fontSize: mq.width * 0.047,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: mq.height * 0.003),
                        Row(
                          children: [
                            Text(
                              _token?.symbol ?? '',
                              style: TextStyle(
                                fontFamily: 'Benne',
                                fontWeight: FontWeight.bold,
                                fontSize: mq.width * 0.045,
                                color: const Color(0xFFC9C9C9),
                              ),
                            ),
                          /*  Text(
                              '     Averge (\$7,765)',
                              style: TextStyle(
                                fontFamily: 'Benne',
                                fontSize: mq.width * 0.035,
                                color: const Color(0xFFC9C9C9),
                              ),
                            ),*/
                          ],
                        ),
                      ],
                    ),
                    /*const Spacer(),
                    Image.asset('assets/images/heart.png', height: 45),
                    SizedBox(width: mq.width * 0.03),
                    Image.asset('assets/images/share.png', height: 45),*/
                  ],
                ),

                SizedBox(height: mq.height * 0.02),

                /// 🔹 PRICE
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'BernardMTCondensed',
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: '${_token?.displayPrice??0.0}',
                        style: TextStyle(
                          fontSize: mq.width * 0.10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: Text(
                          _token?.priceCurrency??'USD',
                          style: TextStyle(
                            fontSize: mq.width * 0.05,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: mq.height * 0.008),

                /*Row(
                  children: [
                    Icon(Icons.arrow_drop_up,
                        color: Colors.green, size: mq.width * 0.07),
                    Text(
                      '0.72%',
                      style: TextStyle(
                        fontFamily: 'BernardMTCondensed',
                        fontSize: mq.width * 0.04,
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),*/

                /*SizedBox(height: mq.height * 0.015),

                /// 📈 CHART
                SizedBox(
                  height: mq.height * 0.23,
                  width: mq.width * 0.92,
                  child: const WalletChart(),
                ),

                SizedBox(height: mq.height * 0.008),

                /// 🔥 RANGE SELECTOR (BELOW GRAPH)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_ranges.length, (index) {
                    final bool isActive = _selectedRangeIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRangeIndex = index;
                        });
                      },
                      child: Row(
                        children: [
                          if (_ranges[index] == 'Live') ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            _ranges[index],
                            style: TextStyle(
                              fontFamily: 'Benne',
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),*/

                SizedBox(height: mq.height * 0.008),

                /// 🔘 ACTION BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _filledGradientActionButton(
                      mq: mq,
                      icon: Icons.add,
                      label: 'Buy',
                      onTap: _token == null
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BuyScreen(
                                    tokenAddress: _token!.tokenAddress,
                                    tokenName: _token!.displayName,
                                    tokenSymbol: _token!.symbol,
                                    tokenLogo: _token!.logo,
                                  ),
                                ),
                              ),
                    ),
                    SizedBox(width: mq.width * 0.05),
                    _filledGradientActionButton(
                      mq: mq,
                      icon: Icons.arrow_upward,
                      label: 'Send',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) =>  SellScreen(token: WalletTokenModel(
                          tokenAddress: _token!.tokenAddress,
                          name: _token!.name,
                          symbol: _token!.symbol,
                          logo: _token!.logo,
                          decimals: int.tryParse(_token!.decimals ?? '18') ?? 18,
                          balance: '0',
                        ))),
                      ),
                    ),
                    SizedBox(width: mq.width * 0.05),
                    _filledGradientActionButton(
                      mq: mq,
                      icon: Icons.swap_vert,
                      label: 'Swap',
                      onTap: () {
                        if (_token == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SwapScreen(
                              token: WalletTokenModel(
                                tokenAddress: _token!.tokenAddress,
                                name: _token!.name,
                                symbol: _token!.symbol,
                                logo: _token!.logo,
                                decimals: int.tryParse(_token!.decimals ?? '18') ?? 18,
                                balance: '0',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                /*SizedBox(height: mq.height * 0.02),

                /// 🔻 ABOUT COIN
                Row(
                  children: [
                    Text(
                      'About Coin',
                      style: TextStyle(
                        fontFamily: 'BernardMTCondensed',
                        fontSize: mq.width * 0.07,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 15),
                    Image.asset('assets/images/flower.png', height: 26),
                    Image.asset('assets/images/divider.png', height: 24),
                    SizedBox(width: 5),
                    Image.asset('assets/images/3_people.png', height: 28),
                    SizedBox(width: 5),
                    Image.asset('assets/images/divider.png', height: 24),
                    Image.asset('assets/images/tick.png', height: 34),
                  ],
                ),

                SizedBox(height: mq.height * 0.012),

                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                  'Donec a pharetra augue. Nunc eu mauris arcu. Phasellus diam nibh, '
                  'rutrum id eros in, viverra commodo elit.',
                  style: TextStyle(
                    fontFamily: 'Benne',
                    fontSize: mq.width * 0.037,
                    color: Colors.white.withOpacity(0.75),
                    height: 1.45,
                  ),
                ),*//*SizedBox(height: mq.height * 0.02),

                /// 🔻 ABOUT COIN
                Row(
                  children: [
                    Text(
                      'About Coin',
                      style: TextStyle(
                        fontFamily: 'BernardMTCondensed',
                        fontSize: mq.width * 0.07,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 15),
                    Image.asset('assets/images/flower.png', height: 26),
                    Image.asset('assets/images/divider.png', height: 24),
                    SizedBox(width: 5),
                    Image.asset('assets/images/3_people.png', height: 28),
                    SizedBox(width: 5),
                    Image.asset('assets/images/divider.png', height: 24),
                    Image.asset('assets/images/tick.png', height: 34),
                  ],
                ),

                SizedBox(height: mq.height * 0.012),

                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                  'Donec a pharetra augue. Nunc eu mauris arcu. Phasellus diam nibh, '
                  'rutrum id eros in, viverra commodo elit.',
                  style: TextStyle(
                    fontFamily: 'Benne',
                    fontSize: mq.width * 0.037,
                    color: Colors.white.withOpacity(0.75),
                    height: 1.45,
                  ),
                ),*/

               /* SizedBox(height: mq.height * 0.025),

                /// 🌐 SOCIAL ICONS
                Row(
                  children: [
                    _gradientIconContainer(
                        mq: mq,
                        imagePath: 'assets/images/www.png',
                        onTap: () {}),
                    SizedBox(width: mq.width * 0.03),
                    _gradientIconContainer(
                        mq: mq,
                        imagePath: 'assets/images/twitter.png',
                        onTap: () {}),
                    SizedBox(width: mq.width * 0.03),
                    _gradientIconContainer(
                        mq: mq,
                        imagePath: 'assets/images/telegram.png',
                        onTap: () {}),
                  ],
                ),*/

                SizedBox(height: mq.height * 0.025),

                disclaimer(),

                SizedBox(height: mq.height * 0.10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tokenLogo(TokenModel token, {required double size}) {
    if (token.logo != null && token.logo!.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size),
          child: Image.network(
            token.logo!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _coinImage(size: size,text: token.displayName.isNotEmpty == true
                ? getFirstValidChar(token.displayName)
                : ''),
          ),
        ),
      );
    }
    return _coinImage(size: size,text: token.displayName.isNotEmpty == true
        ? getFirstValidChar(token.displayName)
        : '');
  }

  String getFirstValidChar(String? text) {
    if (text == null || text.isEmpty) return '';

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
        return char.toUpperCase();
      }
    }
    return '';
  }

  Widget _coinImage({required double size,required String text} ) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child:  Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            //gradient: _circleGradient,
          ),
          child: Center(
            child: Text(text,style: TextStyle(color: Colors.black,fontSize: 20),),
          ),
        ),/*Image.asset('assets/images/bit_coin.png')*/
      ),
    );
  }
  /// ================= HELPERS =================

  Widget _topBackCircleButton({required Size mq, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: mq.width * 0.11,
        height: mq.width * 0.11,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.10),
        ),
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: mq.width * 0.045,
          ),
        ),
      ),
    );
  }

  Widget _filledGradientActionButton({
    required Size mq,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final double size = mq.width * 0.165;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _circleGradient,
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Benne',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientIconContainer({
    required Size mq,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    final double size = mq.width * 0.15;
    final double ring = (size * 0.06).clamp(3.0, 6.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: EdgeInsets.all(ring),
          child: ClipOval(
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget disclaimer(){
    final Size mq = MediaQuery.of(context).size;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:  [
          Text(
            "Disclaimer",
            style: TextStyle(
              fontFamily: 'Benne',
              color: Colors.yellowAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "MoonLaunch is not a cryptocurrency exchange and does not provide investment advice. The content of this app is for informational and entertainment purposes only and does not constitute an offer or recommendation of any financial product or service.\n\nDigital assets displayed in the app are highly volatile and may fluctuate significantly in value. They are for entertainment purposes only and should not be considered an investment, currency or anything of value. Digital assets can be extremely volatile and unpredictable. Price data and other information presented may be inaccurate or delayed.\n\nAll interactions with digital assets are executed directly by the user through their personal wallet and third-party Binance (BNB) blockchain protocols. MoonLaunch does not custody funds, execute transactions, or act as an intermediary.\n\nMoonLaunch is a user interface for accessing decentralized Binance (BNB) blockchain protocols and does not directly facilitate, control digital asset transactions, nor endorse any crypto currencies.",
            style:  TextStyle(
              fontFamily: 'Benne',
              fontSize: mq.width * 0.037,
              color: Colors.white.withOpacity(0.75),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
