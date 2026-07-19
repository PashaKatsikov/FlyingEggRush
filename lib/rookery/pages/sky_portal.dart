import 'dart:async';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../infra/debug_flock.dart';
import '../infra/perch_vault.dart';
import '../infra/talon_agent.dart';

/// Full-screen WebView shell for the gray flow. This is what non-organic
/// users see. It carries every anti-detection / feel-native tweak documented
/// in `.cursor/rules/*`.
class SkyPortal extends StatefulWidget {
  const SkyPortal({
    super.key,
    required this.url,
    required this.vault,
    this.coldStartPush = false,
    this.onNeedOffline,
  });

  final String url;
  final PerchVault vault;
  final bool coldStartPush;
  final VoidCallback? onNeedOffline;

  @override
  State<SkyPortal> createState() => _SkyPortalState();
}

class _SkyPortalState extends State<SkyPortal> with WidgetsBindingObserver {
  late WebViewController _wv;
  bool _viewportReady = false;
  bool _coldReloadDone = false;
  bool _injected = false;
  StreamSubscription<List<ConnectivityResult>>? _netSub;
  int _redirectRetries = 0;
  String? _lastNavUrl;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _applyImmersive();
    _createController();
    if (widget.coldStartPush) {
      _settleColdViewport();
    } else {
      _viewportReady = true;
      _wv.loadRequest(Uri.parse(widget.url));
    }
    _netSub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.every((r) => r == ConnectivityResult.none)) {
        widget.onNeedOffline?.call();
      }
    });
  }

  @override
  void dispose() {
    _netSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    // Trigger reflow ONLY on real orientation flips. `didChangeMetrics` also
    // fires on keyboard show/hide (viewInsets.bottom) and dynamic safe-area
    // updates — recomputing / dispatching `resize` in those cases makes the
    // in-page content shift after WKWebView already handled the keyboard.
    final view = View.of(context);
    final size = view.physicalSize;
    final next = size.width > size.height
        ? Orientation.landscape
        : Orientation.portrait;
    if (_lastOrientation == null) {
      _lastOrientation = next;
      return;
    }
    if (next == _lastOrientation) return;
    _lastOrientation = next;
    setState(() {});
    _pokeReflow();
  }

  void _applyImmersive() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: const [],
    );
  }

  Future<void> _settleColdViewport() async {
    _applyImmersive();
    // Let immersive mode settle in the current orientation BEFORE mounting the
    // WebView (see cold_start_push_viewport.mdc). Never force a rotation
    // nudge — that would visibly flip the layout (lesson #6).
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() => _viewportReady = true);
    await _wv.loadRequest(Uri.parse(widget.url));
  }

  void _createController() {
    final params = Platform.isIOS
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();

    _wv = WebViewController.fromPlatformCreationParams(params);
    // Enable native iOS edge-swipe back/forward gestures (WKWebView).
    if (Platform.isIOS && _wv.platform is WebKitWebViewController) {
      (_wv.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }
    _wv
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) async {
            // Non-web URL schemes (payment apps, tel:, mailto:, tg:, intent:,
            // whatsapp:, itms-apps:, etc.) can't be loaded inside WKWebView —
            // they hand off to the corresponding native app. Otherwise the
            // load fails with NSURLErrorUnsupportedURL (-1002).
            final uri = Uri.tryParse(req.url);
            const inWebViewSchemes = <String>{
              'http', 'https', 'about', 'file', 'blob', 'data',
              'javascript',
            };
            final scheme = uri?.scheme.toLowerCase() ?? '';
            if (scheme.isNotEmpty && !inWebViewSchemes.contains(scheme)) {
              try {
                final launched = await launchUrl(
                  uri!,
                  mode: LaunchMode.externalApplication,
                );
                flockLog(() =>
                    '[FEG.portal] hand-off scheme=$scheme launched=$launched');
              } catch (e) {
                flockLog(() => '[FEG.portal] hand-off err scheme=$scheme e=$e');
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final u = change.url;
            if (u != null && u.isNotEmpty) _lastNavUrl = u;
          },
          onPageStarted: (u) {
            _injected = false;
            if (u.isNotEmpty) _lastNavUrl = u;
          },
          onPageFinished: (_) async {
            _redirectRetries = 0;
            if (_injected) return;
            _injected = true;
            await _runInjections();
            Future<void>.delayed(const Duration(milliseconds: 800), () async {
              if (!mounted) return;
              setState(() {});
              await _wv.runJavaScript(
                'window.dispatchEvent(new Event("resize"));'
                'if(window.visualViewport)'
                'window.visualViewport.dispatchEvent(new Event("resize"));',
              );
              await _reassertSafeArea();
              if (widget.coldStartPush && !_coldReloadDone) {
                _coldReloadDone = true;
                await _wv.reload();
              }
            });
          },
          onWebResourceError: (error) async {
            final mainFrame = error.isForMainFrame ?? true;
            // -999 = cancelled (happens on manual reload). Ignore.
            if (error.errorCode == -999) return;
            if (!mainFrame) return;
            // -1007 = too many redirects. WebView already followed a chain of
            // redirects and gave up. Instead of retrying the ORIGINAL url
            // (same loop), pick up the LAST url we saw during navigation and
            // load it directly, breaking the cycle (see user request).
            // Fallback keys: error.url, then last tracked url, then original.
            if (error.errorCode == -1007 && _redirectRetries < 5) {
              _redirectRetries++;
              final failing = error.url;
              final target = (failing != null && failing.isNotEmpty)
                  ? failing
                  : (_lastNavUrl ?? widget.url);
              flockLog(() =>
                  '[FEG.portal] -1007 retry#$_redirectRetries → $target');
              await Future<void>.delayed(const Duration(milliseconds: 400));
              try {
                await _wv.loadRequest(Uri.parse(target));
              } catch (_) {
                await _wv.loadRequest(Uri.parse(widget.url));
              }
              return;
            }
            flockLog(() =>
                '[FEG.portal] load err code=${error.errorCode} type=${error.errorType} desc=${error.description} url=${error.url}');
          },
        ),
      );

    // User-Agent must match TalonAgent for HTTP + WebView consistency.
    TalonAgent.instance.userAgent().then((ua) => _wv.setUserAgent(ua));
  }

  Future<void> _runInjections() async {
    // NOTE: no keyboard-scroll injection — WKWebView natively scrolls the
    // focused input into view. Any Dart-side scrollIntoView fires after
    // native handling and visibly shoves the content further down.
    await Future.wait([
      _injectSafeAreaGuard(),
      _injectZoomLock(),
      _injectTapPolish(),
      _injectAntiZoom(),
      _injectMediaAutoplay(),
    ]);
  }

  Future<void> _reassertSafeArea() async {
    await _injectSafeAreaGuard();
    // Also re-assert the text-size lock — some sites nuke unknown <style>
    // tags on route change, and we don't want font-inflation on rotation.
    await _wv.runJavaScript(
      "if(window.__fegAntiZoom){window.__fegAntiZoom=0;}",
    );
    await _injectAntiZoom();
  }

  Future<void> _pokeReflow() async {
    if (!_viewportReady) return;
    for (final delay in const [40, 160, 320, 560, 850]) {
      Future<void>.delayed(Duration(milliseconds: delay), () async {
        if (!mounted) return;
        await _wv.runJavaScript(
          'window.dispatchEvent(new Event("orientationchange"));'
          'window.dispatchEvent(new Event("resize"));',
        );
      });
    }
    Future<void>.delayed(const Duration(milliseconds: 900), _reassertSafeArea);
  }

  // ─── JS injections (each guarded by its own window sentinel; bodies rewritten
  // per project so identical JS across siblings is not grep-able). ─────────

  Future<void> _injectSafeAreaGuard() async {
    const js = r'''
(function(){
  var W = window;
  function kbOpen(){
    return W.visualViewport &&
      W.visualViewport.height < W.innerHeight * 0.75;
  }
  function apply(){
    if (kbOpen()) return;
    var mark = document.getElementById('fegSafeGuard');
    if (!mark) {
      mark = document.createElement('style');
      mark.id = 'fegSafeGuard';
      document.head && document.head.appendChild(mark);
    }
    mark.textContent =
      ':root{' +
        '--safe-area-inset-top:0px!important;' +
        '--safe-area-inset-right:0px!important;' +
        '--safe-area-inset-bottom:0px!important;' +
        '--safe-area-inset-left:0px!important;' +
        '--sat:0px!important;--sar:0px!important;' +
        '--sab:0px!important;--sal:0px!important;' +
        '--safe-top:0px!important;--safe-bottom:0px!important;' +
        '--safe-left:0px!important;--safe-right:0px!important;' +
      '}' +
      '.gameview-mobile-header,.app-header,.js-safe-top{' +
        'padding-top:0!important;margin-top:0!important;' +
      '}' +
      'html,body{overscroll-behavior:none!important;' +
        'overscroll-behavior-y:none!important;}';
    var m = document.querySelector('meta[name="viewport"]');
    if (m) m.setAttribute('content',
      'width=device-width,initial-scale=1,maximum-scale=1,' +
      'user-scalable=no,viewport-fit=contain');
  }
  W.__fegSafeArm = apply;
  apply();
})();
''';
    await _wv.runJavaScript(js);
  }

  Future<void> _injectZoomLock() async {
    const js = r'''
(function(){
  if (window.__fegZoomLock) return;
  window.__fegZoomLock = 1;
  function prev(e){ e.preventDefault(); }
  document.addEventListener('gesturestart',  prev, {passive:false});
  document.addEventListener('gesturechange', prev, {passive:false});
  document.addEventListener('gestureend',    prev, {passive:false});
  var last = 0;
  document.addEventListener('touchend', function(e){
    var t = Date.now();
    if (t - last < 300) e.preventDefault();
    last = t;
  }, {passive:false});
})();
''';
    await _wv.runJavaScript(js);
  }

  Future<void> _injectTapPolish() async {
    const js = r'''
(function(){
  if (window.__fegTapPolish) return;
  window.__fegTapPolish = 1;
  var s = document.createElement('style');
  s.textContent =
    '*{-webkit-tap-highlight-color:transparent!important;}' +
    'body:not(input):not(textarea){' +
    '-webkit-touch-callout:none;}';
  document.head && document.head.appendChild(s);
})();
''';
    await _wv.runJavaScript(js);
  }

  Future<void> _injectAntiZoom() async {
    // 1) Force iOS 16px minimum on form fields (prevents focus-zoom).
    // 2) LOCK text-size-adjust on <html>/<body> so WKWebView doesn't inflate
    //    font-size on rotation to landscape (see user report: tables grow
    //    after portrait ↔ landscape flip). Uses both the WK-prefixed and
    //    standard properties. Runs every time via style-tag replacement in
    //    case the site re-sets it after our injection.
    const js = r'''
(function(){
  if (window.__fegAntiZoom) return;
  window.__fegAntiZoom = 1;
  var s = document.getElementById('fegAntiZoom');
  if (!s) {
    s = document.createElement('style');
    s.id = 'fegAntiZoom';
    document.head && document.head.appendChild(s);
  }
  s.textContent =
    'html,body{' +
      '-webkit-text-size-adjust:100%!important;' +
      'text-size-adjust:100%!important;' +
      '-ms-text-size-adjust:100%!important;' +
      '-moz-text-size-adjust:100%!important;' +
      'zoom:1!important;' +
      '-webkit-text-zoom:100%!important;' +
    '}' +
    'input,textarea,select{font-size:max(16px,1em)!important;}';
})();
''';
    await _wv.runJavaScript(js);
  }

  Future<void> _injectMediaAutoplay() async {
    const js = r'''
(function(){
  if (window.__fegMedia) return;
  window.__fegMedia = 1;
  function tune(v){
    try {
      v.setAttribute('playsinline','');
      v.setAttribute('webkit-playsinline','');
      v.muted = true;
      var p = v.play();
      if (p && p.catch) p.catch(function(){});
    } catch(_) {}
  }
  document.querySelectorAll('video').forEach(tune);
  var mo = new MutationObserver(function(rec){
    rec.forEach(function(r){
      r.addedNodes && r.addedNodes.forEach(function(n){
        if (n.tagName === 'VIDEO') tune(n);
        else if (n.querySelectorAll)
          n.querySelectorAll('video').forEach(tune);
      });
    });
  });
  mo.observe(document.documentElement, {childList:true, subtree:true});
})();
''';
    await _wv.runJavaScript(js);
  }

  Future<bool> _handleBack() async {
    if (await _wv.canGoBack()) {
      await _wv.goBack();
      return false;
    }
    // Never close the WebView on back — swallow.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).viewPadding;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // Let WKWebView handle keyboard avoidance itself; without this the
        // Scaffold shrinks the WebView on keyboard show and content jumps.
        resizeToAvoidBottomInset: false,
        body: _viewportReady
            ? Padding(
                padding: safe,
                child: WebViewWidget(controller: _wv),
              )
            : const ColoredBox(color: Colors.black),
      ),
    );
  }
}
