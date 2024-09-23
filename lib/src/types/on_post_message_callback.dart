import '../web_message/main.dart';
import '../web_uri.dart';

///The listener for handling [WebMessageListener] events sent by a `postMessage()` on the injected JavaScript object.
typedef void OnPostMessageCallback(String? message, WebUri? sourceOrigin,
    bool isMainFrame, JavaScriptReplyProxy replyProxy);
