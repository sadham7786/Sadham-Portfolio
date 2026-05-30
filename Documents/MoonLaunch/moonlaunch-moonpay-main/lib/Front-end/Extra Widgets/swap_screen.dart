import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moon_launch/Back-end/Controllers/session_controller.dart';
import 'package:moon_launch/Back-end/Services/trade_service.dart';
import 'package:moon_launch/Back-end/Services/wallet_service.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';
import 'package:url_launcher/url_launcher.dart';

/// Swap screen — sells [token] for BNB via PancakeSwap V2.
class SwapScreen extends StatefulWidget {
  final WalletTokenModel token;

  const SwapScreen({super.key, required this.token});

  static const LinearGradient _btnGradient = LinearGradient(
    colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient _circleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
  );

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;
  String? _error;
  TradeResult? _result;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('transfer_from_failed') || lower.contains('transferfrom')) {
      return 'This token cannot be sold — it may be a honeypot or have transfer restrictions built into its contract.';
    }
    if (lower.contains('insufficient funds') || lower.contains('insufficient balance')) {
      return 'Not enough BNB for gas fees. Please add more BNB to your wallet.';
    }
    if (lower.contains('pancake: insufficient') || lower.contains('pancake: k')) {
      return 'Swap failed — not enough liquidity. Try a smaller amount.';
    }
    if (lower.contains('execution reverted')) {
      return 'Swap rejected by the token contract. This token may have sell restrictions.';
    }
    if (lower.contains('allowance') || lower.contains('approve')) {
      return 'Token approval failed. Please try again.';
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return 'Approval timed out. Please try again.';
    }
    return 'Swap failed. Please try again.';
  }

  Future<void> _onSwap() async {
    final walletAddress = SessionController.instance.walletAddress;
    if (walletAddress == null || walletAddress.isEmpty) {
      setState(() => _error = 'No wallet found. Please log out and log in again.');
      return;
    }

    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      setState(() => _error = 'Please enter an amount to swap.');
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Invalid amount.');
      return;
    }

    setState(() {
      _loading = true;
      _error   = null;
      _result  = null;
    });

    try {
      final result = await TradeService.sell(
        walletAddress: walletAddress,
        tokenAddress:  widget.token.tokenAddress,
        tokenAmount:   amountStr,
        decimals:      widget.token.decimals,
        historyType: 'swap',
      );
      setState(() {
        _result  = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error   = _friendlyError(e.toString());
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: _topBar(context, mq),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * 0.06),
            child: _result != null ? _successView(mq) : _swapForm(mq),
          ),
        ),
      ),
    );
  }

  Widget _swapForm(Size mq) {
    final symbol = widget.token.symbol ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: mq.height * 0.02),

        Text(
          'Swap',
          style: TextStyle(
            fontFamily: 'BernardMTCondensed',
            fontSize: mq.width * 0.085,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),

        SizedBox(height: mq.height * 0.03),

        // From / To cards with swap icon centred between them
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                // FROM — token with amount input
                _card(
                  mq: mq,
                  tag: 'From',
                  logo: widget.token.logo,
                  title: widget.token.displayName,
                  subtitle: symbol.isNotEmpty ? symbol : 'Token',
                  trailing: SizedBox(
                    width: mq.width * 0.30,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'BernardMTCondensed',
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          fontFamily: 'BernardMTCondensed',
                          color: Colors.white.withOpacity(.35),
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: mq.height * 0.020),

                // TO — BNB
                _card(
                  mq: mq,
                  tag: 'To',
                  logo: null,
                  title: 'BNB',
                  subtitle: 'BNB Smart Chain',
                  trailing: Text(
                    '≈ BNB',
                    style: TextStyle(
                      fontFamily: 'BernardMTCondensed',
                      color: Colors.white.withOpacity(.55),
                      fontSize: 16,
                    ),
                  ),
                  isBnb: true,
                ),
              ],
            ),

            // Swap icon centred between cards
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SwapScreen._circleGradient,
              ),
              child: const Icon(Icons.swap_vert, color: Colors.white, size: 26),
            ),
          ],
        ),

        SizedBox(height: mq.height * 0.015),

        // Available balance hint
        Text(
          'Available: ${widget.token.balance} $symbol',
          style: TextStyle(
            fontFamily: 'Benne',
            fontSize: 12,
            color: Colors.white.withOpacity(.45),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          '5% slippage • PancakeSwap V2 • BSC',
          style: TextStyle(
            fontFamily: 'Benne',
            fontSize: 12,
            color: Colors.white.withOpacity(.4),
          ),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _error!,
              style: const TextStyle(
                fontFamily: 'Benne',
                color: Color(0xFFDB2519),
                fontSize: 13,
              ),
            ),
          ),

        const Spacer(),

        _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFE600)))
            : _gradientButton(text: 'Swap Now', onTap: _onSwap),

        SizedBox(height: mq.height * 0.05),
      ],
    );
  }

  Widget _card({
    required Size mq,
    required String tag,
    required String? logo,
    required String title,
    required String subtitle,
    required Widget trailing,
    bool isBnb = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(.40), width: 1),
        color: Colors.black.withOpacity(.10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tag,
                style: TextStyle(
                  fontFamily: 'Benne',
                  color: Colors.white.withOpacity(.55),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: isBnb
                        ? Image.asset('assets/images/bnb.png', width: 36, height: 36, fit: BoxFit.contain)
                        : (logo != null && logo.isNotEmpty
                            ? Image.network(
                                logo,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/bit_coin.png',
                                  width: 36,
                                  height: 36,
                                ),
                              )
                            :_coinImage(
                      size: 36,
                      text: title.isNotEmpty == true
                          ? getFirstValidChar(title?? '')
                          : '',
                    ) /*Image.asset('assets/images/bit_coin.png', width: 36, height: 36)*/),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'BernardMTCondensed',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Benne',
                          color: Colors.white.withOpacity(.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          trailing,
        ],
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

  Widget _successView(Size mq) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFFFFE600), size: 72),
        const SizedBox(height: 20),
        const Text(
          'Swap Submitted!',
          style: TextStyle(
            fontFamily: 'BernardMTCondensed',
            color: Colors.white,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your tokens are being swapped for BNB on BSC.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Benne',
            color: Colors.white.withOpacity(.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Clipboard.setData(ClipboardData(text: _result!.txHash)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_result!.txHash.substring(0, 10)}...${_result!.txHash.substring(_result!.txHash.length - 8)}',
                    style: const TextStyle(fontFamily: 'Benne', color: Colors.white, fontSize: 13),
                  ),
                ),
                const Icon(Icons.copy, color: Colors.white54, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _gradientButton(
          text: 'View on BscScan',
          onTap: () async {
            final uri = Uri.parse(_result!.explorerUrl);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Done',
            style: TextStyle(fontFamily: 'Benne', color: Colors.white70, fontSize: 15),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _topBar(BuildContext context, Size mq) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 70,
      titleSpacing: mq.width * 0.05,
      title: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFDB2519).withOpacity(0.20),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                ),
              ),
            ),
            const Spacer(),
            Image.asset(
              'assets/images/moon_launch_logo.png',
              width: 104,
              height: 31,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton({required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: SwapScreen._btnGradient,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'BernardMTCondensed',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
