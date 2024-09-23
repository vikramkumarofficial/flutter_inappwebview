import 'package:flutter_inappwebview_internal_annotations/flutter_inappwebview_internal_annotations.dart';

import '../in_app_webview/webview.dart';
import '../in_app_webview/in_app_webview_controller.dart';

import 'safe_browsing_response_action.dart';

part 'safe_browsing_response.g.dart';

///Class that represents the response used by the [WebView.onSafeBrowsingHit] event.
///It is used to indicate an action to take when hitting a malicious URL.
@ExchangeableObject()
class SafeBrowsingResponse_ {
  ///If reporting is enabled, all reports will be sent according to the privacy policy referenced by [InAppWebViewController.getSafeBrowsingPrivacyPolicyUrl].
  bool report;

  ///Indicate the [SafeBrowsingResponseAction] to take when hitting a malicious URL.
  SafeBrowsingResponseAction_? action;

  SafeBrowsingResponse_(
      {this.report = true,
      this.action = SafeBrowsingResponseAction_.SHOW_INTERSTITIAL});
}
