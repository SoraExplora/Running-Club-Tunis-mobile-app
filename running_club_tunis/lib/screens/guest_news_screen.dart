import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';


class GuestNewsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const GuestNewsScreen({
    super.key,
    required this.onToggleTheme,
  });

  @override
  State<GuestNewsScreen> createState() => _GuestNewsScreenState();
}

class _GuestNewsScreenState extends State<GuestNewsScreen> {
  late final WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Only initialize webview on mobile platforms
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
            onWebResourceError: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse('https://runningclubtunis.blogspot.com/'));
    } else {
      _controller = null;
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/RCTCONNECT.png', height: 30),
        ),
        title: const Text("RCT News"),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          if (!kIsWeb)
            IconButton(
              onPressed: () => _controller?.reload(),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: kIsWeb
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.web, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "WebView not supported on web platform",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please visit the blog directly:",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // In a real app, you'd use url_launcher here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Visit: https://runningclubtunis.blogspot.com/'),
                        ),
                      );
                    },
                    child: const Text("runningclubtunis.blogspot.com"),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                if (_controller != null) WebViewWidget(controller: _controller),
                if (_isLoading) const LinearProgressIndicator(minHeight: 2),
              ],
            ),
    );
  }
}
