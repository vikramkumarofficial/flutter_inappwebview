// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cookie.dart';

// **************************************************************************
// ExchangeableObjectGenerator
// **************************************************************************

///Class that represents a cookie returned by the [CookieManager].
class Cookie {
  ///The cookie domain.
  ///
  ///**NOTE for Android native WebView**: available on Android only if [WebViewFeature.GET_COOKIE_INFO] feature is supported.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  ///- Android native WebView
  String? domain;

  ///The cookie expiration date in milliseconds.
  ///
  ///**NOTE for Android native WebView**: available on Android only if [WebViewFeature.GET_COOKIE_INFO] feature is supported.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  ///- Android native WebView
  int? expiresDate;

  ///Indicates if the cookie is a http only cookie.
  ///
  ///**NOTE for Android native WebView**: available on Android only if [WebViewFeature.GET_COOKIE_INFO] feature is supported.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  ///- Android native WebView
  bool? isHttpOnly;

  ///Indicates if the cookie is secure or not.
  ///
  ///**NOTE for Android native WebView**: available on Android only if [WebViewFeature.GET_COOKIE_INFO] feature is supported.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  ///- Android native WebView
  bool? isSecure;

  ///Indicates if the cookie is a session only cookie.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  bool? isSessionOnly;

  ///The cookie name.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  ///- Android native WebView
  ///- Web but iframe requires same origin
  String name;

  ///The cookie path.
  ///
  ///**NOTE for Android native WebView**: available on Android only if [WebViewFeature.GET_COOKIE_INFO] feature is supported.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  ///- Android native WebView
  String? path;

  ///The cookie same site policy.
  ///
  ///**NOTE for Android native WebView**: available on Android only if [WebViewFeature.GET_COOKIE_INFO] feature is supported.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  ///- Android native WebView
  HTTPCookieSameSitePolicy? sameSite;

  ///The cookie value.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  ///- Android native WebView
  ///- Web but iframe requires same origin
  dynamic value;
  Cookie(
      {this.domain,
      this.expiresDate,
      this.isHttpOnly,
      this.isSecure,
      this.isSessionOnly,
      required this.name,
      this.path,
      this.sameSite,
      this.value});

  ///Gets a possible [Cookie] instance from a [Map] value.
  static Cookie? fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return null;
    }
    final instance = Cookie(
      domain: map['domain'],
      expiresDate: map['expiresDate'],
      isHttpOnly: map['isHttpOnly'],
      isSecure: map['isSecure'],
      isSessionOnly: map['isSessionOnly'],
      name: map['name'],
      path: map['path'],
      sameSite: HTTPCookieSameSitePolicy.fromNativeValue(map['sameSite']),
      value: map['value'],
    );
    return instance;
  }

  ///Converts instance to a map.
  Map<String, dynamic> toMap() {
    return {
      "domain": domain,
      "expiresDate": expiresDate,
      "isHttpOnly": isHttpOnly,
      "isSecure": isSecure,
      "isSessionOnly": isSessionOnly,
      "name": name,
      "path": path,
      "sameSite": sameSite?.toNativeValue(),
      "value": value,
    };
  }

  ///Converts instance to a map.
  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() {
    return 'Cookie{domain: $domain, expiresDate: $expiresDate, isHttpOnly: $isHttpOnly, isSecure: $isSecure, isSessionOnly: $isSessionOnly, name: $name, path: $path, sameSite: $sameSite, value: $value}';
  }
}
