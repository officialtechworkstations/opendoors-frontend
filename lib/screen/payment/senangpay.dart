import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:goproperti/Api/config.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../utils/Custom_widget.dart';

class Senangpay extends StatefulWidget {
  final String totalAmount;
  final String name;
  final String email;
  final String phone;
  const Senangpay({super.key, required this.totalAmount, required this.name, required this.email, required this.phone});
  @override
  State<Senangpay> createState() => _SenangpayState();
}

class _SenangpayState extends State<Senangpay> {

  late WebViewController _controller;
  var progress;
  String? accessToken;
  String? payerID;
  bool isLoading = true;
  final notificationId = UniqueKey().hashCode;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (finish) {
            readJS();
          },
          onProgress: (val) {
            progress = val;
            setState(() {});
          },
          onNavigationRequest: (NavigationRequest request) async {

            final uri = Uri.parse(request.url);
            if (uri.queryParameters["msg"] == null) {
              accessToken = uri.queryParameters["token"];
            } else {
              if (uri.queryParameters["msg"] == "Payment_was_successful") {
                payerID = await uri.queryParameters["transaction_id"];
                Get.back(result: payerID);
              } else {
                Get.back();
                showToastMessage("${uri.queryParameters["msg"]}");
              }
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )

      ..loadRequest(Uri.parse("${Config.paymentBaseUrl}result.php?detail=Movers&amount=${widget.totalAmount}&order_id=$notificationId&name=${widget.name}&email=${widget.email}&phone=${widget.phone}"));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
            ],
          ),
      ),
    );
  }
  Future readJS() async {
    setState(() {
      _controller
          .runJavaScriptReturningResult("document.documentElement.innerText")
          .then((value) async {
        if (value.toString().contains("Transaction_id")) {
          String fixed = value.toString().replaceAll(r"\'", "");
          if (GetPlatform.isAndroid) {
            String json = jsonDecode(fixed);
            var val1 = jsonStringToMap(json);
            if ((val1['ResponseCode'] == "200") && (val1['Result'] == "true")) {
              Get.back(result: val1["Transaction_id"]);
              showToastMessage(val1["ResponseMsg"]);
            } else {
              showToastMessage(val1["ResponseMsg"]);
              Get.back();
            }
          } else {
            var val2 = jsonStringToMap(fixed);
            if ((val2['ResponseCode'] == "200") && (val2['Result'] == "true")) {
              Get.back(result: val2["Transaction_id"]);
              showToastMessage(val2["ResponseMsg"]);
            } else {
              showToastMessage(val2["ResponseMsg"]);
              Get.back();
            }
          }
        }
        return "";
      });
    });
  }
  jsonStringToMap(String data) {
    List<String> str = data
        .replaceAll("{", "")
        .replaceAll("}", "")
        .replaceAll("\"", "")
        .replaceAll("'", "")
        .split(",");
    Map<String, dynamic> result = {};
    for (int i = 0; i < str.length; i++) {
      List<String> s = str[i].split(":");
      result.putIfAbsent(s[0].trim(), () => s[1].trim());
    }
    return result;
  }
}
