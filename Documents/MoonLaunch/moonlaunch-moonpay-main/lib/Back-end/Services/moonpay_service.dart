import 'dart:convert';

import 'package:http/http.dart' as http;

class MoonPayUrlResult {
  final String url;
  final String externalTxId;

  const MoonPayUrlResult({required this.url, required this.externalTxId});

  factory MoonPayUrlResult.fromJson(Map<String, dynamic> json) {
    return MoonPayUrlResult(
      url: json['url'] as String? ?? '',
      externalTxId: json['external_tx_id'] as String? ?? '',
    );
  }
}

class MoonPaySendResult {
  final String status;
  final String txHash;
  final String explorer;

  const MoonPaySendResult({
    required this.status,
    required this.txHash,
    required this.explorer,
  });

  factory MoonPaySendResult.fromJson(Map<String, dynamic> json) {
    return MoonPaySendResult(
      status: json['status'] as String? ?? '',
      txHash: json['tx_hash'] as String? ?? '',
      explorer: json['explorer'] as String? ?? '',
    );
  }
}

class MoonPayService {
  static const String _base = 'https://backend.moonlaunchapp.com/api';
  static Future<MoonPayUrlResult> createOnrampUrl({
    required String walletAddress,
    double? fiatAmount,
    String fiatCurrency = 'usd',
  }) {
    final payload = <String, dynamic>{
      'wallet_address': walletAddress,
      'fiat_currency': fiatCurrency,
    };
    if (fiatAmount != null) payload['fiat_amount'] = fiatAmount;

    return _createUrl('/moonpay/onramp-url', payload);
  }

  static Future<MoonPayUrlResult> createOfframpUrl({
    required String walletAddress,
    double? cryptoAmount,
    String fiatCurrency = 'usd',
  }) {
    final payload = <String, dynamic>{
      'wallet_address': walletAddress,
      'fiat_currency': fiatCurrency,
    };
    if (cryptoAmount != null) payload['crypto_amount'] = cryptoAmount;

    return _createUrl('/moonpay/offramp-url', payload);
  }

  static Future<MoonPaySendResult> sendSellDeposit({
    required String walletAddress,
    required String externalTxId,
  }) async {
    final uri = Uri.parse('$_base/moonpay/sell-deposit/send');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'wallet_address': walletAddress,
        'external_tx_id': externalTxId,
      }),
    );
    final body = _safeJson(res.body);

    if (res.statusCode == 200) {
      final result = MoonPaySendResult.fromJson(body);
      if (result.txHash.isEmpty) {
        throw 'MoonPay send did not return a transaction hash.';
      }
      return result;
    }

    if (res.statusCode == 422) {
      throw _extractMessage(
        body,
        fallback: 'Still preparing your sell. Please try again in a moment.',
      );
    }

    throw _extractMessage(body, fallback: 'Send failed, please retry.');
  }

  static Future<MoonPayUrlResult> _createUrl(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$_base$path');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );
    final body = _safeJson(res.body);

    if (res.statusCode == 200) {
      final result = MoonPayUrlResult.fromJson(body);
      if (result.url.isEmpty) {
        throw 'MoonPay did not return a widget URL.';
      }
      return result;
    }

    throw _extractMessage(body, fallback: 'MoonPay request failed');
  }

  static Map<String, dynamic> _safeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'message': decoded.toString()};
    } catch (_) {
      return {'message': body};
    }
  }

  static String _extractMessage(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    final message = body['message'] ?? body['error'] ?? body['msg'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }
    return fallback;
  }
}
