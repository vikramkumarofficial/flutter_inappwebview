import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../types/custom_tabs_navigation_event_type.dart';
import '../types/custom_tabs_relation_type.dart';
import '../types/prewarming_token.dart';
import '../util.dart';
import '../debug_logging_settings.dart';

import '../web_uri.dart';
import 'chrome_safari_browser_settings.dart';
import 'chrome_safari_action_button.dart';
import 'chrome_safari_browser_menu_item.dart';
import 'chrome_safari_browser_secondary_toolbar.dart';

///This class uses native [Chrome Custom Tabs](https://developer.android.com/reference/android/support/customtabs/package-summary) on Android
///and [SFSafariViewController](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller) on iOS.
///
///**NOTE**: If you want to use the `ChromeSafariBrowser` class on Android 11+ you need to specify your app querying for
///`android.support.customtabs.action.CustomTabsService` in your `AndroidManifest.xml`
///(you can read more about it here: https://developers.google.com/web/android/custom-tabs/best-practices#applications_targeting_android_11_api_level_30_or_above).
///
///**Supported Platforms/Implementations**:
///- Android
///- iOS
class ChromeSafariBrowser {
  ///Debug settings.
  static DebugLoggingSettings debugLoggingSettings = DebugLoggingSettings();

  ///View ID used internally.
  late final String id;

  ChromeSafariBrowserActionButton? _actionButton;
  Map<int, ChromeSafariBrowserMenuItem> _menuItems = new HashMap();
  ChromeSafariBrowserSecondaryToolbar? _secondaryToolbar;
  bool _isOpened = false;
  MethodChannel? _channel;
  static const MethodChannel _sharedChannel =
      const MethodChannel('com.pichillilorenzo/flutter_chromesafaribrowser');

  ChromeSafariBrowser() {
    id = IdGenerator.generate();
    this._channel =
        MethodChannel('com.pichillilorenzo/flutter_chromesafaribrowser_$id');
    this._channel?.setMethodCallHandler((call) async {
      try {
        return await _handleMethod(call);
      } on Error catch (e) {
        print(e);
        print(e.stackTrace);
      }
    });
    _isOpened = false;
  }

  _init() {
    this._channel =
        MethodChannel('com.pichillilorenzo/flutter_chromesafaribrowser_$id');
    this._channel?.setMethodCallHandler((call) async {
      try {
        return await _handleMethod(call);
      } on Error catch (e) {
        print(e);
        print(e.stackTrace);
      }
    });
  }

  _debugLog(String method, dynamic args) {
    debugLog(
        className: this.runtimeType.toString(),
        id: id,
        debugLoggingSettings: ChromeSafariBrowser.debugLoggingSettings,
        method: method,
        args: args);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    _debugLog(call.method, call.arguments);

    switch (call.method) {
      case "onServiceConnected":
        onServiceConnected();
        break;
      case "onOpened":
        onOpened();
        break;
      case "onCompletedInitialLoad":
        final bool? didLoadSuccessfully = call.arguments["didLoadSuccessfully"];
        onCompletedInitialLoad(didLoadSuccessfully);
        break;
      case "onInitialLoadDidRedirect":
        final String? url = call.arguments["url"];
        final WebUri? uri = url != null ? WebUri(url) : null;
        onInitialLoadDidRedirect(uri);
        break;
      case "onNavigationEvent":
        final navigationEvent = CustomTabsNavigationEventType.fromNativeValue(
            call.arguments["navigationEvent"]);
        onNavigationEvent(navigationEvent);
        break;
      case "onRelationshipValidationResult":
        final relation =
            CustomTabsRelationType.fromNativeValue(call.arguments["relation"]);
        final requestedOrigin = call.arguments["requestedOrigin"] != null
            ? WebUri(call.arguments["requestedOrigin"])
            : null;
        final bool result = call.arguments["result"];
        onRelationshipValidationResult(relation, requestedOrigin, result);
        break;
      case "onWillOpenInBrowser":
        onWillOpenInBrowser();
        break;
      case "onClosed":
        _isOpened = false;
        _dispose();
        onClosed();
        break;
      case "onItemActionPerform":
        String url = call.arguments["url"];
        String title = call.arguments["title"];
        int id = call.arguments["id"].toInt();
        if (this._actionButton?.id == id) {
          if (this._actionButton?.action != null) {
            this._actionButton?.action!(url, title);
          }
          if (this._actionButton?.onClick != null) {
            this._actionButton?.onClick!(WebUri(url), title);
          }
        } else if (this._menuItems[id] != null) {
          if (this._menuItems[id]?.action != null) {
            this._menuItems[id]?.action!(url, title);
          }
          if (this._menuItems[id]?.onClick != null) {
            this._menuItems[id]?.onClick!(WebUri(url), title);
          }
        }
        break;
      case "onSecondaryItemActionPerform":
        final clickableIDs = this._secondaryToolbar?.clickableIDs;
        if (clickableIDs != null) {
          WebUri? url = call.arguments["url"] != null
              ? WebUri(call.arguments["url"])
              : null;
          String name = call.arguments["name"];
          for (final clickable in clickableIDs) {
            var clickableFullname = clickable.id.name;
            if (clickable.id.defType != null &&
                !clickableFullname.contains("/")) {
              clickableFullname = "${clickable.id.defType}/$clickableFullname";
            }
            if (clickable.id.defPackage != null &&
                !clickableFullname.contains(":")) {
              clickableFullname =
                  "${clickable.id.defPackage}:$clickableFullname";
            }
            if (clickableFullname == name) {
              if (clickable.onClick != null) {
                clickable.onClick!(url);
              }
              break;
            }
          }
        }
        break;
      default:
        throw UnimplementedError("Unimplemented ${call.method} method");
    }
  }

  ///Opens the [ChromeSafariBrowser] instance with an [url].
  ///
  ///[url] - The [url] to load. On iOS, the [url] is required and must use the `http` or `https` scheme.
  ///
  ///[headers] (Supported only on Android) - [whitelisted](https://fetch.spec.whatwg.org/#cors-safelisted-request-header) cross-origin request headers.
  ///It is possible to attach non-whitelisted headers to cross-origin requests, when the server and client are related using a
  ///[digital asset link](https://developers.google.com/digital-asset-links/v1/getting-started).
  ///
  ///[otherLikelyURLs] - Other likely destinations, sorted in decreasing likelihood order. Supported only on Android.
  ///
  ///[referrer] - referrer header. Supported only on Android.
  ///
  ///[options] - Deprecated. Use `settings` instead.
  ///
  ///[settings] - Settings for the [ChromeSafariBrowser].
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android
  ///- iOS
  Future<void> open(
      {WebUri? url,
      Map<String, String>? headers,
      List<WebUri>? otherLikelyURLs,
      WebUri? referrer,
      @Deprecated('Use settings instead')
          // ignore: deprecated_member_use_from_same_package
          ChromeSafariBrowserClassOptions? options,
      ChromeSafariBrowserSettings? settings}) async {
    assert(!_isOpened, 'The browser is already opened.');
    _isOpened = true;

    if (Util.isIOS) {
      assert(url != null, 'The specified URL must not be null on iOS.');
      assert(['http', 'https'].contains(url!.scheme),
          'The specified URL has an unsupported scheme. Only HTTP and HTTPS URLs are supported on iOS.');
    }
    if (url != null) {
      assert(url.toString().isNotEmpty, 'The specified URL must not be empty.');
    }

    _init();

    List<Map<String, dynamic>> menuItemList = [];
    _menuItems.forEach((key, value) {
      menuItemList.add(value.toMap());
    });

    var initialSettings = settings?.toMap() ??
        options?.toMap() ??
        ChromeSafariBrowserSettings().toMap();

    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('id', () => id);
    args.putIfAbsent('url', () => url?.toString());
    args.putIfAbsent('headers', () => headers);
    args.putIfAbsent('otherLikelyURLs',
        () => otherLikelyURLs?.map((e) => e.toString()).toList());
    args.putIfAbsent('referrer', () => referrer?.toString());
    args.putIfAbsent('settings', () => initialSettings);
    args.putIfAbsent('actionButton', () => _actionButton?.toMap());
    args.putIfAbsent('secondaryToolbar', () => _secondaryToolbar?.toMap());
    args.putIfAbsent('menuItemList', () => menuItemList);
    await _sharedChannel.invokeMethod('open', args);
  }

  ///Tells the browser to launch with [url].
  ///
  ///[url] - initial url.
  ///
  ///[headers] (Supported only on Android) - [whitelisted](https://fetch.spec.whatwg.org/#cors-safelisted-request-header) cross-origin request headers.
  ///It is possible to attach non-whitelisted headers to cross-origin requests, when the server and client are related using a
  ///[digital asset link](https://developers.google.com/digital-asset-links/v1/getting-started).
  ///
  ///[otherLikelyURLs] - Other likely destinations, sorted in decreasing likelihood order.
  ///
  ///[referrer] - referrer header. Supported only on Android.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android
  Future<void> launchUrl({
    required WebUri url,
    Map<String, String>? headers,
    List<WebUri>? otherLikelyURLs,
    WebUri? referrer,
  }) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('url', () => url.toString());
    args.putIfAbsent('headers', () => headers);
    args.putIfAbsent('otherLikelyURLs',
        () => otherLikelyURLs?.map((e) => e.toString()).toList());
    args.putIfAbsent('referrer', () => referrer?.toString());
    await _channel?.invokeMethod("launchUrl", args);
  }

  ///Tells the browser of a likely future navigation to a URL.
  ///The most likely URL has to be specified first.
  ///Optionally, a list of other likely URLs can be provided.
  ///They are treated as less likely than the first one, and have to be sorted in decreasing priority order.
  ///These additional URLs may be ignored. All previous calls to this method will be deprioritized.
  ///
  ///[url] - Most likely URL, may be null if otherLikelyBundles is provided.
  ///
  ///[otherLikelyURLs] - Other likely destinations, sorted in decreasing likelihood order.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android ([Official API - CustomTabsSession.mayLaunchUrl](https://developer.android.com/reference/androidx/browser/customtabs/CustomTabsSession#mayLaunchUrl(android.net.Uri,android.os.Bundle,java.util.List%3Candroid.os.Bundle%3E)))
  Future<bool> mayLaunchUrl(
      {WebUri? url, List<WebUri>? otherLikelyURLs}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('url', () => url?.toString());
    args.putIfAbsent('otherLikelyURLs',
        () => otherLikelyURLs?.map((e) => e.toString()).toList());
    return await _channel?.invokeMethod("mayLaunchUrl", args);
  }

  ///Requests to validate a relationship between the application and an origin.
  ///
  ///See [here](https://developers.google.com/digital-asset-links/v1/getting-started) for documentation about Digital Asset Links.
  ///This methods requests the browser to verify a relation with the calling application, to grant the associated rights.
  ///
  ///If this method returns `true`, the validation result will be provided through [onRelationshipValidationResult].
  ///Otherwise the request didn't succeed.
  ///
  ///[relation] – Relation to check, must be one of the [CustomTabsRelationType] constants.
  ///
  ///[origin] – Origin.
  ///
  ///[extras] – Reserved for future use.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android ([Official API - CustomTabsSession.validateRelationship](https://developer.android.com/reference/androidx/browser/customtabs/CustomTabsSession#validateRelationship(int,android.net.Uri,android.os.Bundle)))
  Future<bool> validateRelationship(
      {required CustomTabsRelationType relation,
      required WebUri origin}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('relation', () => relation.toNativeValue());
    args.putIfAbsent('origin', () => origin.toString());
    return await _channel?.invokeMethod("validateRelationship", args);
  }

  ///Closes the [ChromeSafariBrowser] instance.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android
  ///- iOS
  Future<void> close() async {
    Map<String, dynamic> args = <String, dynamic>{};
    await _channel?.invokeMethod("close", args);
  }

  ///Set a custom action button.
  ///
  ///**NOTE**: Not available in a Trusted Web Activity.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android ([Official API - CustomTabsIntent.Builder.setActionButton](https://developer.android.com/reference/androidx/browser/customtabs/CustomTabsIntent.Builder#setActionButton(android.graphics.Bitmap,%20java.lang.String,%20android.app.PendingIntent,%20boolean)))
  void setActionButton(ChromeSafariBrowserActionButton actionButton) {
    this._actionButton = actionButton;
  }

  ///Updates the [ChromeSafariBrowserActionButton.icon] and [ChromeSafariBrowserActionButton.description].
  ///
  ///**NOTE**: Not available in a Trusted Web Activity.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android ([Official API - CustomTabsSession.setActionButton](https://developer.android.com/reference/androidx/browser/customtabs/CustomTabsSession#setActionButton(android.graphics.Bitmap,java.lang.String)))
  Future<void> updateActionButton(
      {required Uint8List icon, required String description}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('icon', () => icon);
    args.putIfAbsent('description', () => description);
    await _channel?.invokeMethod("updateActionButton", args);
    _actionButton?.icon = icon;
    _actionButton?.description = description;
  }

  ///Sets the remote views displayed in the secondary toolbar in a custom tab.
  ///
  ///**NOTE**: Not available in a Trusted Web Activity.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android ([Official API - CustomTabsIntent.Builder.setSecondaryToolbarViews](https://developer.android.com/reference/androidx/browser/customtabs/CustomTabsIntent.Builder#setSecondaryToolbarViews(android.widget.RemoteViews,int[],android.app.PendingIntent)))
  void setSecondaryToolbar(
      ChromeSafariBrowserSecondaryToolbar secondaryToolbar) {
    this._secondaryToolbar = secondaryToolbar;
  }

  ///Sets or updates (if already present) the Remote Views of the secondary toolbar in an existing custom tab session.
  ///
  ///**NOTE**: Not available in a Trusted Web Activity.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android ([Official API - CustomTabsSession.setSecondaryToolbarViews](https://developer.android.com/reference/androidx/browser/customtabs/CustomTabsSession#setSecondaryToolbarViews(android.widget.RemoteViews,int[],android.app.PendingIntent)))
  Future<void> updateSecondaryToolbar(
      ChromeSafariBrowserSecondaryToolbar secondaryToolbar) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('secondaryToolbar', () => secondaryToolbar.toMap());
    await _channel?.invokeMethod("updateSecondaryToolbar", args);
    this._secondaryToolbar = secondaryToolbar;
  }

  ///Adds a [ChromeSafariBrowserMenuItem] to the menu.
  ///
  ///**NOTE**: Not available in an Android Trusted Web Activity.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android
  ///- iOS
  void addMenuItem(ChromeSafariBrowserMenuItem menuItem) {
    this._menuItems[menuItem.id] = menuItem;
  }

  ///Adds a list of [ChromeSafariBrowserMenuItem] to the menu.
  ///
  ///**NOTE**: Not available in an Android Trusted Web Activity.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android
  ///- iOS
  void addMenuItems(List<ChromeSafariBrowserMenuItem> menuItems) {
    menuItems.forEach((menuItem) {
      this._menuItems[menuItem.id] = menuItem;
    });
  }

  ///On Android, returns `true` if Chrome Custom Tabs is available.
  ///On iOS, returns `true` if SFSafariViewController is available.
  ///Otherwise returns `false`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android
  ///- iOS
  static Future<bool> isAvailable() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _sharedChannel.invokeMethod("isAvailable", args);
  }

  ///The maximum number of allowed secondary toolbar items.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android
  static Future<int> getMaxToolbarItems() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _sharedChannel.invokeMethod("getMaxToolbarItems", args);
  }

  ///Clear associated website data accrued from browsing activity within your app.
  ///This includes all local storage, cached resources, and cookies.
  ///
  ///**NOTE for iOS**: available on iOS 16.0+.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS ([Official API - SFSafariViewController.DataStore.clearWebsiteData](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller/datastore/3981117-clearwebsitedata))
  static Future<void> clearWebsiteData() async {
    Map<String, dynamic> args = <String, dynamic>{};
    await _sharedChannel.invokeMethod("clearWebsiteData", args);
  }

  ///Prewarms a connection to each URL. SFSafariViewController will automatically use a
  ///prewarmed connection if possible when loading its initial URL.
  ///
  ///Returns a token object that corresponds to the requested URLs. You must keep a strong
  ///reference to this token as long as you expect the prewarmed connections to remain open. If the same
  ///server is requested in multiple calls to this method, all of the corresponding tokens must be
  ///invalidated or released to end the prewarmed connection to that server.
  ///
  ///This method uses a best-effort approach to prewarming connections, but may delay
  ///or drop requests based on the volume of requests made by your app. Use this method when you expect
  ///to present the browser soon. Many HTTP servers time out connections after a few minutes.
  ///After a timeout, prewarming delivers less performance benefit.
  ///
  ///[URLs] - the URLs of servers that the browser should prewarm connections to.
  ///Only supports URLs with `http://` or `https://` schemes.
  ///
  ///**NOTE for iOS**: available on iOS 15.0+.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS ([Official API - SFSafariViewController.prewarmConnections](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller/3752133-prewarmconnections))
  static Future<PrewarmingToken?> prewarmConnections(List<WebUri> URLs) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('URLs', () => URLs.map((e) => e.toString()).toList());
    Map<String, dynamic>? result =
        (await _sharedChannel.invokeMethod("prewarmConnections", args))
            ?.cast<String, dynamic>();
    return PrewarmingToken.fromMap(result);
  }

  ///Ends all prewarmed connections associated with the token, except for connections that are also kept alive by other tokens.
  ///
  ///**NOTE for iOS**: available on iOS 15.0+.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS ([Official API - SFSafariViewController.prewarmConnections](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller/3752133-prewarmconnections))
  static Future<void> invalidatePrewarmingToken(
      PrewarmingToken prewarmingToken) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('prewarmingToken', () => prewarmingToken.toMap());
    await _sharedChannel.invokeMethod("invalidatePrewarmingToken", args);
  }

  ///Event fired when the when connecting from Android Custom Tabs Service.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android
  void onServiceConnected() {}

  ///Event fired when the [ChromeSafariBrowser] is opened.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android
  ///- iOS
  void onOpened() {}

  ///Event fired when the initial URL load is complete.
  ///
  ///[didLoadSuccessfully] - `true` if loading completed successfully; otherwise, `false`. Supported only on iOS.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android
  ///- iOS ([Official API - SFSafariViewControllerDelegate.safariViewController](https://developer.apple.com/documentation/safariservices/sfsafariviewcontrollerdelegate/1621215-safariviewcontroller))
  void onCompletedInitialLoad(bool? didLoadSuccessfully) {}

  ///Event fired when the initial URL load is complete.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS ([Official API - SFSafariViewControllerDelegate.safariViewController](https://developer.apple.com/documentation/safariservices/sfsafariviewcontrollerdelegate/2923545-safariviewcontroller))
  void onInitialLoadDidRedirect(WebUri? url) {}

  ///Event fired when a navigation event happens.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android ([Official API - CustomTabsCallback.onNavigationEvent](https://developer.android.com/reference/androidx/browser/customtabs/CustomTabsCallback#onNavigationEvent(int,android.os.Bundle)))
  void onNavigationEvent(CustomTabsNavigationEventType? navigationEvent) {}

  ///Event fired when a relationship validation result is available.
  ///
  ///[relation] - Relation for which the result is available. Value previously passed to [validateRelationship].
  ///
  ///[requestedOrigin] - Origin requested. Value previously passed to [validateRelationship].
  ///
  ///[result] - Whether the relation was validated.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android ([Official API - CustomTabsCallback.onRelationshipValidationResult](https://developer.android.com/reference/androidx/browser/customtabs/CustomTabsCallback#onRelationshipValidationResult(int,android.net.Uri,boolean,android.os.Bundle)))
  void onRelationshipValidationResult(
      CustomTabsRelationType? relation, WebUri? requestedOrigin, bool result) {}

  ///Event fired when the user opens the current page in the default browser by tapping the toolbar button.
  ///
  ///**NOTE for iOS**: available on iOS 14.0+.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS ([Official API - SFSafariViewControllerDelegate.safariViewControllerWillOpenInBrowser](https://developer.apple.com/documentation/safariservices/sfsafariviewcontrollerdelegate/3650426-safariviewcontrollerwillopeninbr))
  void onWillOpenInBrowser() {}

  ///Event fired when the [ChromeSafariBrowser] is closed.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android
  ///- iOS
  void onClosed() {}

  ///Returns `true` if the [ChromeSafariBrowser] instance is opened, otherwise `false`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android
  ///- iOS
  bool isOpened() {
    return _isOpened;
  }

  ///Disposes the channel.
  void _dispose() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
  }
}
