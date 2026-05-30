import 'package:flutter/material.dart';
import 'package:moon_launch/Back-end/Controllers/session_controller.dart';
import 'package:moon_launch/Back-end/Services/moonpay_service.dart';
import 'package:moon_launch/Back-end/Services/token_service.dart';
import 'package:moon_launch/Back-end/Services/wallet_service.dart';
import 'package:moon_launch/Front-end/Extra%20Widgets/moonpay_webview_screen.dart';
import 'package:moon_launch/Front-end/views/coin_detail_screen.dart';
import 'package:moon_launch/Front-end/widgets/profile_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LinearGradient _mainGradient = const LinearGradient(
    colors: [Color(0xFF2A1216), Color(0xFF9A1117)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  List<TokenModel> _allTokens = [];
  List<TokenModel> _filteredTokens = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;

  String _bnbBalance = '--';
  String _usdValue = '--';
  bool _addBnbLoading = false;
  bool _sellBnbLoading = false;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTokens();
    _loadBnb();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore &&
        _searchController.text.isEmpty) {
      _loadMoreTokens();
    }
  }

  void _onSearchChanged() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        _filteredTokens = List.from(_allTokens);
      } else {
        _filteredTokens = _allTokens.where((t) {
          final name = t.name?.toLowerCase() ?? '';
          final symbol = t.symbol?.toLowerCase() ?? '';
          final address = t.tokenAddress.toLowerCase();
          return name.contains(query) ||
              symbol.contains(query) ||
              address.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadBnb() async {
    final address = SessionController.instance.walletAddress;
    if (address == null || address.isEmpty) return;
    try {
      final wallet = await WalletService.getBalance(address);
      if (mounted) {
        setState(() {
          _bnbBalance = wallet.displayBnb;
          _usdValue = wallet.displayUsd;
        });
      }
    } catch (_) {}
  }

  Future<void> _openAddBnbFlow() async {
    final walletAddress = SessionController.instance.walletAddress;
    if (walletAddress == null || walletAddress.isEmpty) {
      _showSnackBar('No wallet found. Please log out and log in again.');
      return;
    }

    setState(() => _addBnbLoading = true);

    try {
      final result = await MoonPayService.createOnrampUrl(
        walletAddress: walletAddress,
      );
      if (!mounted) return;

      setState(() => _addBnbLoading = false);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MoonPayWebViewScreen(url: result.url, title: 'Add BNB'),
        ),
      );

      if (!mounted) return;
      await _loadBnb();
    } catch (e) {
      if (!mounted) return;
      setState(() => _addBnbLoading = false);
      _showSnackBar(e.toString());
    }
  }

  Future<void> _openSellBnbFlow() async {
    final walletAddress = SessionController.instance.walletAddress;
    if (walletAddress == null || walletAddress.isEmpty) {
      _showSnackBar('No wallet found. Please log out and log in again.');
      return;
    }

    setState(() => _sellBnbLoading = true);

    try {
      final result = await MoonPayService.createOfframpUrl(
        walletAddress: walletAddress,
      );
      if (!mounted) return;

      setState(() => _sellBnbLoading = false);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MoonPayWebViewScreen(
            url: result.url,
            title: 'Sell BNB',
            onSendWithMoonLaunch: () => _sendMoonPaySellDeposit(
              walletAddress: walletAddress,
              externalTxId: result.externalTxId,
            ),
          ),
        ),
      );

      if (!mounted) return;
      await _loadBnb();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sellBnbLoading = false);
      _showSnackBar(e.toString());
    }
  }

  Future<String?> _sendMoonPaySellDeposit({
    required String walletAddress,
    required String externalTxId,
  }) async {
    if (externalTxId.isEmpty) {
      throw 'MoonPay did not return a sell transaction ID.';
    }

    final result = await MoonPayService.sendSellDeposit(
      walletAddress: walletAddress,
      externalTxId: externalTxId,
    );

    if (mounted) await _loadBnb();

    if (result.status == 'already_sent') {
      return 'Already sent to MoonPay. Waiting for confirmation.';
    }
    return 'Sent to MoonPay. Waiting for confirmation.';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Benne', color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadTokens() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
      _hasMore = true;
    });
    try {
      final tokens = await TokenService.getNewLaunches(
        limit: _limit,
        offset: 0,
      );
      setState(() {
        _allTokens = tokens;
        _offset = tokens.length;
        if (tokens.length < _limit) _hasMore = false;
        _onSearchChanged();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreTokens() async {
    if (_loadingMore || !_hasMore) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final tokens = await TokenService.getNewLaunches(
        limit: _limit,
        offset: _offset,
      );
      setState(() {
        if (tokens.isEmpty) {
          _hasMore = false;
        } else {
          _allTokens.addAll(tokens);
          _offset += tokens.length;
          if (tokens.length < _limit) _hasMore = false;
          _onSearchChanged();
        }
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loadingMore = false;
      });
    }
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
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black, fontSize: 20),
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
            errorBuilder: (context, error, stackTrace) => _coinImage(
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

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: ProfileBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadTokens,
            color: const Color(0xFFFFE600),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: mq.height * 0.01),
                    child: Column(
                      children: [
                        // Search bar
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: mq.width * 0.06,
                          ),
                          child: Container(
                            height: mq.height * 0.055,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1,
                              ),
                              color: Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: mq.width * 0.04),
                                Icon(
                                  Icons.search,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  size: 20,
                                ),
                                SizedBox(width: mq.width * 0.03),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(color: Colors.white),
                                    textAlignVertical: TextAlignVertical.center,
                                    decoration: InputDecoration(
                                      hintText: "Search...",
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.70,
                                        ),
                                        fontFamily: 'Benne',
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      isCollapsed: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 0,
                                          ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: mq.width * 0.04),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: mq.height * 0.03),

                        // Total wallet value label
                        Text(
                          'Total Wallet Value',
                          style: TextStyle(
                            fontFamily: 'Benne',
                            fontWeight: FontWeight.w400,
                            fontSize: mq.width * 0.040,
                            color: const Color(0xFFC9C9C9),
                          ),
                        ),
                        SizedBox(height: mq.height * 0.010),

                        // USD value — big
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'BernardMTCondensed',
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                            children: [
                              TextSpan(
                                text: _usdValue,
                                style: TextStyle(fontSize: mq.width * 0.100),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: Text(
                                    'usd',
                                    style: TextStyle(
                                      fontFamily: 'BernardMTCondensed',
                                      fontWeight: FontWeight.w400,
                                      fontSize: mq.width * 0.042,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // BNB balance — smaller below
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'BernardMTCondensed',
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                            children: [
                              TextSpan(
                                text: _bnbBalance,
                                style: TextStyle(fontSize: mq.width * 0.058),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: Text(
                                    'BNB',
                                    style: TextStyle(
                                      fontFamily: 'BernardMTCondensed',
                                      fontWeight: FontWeight.w400,
                                      fontSize: mq.width * 0.038,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _gradientPillButton(
                              mq: mq,
                              title: "ADD BNB",
                              icon: Icons.arrow_downward,
                              loading: _addBnbLoading,
                              onTap: _addBnbLoading || _sellBnbLoading
                                  ? null
                                  : _openAddBnbFlow,
                            ),
                            SizedBox(width: mq.width * 0.03),
                            _gradientPillButton(
                              mq: mq,
                              title: "SELL BNB",
                              icon: Icons.account_balance,
                              loading: _sellBnbLoading,
                              onTap: _addBnbLoading || _sellBnbLoading
                                  ? null
                                  : _openSellBnbFlow,
                            ),
                          ],
                        ),

                        SizedBox(height: mq.height * 0.025),

                        // New Launches header
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: mq.width * 0.07,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'New Launches',
                                style: TextStyle(
                                  fontFamily: 'Benne',
                                  fontWeight: FontWeight.w400,
                                  fontSize: mq.width * 0.05,
                                  color: Colors.white,
                                ),
                              ),
                              InkWell(
                                onTap: _loadTokens,
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      _mainGradient.createShader(bounds),
                                  child: Text(
                                    'Refresh',
                                    style: TextStyle(
                                      fontFamily: 'Benne',
                                      fontWeight: FontWeight.w400,
                                      fontSize: mq.width * 0.04,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: mq.height * 0.012),
                      ],
                    ),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Failed to load launches',
                            style: TextStyle(
                              fontFamily: 'Benne',
                              color: Colors.white70,
                              fontSize: mq.width * 0.04,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _loadTokens,
                            child: const Text(
                              'Tap to retry',
                              style: TextStyle(
                                fontFamily: 'Benne',
                                color: Color(0xFFFFE600),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_filteredTokens.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'No launches yet'
                            : 'No tokens match your search',
                        style: TextStyle(
                          fontFamily: 'Benne',
                          color: Colors.white54,
                          fontSize: mq.width * 0.04,
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == _filteredTokens.length) {
                        return _loadingMore
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFFE600),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      final token = _filteredTokens[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: mq.width * 0.04,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CoinDetailScreen(
                                  tokenAddress: token.tokenAddress,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  width: 1.0,
                                  color: Color(0xFFCDCDCD),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                _tokenLogo(token, size: 46),
                                SizedBox(width: mq.width * 0.02),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        token.displayName,
                                        style: const TextStyle(
                                          fontFamily: 'BernardMTCondensed',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        token.symbol ?? '',
                                        style: const TextStyle(
                                          fontFamily: 'Benne',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                          color: Color(0xFFC9C9C9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      token.displayPrice,
                                      style: const TextStyle(
                                        fontFamily: 'BernardMTCondensed',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      token.priceCurrency ?? 'USD',
                                      style: const TextStyle(
                                        fontFamily: 'Benne',
                                        fontSize: 11,
                                        color: Color(0xFFC9C9C9),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: _filteredTokens.length + 1),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradientPillButton({
    required Size mq,
    required String title,
    required VoidCallback? onTap,
    required IconData icon,
    bool loading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: _mainGradient,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: mq.width * 0.055,
              vertical: mq.height * 0.014,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFE600),
                      strokeWidth: 2,
                    ),
                  )
                else
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'BernardMTCondensed',
                      fontWeight: FontWeight.w400,
                      fontSize: mq.width * 0.040,
                      color: Colors.white,
                    ),
                  ),
                SizedBox(width: mq.width * 0.03),
                Icon(icon, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
