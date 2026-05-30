import 'package:flutter/material.dart';
import 'package:moon_launch/Back-end/Controllers/session_controller.dart';
import 'package:moon_launch/Back-end/Services/token_service.dart';
import 'package:moon_launch/Front-end/widgets/app_background.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isLoading = true;
  List<TransactionModel> _transactions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final walletAddress = SessionController.instance.walletAddress;
    if (walletAddress == null) {
      setState(() {
        _isLoading = false;
        _error = 'Wallet address not found';
      });
      return;
    }

    try {
      final history = await TokenService.getTransactionHistory(walletAddress);
      setState(() {
        _transactions = history;
        print('_transactions ${_transactions}');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        surfaceTintColor: Colors.transparent,
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
            padding: EdgeInsets.symmetric(
              vertical: 10,
              horizontal: mqSize.width * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction History',
                  style: TextStyle(
                    fontFamily: 'BernardMTCondensed',
                    fontWeight: FontWeight.w400,
                    fontSize: mqSize.width * 0.08,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: mqSize.height * 0.01),
                Text(
                  'Your recent activity',
                  style: TextStyle(
                    fontFamily: 'Benne',
                    fontWeight: FontWeight.w400,
                    fontSize: mqSize.width * 0.045,
                    color: const Color(0xFFC9C9C9),
                  ),
                ),
                SizedBox(height: mqSize.height * 0.03),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFDB2519)))
                      : _error != null
                          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white, fontFamily: 'Benne')))
                          : _transactions.isEmpty
                              ? const Center(child: Text('No transactions found', style: TextStyle(color: Colors.white, fontFamily: 'Benne')))
                              : ListView.builder(
                                  itemCount: _transactions.length,
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (context, index) {
                                    final tx = _transactions[index];
                                    final iconConfig = getTransactionIconConfig(tx.type);
                                    final Color statusColor = getStatusColor(tx.status);
                                    
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 15,
                                      ),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            width: 1.0,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: iconConfig.color.withOpacity(0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              iconConfig.icon,
                                              color: iconConfig.color,
                                              size: 24,
                                            ),
                                          ),

                                          SizedBox(width: mqSize.width * 0.03),

                                          Expanded(
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        buildTransactionTitle(tx),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontFamily: 'BernardMTCondensed',
                                                          fontWeight: FontWeight.w400,
                                                          fontSize: 16,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        formatDate(tx.createdAt),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontFamily: 'Benne',
                                                          fontWeight: FontWeight.w400,
                                                          fontSize: 12,
                                                          color: Color(0xFFC9C9C9),
                                                        ),
                                                      ),
                                                      if ((tx.failureReason ?? '').trim().isNotEmpty) ...[
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'Reason: ${tx.failureReason!.trim()}',
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            fontFamily: 'Benne',
                                                            fontWeight: FontWeight.w400,
                                                            fontSize: 11,
                                                            color: Color(0xFFFF8A80),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(width: mqSize.width * 0.02),
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: mqSize.width * 0.34,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        getTransactionAmount(tx),
                                                        maxLines: 2,
                                                        textAlign: TextAlign.right,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontFamily: 'BernardMTCondensed',
                                                          fontWeight: FontWeight.w400,
                                                          fontSize: 16,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Status: ${formatStatus(tx.status)}',
                                                        maxLines: 1,
                                                        textAlign: TextAlign.right,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontFamily: 'BernardMTCondensed',
                                                          fontWeight: FontWeight.w400,
                                                          fontSize: 12,
                                                          color: statusColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
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
          ),
        ),
      ),
    );
  }
  String formatDate(String date) {
    final parsed = DateTime.parse(date).toLocal();

    return "${parsed.year}-"
        "${parsed.month.toString().padLeft(2, '0')}-"
        "${parsed.day.toString().padLeft(2, '0')} "
        "${parsed.hour.toString().padLeft(2, '0')}:"
        "${parsed.minute.toString().padLeft(2, '0')}";
  }

  String getTransactionAmount(TransactionModel tx) {
    final value = preferredAmount(tx);
    if (value == null || value.trim().isEmpty) {
      return 'Amount: Pending';
    }

    final currency = displayCurrency(tx);
    final formattedValue = formatAmountValue(value);

    if (currency.isEmpty) {
      return 'Amount: $formattedValue';
    }

    return 'Amount: $formattedValue ${formatCurrency(currency)}';
  }

  String formatCurrency(String currency) {
    return currency
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();
  }

  String buildTransactionTitle(TransactionModel tx) {
    final typeLabel = formatTransactionType(tx.type);
    final currency = displayCurrency(tx);

    if (currency.isEmpty) {
      return typeLabel;
    }

    return '$typeLabel ${formatCurrency(currency)}';
  }

  String formatTransactionType(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return 'Purchase';
      case 'sell':
        return 'Sell';
      case 'swap':
        return 'Swap';
      case 'send':
        return 'Send';
      default:
        return type.isEmpty ? 'Transaction' : type;
    }
  }

  String formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String formatAmountValue(String? raw) {
    if (raw == null || raw.isEmpty) return 'Pending';

    final normalized = _trimTrailingZeros(raw.trim());
    if (normalized.isEmpty) return 'Pending';

    final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(normalized);
    if (match != null) {
      final integerPart = _formatThousands(match.group(1)!);
      final decimalPart = (match.group(2) ?? '').replaceFirst(RegExp(r'0+$'), '');
      return decimalPart.isEmpty ? integerPart : '$integerPart.$decimalPart';
    }

    final numeric = double.tryParse(normalized);
    if (numeric != null) {
      final fallback = numeric.toStringAsFixed(numeric.truncateToDouble() == numeric ? 0 : 4);
      return fallback.replaceFirst(RegExp(r'\.?0+$'), '');
    }

    if (normalized.length > 18) {
      return '${normalized.substring(0, 15)}...';
    }

    return normalized;
  }

  String displayCurrency(TransactionModel tx) {
    final tokenOrCurrency = tx.tokenOrCurrency.trim();
    final crypto = tx.cryptoCurrency.trim();
    final fiat = (tx.fiatCurrency ?? '').trim();

    if (tokenOrCurrency.isNotEmpty && !looksLikeAddress(tokenOrCurrency)) {
      return tokenOrCurrency;
    }

    if (crypto.isNotEmpty && !looksLikeAddress(crypto)) {
      return crypto;
    }

    if (fiat.isNotEmpty && !looksLikeAddress(fiat)) {
      return fiat;
    }

    return '';
  }

  bool looksLikeAddress(String value) {
    return RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(value);
  }

  String? preferredAmount(TransactionModel tx) {
    for (final candidate in [tx.cryptoAmount, tx.fiatAmount, tx.amount]) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _formatThousands(String digits) {
    final trimmed = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final buffer = StringBuffer();
    for (int index = 0; index < trimmed.length; index++) {
      final remaining = trimmed.length - index;
      buffer.write(trimmed[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  String _trimTrailingZeros(String value) {
    if (!value.contains('.')) {
      return value;
    }

    return value
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'waiting_payment':
      case 'waiting_authorization':
      case 'waiting_for_deposit':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  _TransactionIconConfig getTransactionIconConfig(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return const _TransactionIconConfig(
          icon: Icons.call_received,
          color: Colors.green,
        );
      case 'sell':
        return const _TransactionIconConfig(
          icon: Icons.trending_down_rounded,
          color: Colors.red,
        );
      case 'swap':
        return const _TransactionIconConfig(
          icon: Icons.swap_horiz_rounded,
          color: Colors.orange,
        );
      case 'send':
        return const _TransactionIconConfig(
          icon: Icons.north_east_rounded,
          color: Colors.blue,
        );
      default:
        return const _TransactionIconConfig(
          icon: Icons.receipt_long_rounded,
          color: Colors.white70,
        );
    }
  }
}

class _TransactionIconConfig {
  final IconData icon;
  final Color color;

  const _TransactionIconConfig({
    required this.icon,
    required this.color,
  });
}
