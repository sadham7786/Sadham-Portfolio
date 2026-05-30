import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moon_launch/Back-end/Controllers/session_controller.dart';
import 'package:moon_launch/Back-end/Services/trade_service.dart';
import 'package:moon_launch/Back-end/Services/wallet_service.dart';
import 'package:moon_launch/Front-end/Extra%20Widgets/qr_scan_screen.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';
import 'package:url_launcher/url_launcher.dart';

/// Send screen — used to transfer BNB or an ERC-20 token to another address.
///
/// When [token] is null → sends native BNB.
/// When [token] is provided → sends that ERC-20 token.
class SellScreen extends StatefulWidget {
  final WalletTokenModel? token;

  const SellScreen({super.key, this.token});

  static const LinearGradient btnGradient = LinearGradient(
    colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController  = TextEditingController();

  bool _loading = false;
  String? _error;
  TradeResult? _result;
  bool _isBnb =false;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _amountController.text = '0';
    setState(() {
      if(widget.token == null){
        _isBnb = true;
      }else{
        _isBnb = false;
      }
    });
  }


  //bool get _isBnb => widget.token == null;

  String get _assetLabel => _isBnb ? 'BNB' : (widget.token!.symbol ?? 'Token');

  Future<void> _openQrScanner() async {
    final String? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() => _addressController.text = result.trim());
    }
  }

  Future<void> _onPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() => _addressController.text = data!.text!.trim());
    }
  }

  Future<void> _onSend() async {
    final walletAddress = SessionController.instance.walletAddress;
    if (walletAddress == null || walletAddress.isEmpty) {
      setState(() => _error = 'No wallet found.');
      return;
    }

    final toAddress = _addressController.text.trim();
    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(toAddress)) {
      setState(() => _error = 'Enter a valid BSC wallet address (0x...).');
      return;
    }

    final amountStr = _amountController.text.trim();
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }

    setState(() {
      _loading = true;
      _error   = null;
      _result  = null;
    });

    try {
      final result = await TradeService.send(
        walletAddress: walletAddress,
        toAddress: toAddress,
        amount: amountStr,
        tokenAddress: _isBnb ? null : widget.token!.tokenAddress,
        decimals: _isBnb ? 18 : widget.token!.decimals,
      );
      setState(() {
        _result  = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error   = e.toString();
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
            child: _result != null ? _successView(mq) : _sendForm(mq),
          ),
        ),
      ),
    );
  }

  Widget _sendForm(Size mq) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: mq.height * 0.02),

        Text(
          'Send',
          style: TextStyle(
            fontFamily: 'BernardMTCondensed',
            fontSize: mq.width * 0.085,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),

        SizedBox(height: mq.height * 0.025),

        // Asset info
        Center(
          child: Column(
            children: [
              _isBnb
                  ? Image.asset(
                      'assets/images/bit_coin.png',
                      width: mq.width * 0.22,
                      height: mq.width * 0.22,
                      fit: BoxFit.contain,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(mq.width * 0.11),
                      child: widget.token!.logo != null && widget.token!.logo!.isNotEmpty
                          ? Image.network(
                              widget.token!.logo!,
                              width: mq.width * 0.22,
                              height: mq.width * 0.22,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/bit_coin.png',
                                width: mq.width * 0.22,
                                height: mq.width * 0.22,
                              ),
                            )
                          : _coinImage(
                        size: mq.width * 0.22,
                        text: _assetLabel.isNotEmpty == true
                            ? getFirstValidChar(_assetLabel?? '')
                            : '',
                      ),
                    ),
              const SizedBox(height: 8),
              Text(
                _assetLabel,
                style: const TextStyle(
                  fontFamily: 'BernardMTCondensed',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: mq.height * 0.025),

        // Recipient address field
        _pill(
          mq,
          child: Row(
            children: [
              const SizedBox(width: 18),
              Expanded(
                child: TextField(
                  controller: _addressController,
                  style: TextStyle(
                    fontFamily: 'Benne',
                    color: Colors.white.withOpacity(.9),
                    fontSize: 14,
                  ),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Recipient Address (0x...)',
                    hintStyle: TextStyle(
                      fontFamily: 'Benne',
                      color: Colors.white.withOpacity(.45),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _onPaste,
                child: ShaderMask(
                  shaderCallback: (b) => SellScreen.btnGradient.createShader(b),
                  child: const Text(
                    'Paste',
                    style: TextStyle(
                      fontFamily: 'BernardMTCondensed',
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _openQrScanner,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: ShaderMask(
                    shaderCallback: (b) => SellScreen.btnGradient.createShader(b),
                    child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Network badge
        Container(
          height: mq.height * 0.065,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(.35)),
            color: const Color(0xFFFFE600).withOpacity(0.08),
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),
              Text(
                'BNB Smart Chain (BSC)',
                style: TextStyle(
                  fontFamily: 'Benne',
                  color: Colors.white.withOpacity(.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Amount field
        _pill(
          mq,
          child: Row(
            children: [
              const SizedBox(width: 18),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: const TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Amount ($_assetLabel)',
                    hintStyle: TextStyle(
                      fontFamily: 'Benne',
                      color: Colors.white.withOpacity(.45),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              ShaderMask(
                shaderCallback: (b) => SellScreen.btnGradient.createShader(b),
                child: const Text(
                  'MAX',
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 18),
            ],
          ),
        ),

        const SizedBox(height: 8),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
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
            : _bottomGradientButton(text: 'Send', onTap: _onSend),

        SizedBox(height: mq.height * 0.05),
      ],
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
        ),
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
          'Sent!',
          style: TextStyle(
            fontFamily: 'BernardMTCondensed',
            color: Colors.white,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your transaction has been broadcast to BSC.',
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
        _bottomGradientButton(
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

  Widget _pill(Size mq, {required Widget child}) {
    return Container(
      height: mq.height * 0.065,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(.35), width: 1),
        color: Colors.black.withOpacity(.10),
      ),
      child: child,
    );
  }

  Widget _bottomGradientButton({required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: SellScreen.btnGradient,
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
