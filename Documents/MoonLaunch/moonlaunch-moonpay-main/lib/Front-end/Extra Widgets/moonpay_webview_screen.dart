import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class MoonPayWebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final Future<String?> Function()? onSendWithMoonLaunch;

  const MoonPayWebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.onSendWithMoonLaunch,
  });

  @override
  State<MoonPayWebViewScreen> createState() =>
      _MoonPayWebViewScreenState();
}

class _MoonPayWebViewScreenState
    extends State<MoonPayWebViewScreen> {
  late final WebViewController _controller;

  int _progress = 0;
  String? _loadError;
  bool _sendInProgress = false;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;

    /// iOS WKWebView configuration
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const {},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller =
    WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'MoonLaunchBridge',
        onMessageReceived: (message) {
          if (message.message == 'send_with_moonlaunch') {
            _sendWithMoonLaunch();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _handleNavigationRequest,

          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },

          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _loadError = null);
          },

          onPageFinished: (_) async {
            await _installSendButtonBridge();
          },

          onWebResourceError: (error) {
            if (!mounted) return;

            if (error.isForMainFrame == false) return;

            if (error.description
                .contains('ERR_UNKNOWN_URL_SCHEME')) {
              return;
            }

            setState(() {
              _loadError = error.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    /// Android permissions
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);

      (controller.platform as AndroidWebViewController)
          .setOnPlatformPermissionRequest((request) {
        request.grant();
      });
    }

    _controller = controller;
  }

  NavigationDecision _handleNavigationRequest(
      NavigationRequest request,
      ) {
    final uri = Uri.tryParse(request.url);
    final scheme = uri?.scheme.toLowerCase();

    if (uri != null && _isSendWithMoonLaunchUrl(uri)) {
      _sendWithMoonLaunch();
      return NavigationDecision.prevent;
    }

    if (scheme == null ||
        scheme == 'http' ||
        scheme == 'https' ||
        scheme == 'about' ||
        scheme == 'data') {
      return NavigationDecision.navigate;
    }

    if (scheme == 'moonlaunch') {
      Navigator.pop(context);
      return NavigationDecision.prevent;
    }

    launchUrl(
      uri!,
      mode: LaunchMode.externalApplication,
    );

    return NavigationDecision.prevent;
  }

  bool _isSendWithMoonLaunchUrl(Uri uri) {
    if (widget.onSendWithMoonLaunch == null) return false;

    final normalized = uri.toString().toLowerCase();

    if (normalized.contains('send-with-moonlaunch') ||
        normalized.contains('sendwithmoonlaunch') ||
        normalized.contains('sell-deposit') ||
        normalized.contains('sell_deposit')) {
      return true;
    }

    return normalized.contains('moonlaunch') &&
        normalized.contains('send') &&
        normalized.contains('moonpay');
  }

  Future<void> _installSendButtonBridge() async {
    if (widget.onSendWithMoonLaunch == null) return;

    const script = '''
(function() {
  if (window.__moonLaunchSendBridgeInstalled) return;

  window.__moonLaunchSendBridgeInstalled = true;

  function textFor(element) {
    return (
      (
        element &&
        (
          element.innerText ||
          element.textContent ||
          element.value
        )
      ) || ''
    )
      .trim()
      .toLowerCase();
  }

  function isSendWithMoonLaunch(element) {
    return textFor(element)
      .indexOf('send with moonlaunch') !== -1;
  }

  document.addEventListener(
    'click',
    function(event) {

      var element = event.target;

      for (
        var i = 0;
        element && i < 6;
        i += 1
      ) {
        if (isSendWithMoonLaunch(element)) {

          event.preventDefault();
          event.stopPropagation();

          MoonLaunchBridge.postMessage(
            'send_with_moonlaunch'
          );

          return false;
        }

        element = element.parentElement;
      }
    },
    true
  );
})();
''';

    try {
      await _controller.runJavaScript(script);
    } catch (_) {
      // Some MoonPay pages block JS injection.
    }
  }

  Future<void> _sendWithMoonLaunch() async {
    final callback = widget.onSendWithMoonLaunch;

    if (callback == null || _sendInProgress) return;

    if (mounted) {
      setState(() {
        _sendInProgress = true;
        _loadError = null;
      });
    }

    try {
      final message = await callback();

      if (!mounted) return;

      _showSnackBar(
        message ??
            'Sent to MoonPay. Waiting for confirmation.',
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _sendInProgress = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1A1A),
        duration: const Duration(seconds: 4),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Benne',
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'BernardMTCondensed',
            color: Colors.white,
            fontSize: 22,
          ),
        ),

        actions: [
          if (widget.onSendWithMoonLaunch != null)
            IconButton(
              tooltip: 'Send with MoonLaunch',

              icon: _sendInProgress
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.send,
                color: Colors.white,
              ),

              onPressed: _sendInProgress
                  ? null
                  : _sendWithMoonLaunch,
            ),

          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _loadError = null;
              });

              _controller.reload();
            },
          ),
        ],
      ),

      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),

            if (_progress < 100)
              LinearProgressIndicator(
                value: _progress / 100,
                color: const Color(0xFFFFE600),
                backgroundColor: Colors.white12,
              ),

            if (_loadError != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF9A1117),
                    ),
                  ),

                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFFFE600),
                        size: 20,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          _loadError!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Benne',
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}