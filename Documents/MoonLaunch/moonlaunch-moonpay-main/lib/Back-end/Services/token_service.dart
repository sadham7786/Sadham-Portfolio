import 'dart:convert';
import 'package:http/http.dart' as http;

class TokenModel {
  final String tokenAddress;
  final String? pairAddress;
  final String? name;
  final String? symbol;
  final String? decimals;
  final String? logo;
  final String? initialPrice;
  final String? priceCurrency;
  final String? detectedAt;
  final String? txHash;
  final String sourceType;
  final String tradeMode;
  final String status;
  final bool isTradeable;

  TokenModel({
    required this.tokenAddress,
    this.pairAddress,
    this.name,
    this.symbol,
    this.decimals,
    this.logo,
    this.initialPrice,
    this.priceCurrency,
    this.detectedAt,
    this.txHash,
    this.sourceType = 'pancakeswap',
    this.tradeMode = 'router_swap',
    this.status = 'active',
    this.isTradeable = true,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      tokenAddress: json['token_address'] as String? ?? '',
      pairAddress: json['pair_address'] as String?,
      name: json['name'] as String?,
      symbol: json['symbol'] as String?,
      decimals: json['decimals']?.toString(),
      logo: json['logo'] as String?,
      initialPrice: json['initial_price']?.toString(),
      priceCurrency: json['price_currency'] as String?,
      detectedAt: json['detected_at'] as String?,
      txHash: json['tx_hash'] as String?,
      sourceType: json['source_type'] as String? ?? 'pancakeswap',
      tradeMode: json['trade_mode'] as String? ?? 'router_swap',
      status: json['status'] as String? ?? 'active',
      isTradeable: json['is_tradeable'] == true || json['is_tradeable'] == 1,
    );
  }

  String get displayName => name ?? symbol ?? tokenAddress.substring(0, 8);
  String get displayPrice => initialPrice != null ? '\$$initialPrice' : '--';
}

class TransactionModel {
  final String source;
  final String type;
  final String externalTxId;
  final String? moonpayTxId;
  final String status;
  final String? amount;
  final String tokenOrCurrency;
  final String? fiatAmount;
  final String? fiatCurrency;
  final String? cryptoAmount;
  final String cryptoCurrency;
  final String? onChainTxHash;
  final String? explorerUrl;
  final String? failureReason;
  final String createdAt;
  final String updatedAt;

  TransactionModel({
    required this.source,
    required this.type,
    required this.externalTxId,
    this.moonpayTxId,
    required this.status,
    this.amount,
    required this.tokenOrCurrency,
    this.fiatAmount,
    this.fiatCurrency,
    this.cryptoAmount,
    required this.cryptoCurrency,
    this.onChainTxHash,
    this.explorerUrl,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      source: json['source']?.toString() ?? 'moonpay',
      type: json['type']?.toString() ?? '',
      externalTxId:
          json['external_tx_id']?.toString() ??
          json['record_id']?.toString() ??
          '',
      moonpayTxId: json['moonpay_tx_id']?.toString(),
      status: json['status']?.toString() ?? '',
      amount: json['amount']?.toString(),
      tokenOrCurrency:
          json['token_or_currency']?.toString() ??
          json['crypto_currency']?.toString() ??
          json['fiat_currency']?.toString() ??
          '',
      fiatAmount: json['fiat_amount']?.toString(),
      fiatCurrency: json['fiat_currency']?.toString(),
      cryptoAmount: json['crypto_amount']?.toString(),
      cryptoCurrency: json['crypto_currency']?.toString() ?? '',
      onChainTxHash:
          json['on_chain_tx_hash']?.toString() ?? json['tx_hash']?.toString(),
      explorerUrl: json['explorer_url']?.toString(),
      failureReason: json['failure_reason']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'type': type,
      'external_tx_id': externalTxId,
      'moonpay_tx_id': moonpayTxId,
      'status': status,
      'amount': amount,
      'token_or_currency': tokenOrCurrency,
      'fiat_amount': fiatAmount,
      'fiat_currency': fiatCurrency,
      'crypto_amount': cryptoAmount,
      'crypto_currency': cryptoCurrency,
      'on_chain_tx_hash': onChainTxHash,
      'explorer_url': explorerUrl,
      'failure_reason': failureReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class TokenService {
  static const String _base = 'https://backend.moonlaunchapp.com/api';

  static Future<List<TokenModel>> getNewLaunches({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_base/new-launches?limit=$limit&offset=$offset');

    final res = await http.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final data = decoded['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => TokenModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw 'Failed to load launches (${res.statusCode})';
  }

  static Future<TokenModel> getTokenDetail(String address) async {
    final uri = Uri.parse('$_base/token/$address');

    final res = await http.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return TokenModel.fromJson(decoded['data'] as Map<String, dynamic>);
    }
    if (res.statusCode == 404) throw 'Token not found';
    throw 'Failed to load token detail (${res.statusCode})';
  }

  /*static Future<List<TransactionModel>> getTransactionHistory(String walletAddress) async {
    print('walletAddress ${walletAddress}');
    final uri = Uri.parse('$_base/moonpay/transactions?wallet_address=$walletAddress');

    final res = await http.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      print('decoded ${decoded}');
      final data = decoded['data'] as List<dynamic>? ?? [];
      print('data ${data}');
      return data.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw 'Failed to load transaction history (${res.statusCode})';
  }*/
  static Future<List<TransactionModel>> getTransactionHistory(
    String walletAddress,
  ) async {
    print('walletAddress $walletAddress');

    final uri = Uri.parse('$_base/transactions?wallet_address=$walletAddress');

    final res = await http.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;

      print('decoded $decoded');

      final data = decoded['transactions'] as List<dynamic>? ?? [];

      print('data $data');

      return data
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw 'Failed to load transaction history (${res.statusCode})';
  }
}
