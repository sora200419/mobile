// lib/features/marketplace/views/payment_webview_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mobiletesting/features/marketplace/services/payment_service.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String paymentId;

  const PaymentWebViewScreen({
    Key? key,
    required this.paymentUrl,
    required this.paymentId,
  }) : super(key: key);

  @override
  _PaymentWebViewScreenState createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _setupWebViewController();
  }

  void _setupWebViewController() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });

                // Check if the URL is our redirect URL
                if (url.startsWith('campuslink://payment/')) {
                  _handlePaymentRedirect(url);
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                // Handle deep links
                if (request.url.startsWith('campuslink://')) {
                  _handlePaymentRedirect(request.url);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handlePaymentRedirect(String url) async {
    // Extract status from URL (this would depend on your app's URL structure)
    bool isSuccess = url.contains('completed') || url.contains('success');

    if (isSuccess) {
      // Update payment status
      await _paymentService.updatePaymentStatus(widget.paymentId, 'completed', {
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to product screen with success result
        Navigator.pop(context, true);
      }
    } else {
      // Update payment status as failed
      await _paymentService.updatePaymentStatus(widget.paymentId, 'failed', {
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Show failure message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed or cancelled'),
            backgroundColor: Colors.red,
          ),
        );

        // Navigate back to product screen with failure result
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Payment')),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
