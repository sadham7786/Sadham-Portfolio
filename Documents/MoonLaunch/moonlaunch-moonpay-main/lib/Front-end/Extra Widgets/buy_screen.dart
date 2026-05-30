import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moon_launch/Back-end/Controllers/session_controller.dart';
import 'package:moon_launch/Back-end/Services/trade_service.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyScreen extends StatefulWidget {
  final String tokenAddress;
  final String tokenName;
  final String? tokenSymbol;
  final String? tokenLogo;

  const BuyScreen({
    super.key,
    required this.tokenAddress,
    required this.tokenName,
    this.tokenSymbol,
    this.tokenLogo,
  });

  static const LinearGradient _btnGradient = LinearGradient(
    colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;
  String? _error;
  TradeResult? _result;

  // Quick-select BNB amounts
  static const List<String> _quickAmounts = ['0.01', '0.05', '0.1', '0.5'];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('transfer_from_failed') ||
        lower.contains('transferfrom')) {
      return 'This token cannot be purchased — its contract blocks buying. It may be a restricted or honeypot token.';
    }
    if (lower.contains('insufficient funds') ||
        lower.contains('insufficient balance')) {
      return 'Insufficient BNB balance. Please add more BNB to your wallet.';
    }
    if (lower.contains('gas')) {
      return 'Not enough BNB to cover gas fees. Please add more BNB.';
    }
    if (lower.contains('nonce') || lower.contains('replacement transaction')) {
      return 'Transaction conflict. Please try again in a moment.';
    }
    if (lower.contains('no wallet') || lower.contains('wallet not found')) {
      return 'Wallet not found. Please log out and log in again.';
    }
    return 'Transaction failed. Please try again.';
  }

  Future<void> _onBuy() async {
    final walletAddress = SessionController.instance.walletAddress;
    if (walletAddress == null || walletAddress.isEmpty) {
      setState(
        () => _error = 'No wallet found. Please log out and log in again.',
      );
      return;
    }

    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      setState(() => _error = 'Please enter a BNB amount.');
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Invalid amount.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await TradeService.buy(
        walletAddress: walletAddress,
        tokenAddress: widget.tokenAddress,
        bnbAmount: amountStr,
      );
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = _friendlyError(e.toString());
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
            padding: EdgeInsets.symmetric(horizontal: mq.width * 0.07),
            child: _result != null ? _successView(mq) : _buyForm(mq),
          ),
        ),
      ),
    );
  }

  Widget _buyForm(Size mq) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: mq.height * 0.02),

        Text(
          'Buy',
          style: TextStyle(
            fontFamily: 'BernardMTCondensed',
            fontSize: mq.width * 0.085,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),

        SizedBox(height: mq.height * 0.025),

        // Token info
        Center(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(mq.width * 0.14),
                child: widget.tokenLogo != null && widget.tokenLogo!.isNotEmpty
                    ? Image.network(
                        widget.tokenLogo!,
                        width: mq.width * 0.28,
                        height: mq.width * 0.28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _coinImage(
                          size: mq.width * 0.14,
                          text: widget.tokenName.isNotEmpty == true
                              ? getFirstValidChar(widget.tokenName)
                              : '',
                        ),
                      )
                    : _coinImage(
                        size: mq.width * 0.28,
                        text: widget.tokenName?.isNotEmpty == true
                            ? getFirstValidChar(widget.tokenName ?? '')
                            : '',
                      ) /*Image.asset(
                        'assets/images/bit_coin.png',
                        width: mq.width * 0.28,
                        height: mq.width * 0.28,
                        fit: BoxFit.contain,
                      )*/,
              ),
              const SizedBox(height: 10),
              Text(
                widget.tokenName,
                style: const TextStyle(
                  fontFamily: 'BernardMTCondensed',
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              if (widget.tokenSymbol != null)
                Text(
                  widget.tokenSymbol!,
                  style: const TextStyle(
                    fontFamily: 'Benne',
                    color: Color(0xFFC9C9C9),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),

        SizedBox(height: mq.height * 0.025),

        // BNB amount input
        Container(
          height: mq.height * 0.065,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(.35), width: 1),
            color: Colors.black.withOpacity(.10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
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
                      color: Colors.white.withOpacity(.4),
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Text(
                'BNB',
                style: TextStyle(
                  fontFamily: 'Benne',
                  color: Colors.white.withOpacity(.75),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 18),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Quick-select amounts
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _quickAmounts.map((amt) {
            return GestureDetector(
              onTap: () => _amountController.text = amt,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(.25)),
                ),
                child: Text(
                  '$amt BNB',
                  style: const TextStyle(
                    fontFamily: 'Benne',
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // Error
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: const TextStyle(
                fontFamily: 'Benne',
                color: Color(0xFFDB2519),
                fontSize: 13,
              ),
            ),
          ),

        // Slippage notice
        Text(
          '5% slippage • PancakeSwap V2 • BSC',
          style: TextStyle(
            fontFamily: 'Benne',
            fontSize: 12,
            color: Colors.white.withOpacity(.4),
          ),
        ),

        const Spacer(),

        _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFE600)),
              )
            : _gradientButton(text: 'Buy Now', onTap: _onBuy),

        SizedBox(height: mq.height * 0.05),
      ],
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

  Widget _successView(Size mq) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Color(0xFFFFE600),
          size: 72,
        ),
        const SizedBox(height: 20),
        const Text(
          'Purchase Submitted!',
          style: TextStyle(
            fontFamily: 'BernardMTCondensed',
            color: Colors.white,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your transaction has been broadcast to the BSC network.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Benne',
            color: Colors.white.withOpacity(.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),

        // TX hash
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
                    style: const TextStyle(
                      fontFamily: 'Benne',
                      color: Colors.white,
                      fontSize: 13,
                    ),
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
            style: TextStyle(
              fontFamily: 'Benne',
              color: Colors.white70,
              fontSize: 15,
            ),
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
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 24,
                  ),
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
          gradient: BuyScreen._btnGradient,
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
