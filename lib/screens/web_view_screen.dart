import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.cream)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cherry,
        foregroundColor: Colors.white,
        title: Text(widget.title,
            style: AppText.title(20, color: Colors.white)),
      ),
      body: Stack(
        children: [
          if (!_error) WebViewWidget(controller: _controller),
          if (_error) _errorView(),
          if (_loading && !_error)
            const Center(
              child: CircularProgressIndicator(color: AppColors.deepGold),
            ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.deepGold),
            const SizedBox(height: 16),
            Text(
              'Could not load the page.\nCheck your connection and try again.',
              textAlign: TextAlign.center,
              style: AppText.body(16, color: AppColors.ink),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cherry,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _error = false;
                  _loading = true;
                });
                _controller.loadRequest(Uri.parse(widget.url));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
