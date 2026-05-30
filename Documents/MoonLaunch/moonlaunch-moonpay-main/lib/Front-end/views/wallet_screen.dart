import 'package:flutter/material.dart';
import 'package:moon_launch/Back-end/Controllers/session_controller.dart';
import 'package:moon_launch/Back-end/Services/wallet_service.dart';
import 'package:moon_launch/Front-end/Extra%20Widgets/buy_screen.dart';
import 'package:moon_launch/Front-end/Extra%20Widgets/receive_screen.dart';
import 'package:moon_launch/Front-end/Extra%20Widgets/sell_screen.dart';
import 'package:moon_launch/Front-end/Extra%20Widgets/swap_screen.dart';
import 'package:moon_launch/Front-end/widgets/profile_background.dart';
import 'package:moon_launch/Front-end/widgets/wallet_chart.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final LinearGradient _circleGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
  );

  int _selectedRangeIndex = 0;
  final List<String> _ranges = ['Live', '1D', '1M', '3M', '1Y', 'All'];

  WalletBalanceModel? _wallet;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final address = SessionController.instance.walletAddress;
    if (address == null || address.isEmpty) {
      setState(() {
        _error = 'No wallet address found';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final wallet = await WalletService.getBalance(address);
      setState(() {
        _wallet = wallet;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showCoinSelectionPopup({
    required String title,
    required Function(WalletTokenModel) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'BernardMTCondensed',
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _wallet?.tokens.length ?? 0,
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.white.withOpacity(0.1),
                    height: 24,
                  ),
                  itemBuilder: (context, index) {
                    final token = _wallet!.tokens[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(token);
                      },
                      child: Row(
                        children: [
                          _tokenLogo(token, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  token.displayName,
                                  style: const TextStyle(
                                    fontFamily: 'BernardMTCondensed',
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  token.symbol ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Benne',
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            token.balance,
                            style: const TextStyle(
                              fontFamily: 'BernardMTCondensed',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInteractionPopup(VoidCallback onContinue) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF9A1117), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF9A1117),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Protocol Interaction',
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This interaction will be executed directly through third-party Binance (BNB) blockchain protocols, including decentralized liquidity protocols.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Benne',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () {
                    Navigator.pop(context); // Close dialog
                    onContinue();
                  },
                  child: Container(
                    height: 44,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
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

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleSpacing: mq.width * 0.045,
        title: Padding(
          padding: EdgeInsets.only(top: mq.height * 0.02),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Wallet Value',
                style: TextStyle(
                  fontFamily: 'Benne',
                  fontSize: mq.width * 0.038,
                  color: const Color(0xFFC9C9C9),
                ),
              ),
              SizedBox(width: mq.width * 0.02),
              Image.asset(
                'assets/images/close_eye_icon.png',
                width: mq.width * 0.06,
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: mq.width * 0.045,
              top: mq.height * 0.02,
            ),
            child: Image.asset(
              'assets/images/moon_launch_logo.png',
              width: 104,
              height: 31,
            ),
          ),
        ],
      ),
      body: ProfileBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadBalance,
            color: const Color(0xFFFFE600),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // BNB balance
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: mq.width * 0.05,
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_loading)
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: mq.height * 0.01,
                                  ),
                                  child: const SizedBox(
                                    height: 28,
                                    width: 28,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFFE600),
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              else if (_error != null)
                                GestureDetector(
                                  onTap: _loadBalance,
                                  child: Text(
                                    'Your wallet has no value.',
                                    style: TextStyle(
                                      fontFamily: 'Benne',
                                      fontSize: mq.width * 0.038,
                                      color: const Color(0xFFFFE600),
                                    ),
                                  ),
                                )
                              else ...[
                                // USD value — big
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontFamily: 'BernardMTCondensed',
                                      color: Colors.white,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _wallet?.displayUsd ?? '--',
                                        style: TextStyle(
                                          fontSize: mq.width * 0.090,
                                        ),
                                      ),
                                      WidgetSpan(
                                        alignment:
                                            PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 3,
                                          ),
                                          child: Text(
                                            'usd',
                                            style: TextStyle(
                                              fontFamily: 'BernardMTCondensed',
                                              fontSize: mq.width * 0.038,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // BNB balance — smaller below
                                Text(
                                  '${_wallet?.displayBnb ?? '--'} BNB',
                                  style: TextStyle(
                                    fontFamily: 'BernardMTCondensed',
                                    fontSize: mq.width * 0.052,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                              if (!_loading && _error == null)
                                Text(
                                  SessionController.instance.walletAddress !=
                                          null
                                      ? '${SessionController.instance.walletAddress!.substring(0, 6)}...${SessionController.instance.walletAddress!.substring(SessionController.instance.walletAddress!.length - 4)}'
                                      : '',
                                  style: TextStyle(
                                    fontFamily: 'Benne',
                                    fontSize: mq.width * 0.032,
                                    color: Colors.white54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _actionButton(
                            mq: mq,
                            icon: Icons.add,
                            label: 'Buy',
                            onTap: () {
                              if (_wallet == null || _wallet!.tokens.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'You do not have any tokens to buy in your wallet.\nPlease buy some tokens from the Home Screen.',
                                      style: TextStyle(
                                        fontFamily: 'Benne',
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Color(0xFF1A1A1A),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                _showCoinSelectionPopup(
                                  title: 'Select Token to Buy',
                                  onSelected: (token) {
                                    _showInteractionPopup(() {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BuyScreen(
                                            tokenAddress: token.tokenAddress,
                                            tokenName: token.displayName,
                                            tokenSymbol: token.symbol,
                                            tokenLogo: token.logo,
                                          ),
                                        ),
                                      );
                                    });
                                  },
                                );
                              }
                            },
                          ),
                          SizedBox(width: mq.width * 0.05),
                          _actionButton(
                            mq: mq,
                            icon: Icons.arrow_upward,
                            label: 'Send',
                            onTap: () {
                              if (_wallet == null || _wallet!.tokens.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'You do not have any tokens to send in your wallet.\nPlease buy some tokens from the Home Screen.',
                                      style: TextStyle(
                                        fontFamily: 'Benne',
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Color(0xFF1A1A1A),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                _showCoinSelectionPopup(
                                  title: 'Select Token to Send',
                                  onSelected: (token) {
                                    _showInteractionPopup(() {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SellScreen(token: token),
                                        ),
                                      );
                                    });
                                  },
                                );
                              }
                            },
                          ),
                          SizedBox(width: mq.width * 0.05),
                          _actionButton(
                            mq: mq,
                            icon: Icons.arrow_downward,
                            label: 'Receive',
                            onTap: () {
                              _showInteractionPopup(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ReceiveScreen(),
                                  ),
                                );
                              });
                            },
                          ),
                          SizedBox(width: mq.width * 0.05),
                          _actionButton(
                            mq: mq,
                            icon: Icons.swap_vert,
                            label: 'Swap',
                            onTap: () {
                              if (_wallet == null || _wallet!.tokens.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'You do not have tokens available to swap in your wallet.\nPlease buy some tokens from the Home Screen.',
                                      style: TextStyle(
                                        fontFamily: 'Benne',
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Color(0xFF1A1A1A),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                _showCoinSelectionPopup(
                                  title: 'Select Token to Swap',
                                  onSelected: (token) {
                                    _showInteractionPopup(() {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SwapScreen(token: token),
                                        ),
                                      );
                                    });
                                  },
                                );
                              }
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: mq.height * 0.02),

                      // Your Coins header
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: mq.width * 0.05,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Coins',
                              style: TextStyle(
                                fontFamily: 'Benne',
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            if (!_loading && _wallet != null)
                              Text(
                                '${_wallet!.tokens.length} token${_wallet!.tokens.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontFamily: 'Benne',
                                  fontSize: 13,
                                  color: Colors.white54,
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: mq.height * 0.012),
                    ],
                  ),
                ),

                if (_loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFE600),
                      ),
                    ),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'You do not have any tokens in your wallet yet.',
                        style: TextStyle(
                          fontFamily: 'Benne',
                          color: Colors.white54,
                          fontSize: mq.width * 0.038,
                        ),
                      ),
                    ),
                  )
                else if (_wallet == null || _wallet!.tokens.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'You do not have any tokens in your wallet yet.',
                        style: TextStyle(
                          fontFamily: 'Benne',
                          color: Colors.white54,
                          fontSize: mq.width * 0.038,
                         ),
                        textAlign: TextAlign.center,
                        ),
                      ),
                   )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index.isOdd) {
                          return Divider(
                            color: Colors.white.withOpacity(0.18),
                            height: 18,
                          );
                        }
                        final tokenIndex = index ~/ 2;
                        final token = _wallet!.tokens[tokenIndex];
                        return InkWell(
                          onTap: () {
                            /*_showInteractionPopup(() {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SwapScreen(token: token),
                                ),
                              );
                            });*/
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              _tokenLogo(token, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      token.displayName,
                                      style: const TextStyle(
                                        fontFamily: 'BernardMTCondensed',
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      token.symbol ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Benne',
                                        fontSize: 12,
                                        color: Color(0xFFC9C9C9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                token.balance,
                                style: const TextStyle(
                                  fontFamily: 'BernardMTCondensed',
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }, childCount: _wallet!.tokens.length * 2 - 1),
                    ),
                  ),

                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      mq.width * 0.05,
                      24,
                      mq.width * 0.05,
                      mq.height * 0.12,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [disclaimer()],
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

  Widget _tokenLogo(WalletTokenModel token, {required double size}) {
    if (token.logo != null && token.logo!.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size),
          child: Image.network(
            token.logo!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _coinImage(
              size: size,
              text: token.displayName.isNotEmpty == true
                  ? getFirstValidChar(token.displayName)
                  : '',
            ),
          ),
        ),
      );
    }
    return _coinImage(
      size: size,
      text: token.displayName.isNotEmpty == true
          ? getFirstValidChar(token.displayName)
          : '',
    );
  }

  Widget _coinImage({required double size, required String text}) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            //gradient: _circleGradient,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
        ) /*Image.asset('assets/images/bit_coin.png')*/,
      ),
    );
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

  Widget _defaultIcon(double size) {
    return Image.asset('assets/images/bit_coin.png', width: size, height: size);
  }

  Widget _actionButton({
    required Size mq,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
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
            child: Center(child: Icon(icon, color: Colors.white, size: 34)),
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

  Widget disclaimer() {
    final Size mq = MediaQuery.of(context).size;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Disclaimer",
            style: TextStyle(
              fontFamily: 'BernardMTCondensed',
              color: Color(0xFFEEFF00),
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "MoonLaunch is a non-custodial interface. Assets are held and controlled by the user on the Binance (BNB) blockchain via their personal wallet. MoonLaunch does not custody funds, execute transactions, or operate as a cryptocurrency exchange.",
            style: TextStyle(
              fontFamily: 'Benne',
              fontSize: mq.width * 0.040,
              color: Colors.white.withOpacity(0.90),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
