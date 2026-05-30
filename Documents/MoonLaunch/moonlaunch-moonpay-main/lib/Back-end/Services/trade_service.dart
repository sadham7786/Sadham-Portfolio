import 'dart:convert';
import 'package:http/http.dart' as http;

class TradeResult {
  final String txHash;
  final String explorerUrl;

  TradeResult({required this.txHash, required this.explorerUrl});
}

class TradeService {
  static const String _base = 'https://backend.moonlaunchapp.com/api';

  /// Convert a BNB/token amount string (e.g. "0.05") to wei (decimal string).
  /// [decimals] defaults to 18 for BNB/most tokens.
  static String toWei(String amount, {int decimals = 18}) {
    final parts = amount.split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    String frac = parts.length > 1 ? parts[1] : '';

    // Pad or truncate fractional part to [decimals] digits
    if (frac.length > decimals) {
      frac = frac.substring(0, decimals);
    } else {
      frac = frac.padRight(decimals, '0');
    }

    final wholeBig = BigInt.parse(whole);
    final fracBig = BigInt.parse(frac.isEmpty ? '0' : frac);
    final multiplier = BigInt.from(10).pow(decimals);

    return (wholeBig * multiplier + fracBig).toString();
  }

  /// Buy a token with BNB via PancakeSwap V2.
  ///
  /// [walletAddress] — user's wallet (from SessionController)
  /// [tokenAddress]  — token contract to buy
  /// [bnbAmount]     — amount in BNB, e.g. "0.05"
  /// [slippageBps]   — slippage in basis points (default 500 = 5%)
  static Future<TradeResult> buy({
    required String walletAddress,
    required String tokenAddress,
    required String bnbAmount,
    int slippageBps = 500,
  }) async {
    final bnbAmountWei = toWei(bnbAmount);

    final uri = Uri.parse('$_base/trade/buy');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'wallet_address': walletAddress,
        'token_address': tokenAddress,
        'bnb_amount_wei': bnbAmountWei,
        'slippage_bps': slippageBps,
      }),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      return TradeResult(
        txHash: body['tx_hash'] as String,
        explorerUrl: body['explorer'] as String,
      );
    }

    throw body['message'] as String? ?? 'Buy failed (${res.statusCode})';
  }

  /// Sell a token for BNB via PancakeSwap V2 swapExactTokensForETH.
  ///
  /// [walletAddress] — user's wallet (from SessionController)
  /// [tokenAddress]  — token contract to sell
  /// [tokenAmount]   — human-readable amount, e.g. "1000"
  /// [decimals]      — token decimals (default 18)
  /// [slippageBps]   — slippage in basis points (default 500 = 5%)
  static Future<TradeResult> sell({
    required String walletAddress,
    required String tokenAddress,
    required String tokenAmount,
    int decimals = 18,
    int slippageBps = 500,
    String historyType = 'sell',
  }) async {
    final tokenAmountWei = toWei(tokenAmount, decimals: decimals);

    final uri = Uri.parse('$_base/trade/sell');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'wallet_address': walletAddress,
        'token_address': tokenAddress,
        'token_amount_wei': tokenAmountWei,
        'slippage_bps': slippageBps,
        'history_type': historyType,
      }),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      return TradeResult(
        txHash: body['tx_hash'] as String,
        explorerUrl: body['explorer'] as String,
      );
    }

    throw body['message'] as String? ?? 'Sell failed (${res.statusCode})';
  }

  /// Send native BNB or an ERC-20 token to [toAddress].
  ///
  /// [tokenAddress] — if null, sends native BNB
  /// [amount]       — human-readable amount, e.g. "0.1"
  /// [decimals]     — token decimals (18 for BNB/most tokens)
  static Future<TradeResult> send({
    required String walletAddress,
    required String toAddress,
    required String amount,
    String? tokenAddress,
    int decimals = 18,
  }) async {
    final amountWei = toWei(amount, decimals: decimals);

    final uri = Uri.parse('$_base/wallet/send');
    final payload = <String, dynamic>{
      'wallet_address': walletAddress,
      'to_address': toAddress,
      'amount_wei': amountWei,
    };
    if (tokenAddress != null) {
      payload['token_address'] = tokenAddress;
    }

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      return TradeResult(
        txHash: body['tx_hash'] as String,
        explorerUrl: body['explorer'] as String,
      );
    }

    throw body['message'] as String? ?? 'Send failed (${res.statusCode})';
  }
}
