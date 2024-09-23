import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:integration_test/integration_test.dart';

import 'in_app_webview/main.dart' as in_app_webview_tests;
import 'find_interaction_controller/main.dart'
    as find_interaction_controller_tests;
import 'service_worker_controller/main.dart' as service_worker_controller_tests;
import 'proxy_controller/main.dart' as proxy_controller_tests;
import 'headless_in_app_webview/main.dart' as headless_in_app_webview_tests;
import 'cookie_manager/main.dart' as cookie_manager_tests;
import 'in_app_browser/main.dart' as in_app_browser_tests;
import 'chrome_safari_browser/main.dart' as chrome_safari_browser_tests;
import 'in_app_localhost_server/main.dart' as in_app_localhost_server_tests;
import 'tracing_controller/main.dart' as tracing_controller_tests;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  WebView.debugLoggingSettings.usePrint = true;
  WebView.debugLoggingSettings.maxLogMessageLength = 7000;
  InAppBrowser.debugLoggingSettings.usePrint = true;
  InAppBrowser.debugLoggingSettings.maxLogMessageLength = 7000;
  ChromeSafariBrowser.debugLoggingSettings.usePrint = true;
  ChromeSafariBrowser.debugLoggingSettings.maxLogMessageLength = 7000;
  WebAuthenticationSession.debugLoggingSettings.usePrint = true;
  WebAuthenticationSession.debugLoggingSettings.maxLogMessageLength = 7000;
  PullToRefreshController.debugLoggingSettings.usePrint = true;
  PullToRefreshController.debugLoggingSettings.maxLogMessageLength = 7000;
  FindInteractionController.debugLoggingSettings.usePrint = true;
  FindInteractionController.debugLoggingSettings.maxLogMessageLength = 7000;

  in_app_webview_tests.main();
  find_interaction_controller_tests.main();
  service_worker_controller_tests.main();
  proxy_controller_tests.main();
  tracing_controller_tests.main();
  headless_in_app_webview_tests.main();
  cookie_manager_tests.main();
  in_app_browser_tests.main();
  chrome_safari_browser_tests.main();
  in_app_localhost_server_tests.main();
}
