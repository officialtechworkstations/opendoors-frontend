// ignore_for_file: prefer_final_fields, unused_field, prefer_typing_uninitialized_variables, use_key_in_widget_constructors, prefer_interpolation_to_compose_strings, unnecessary_string_interpolations, await_only_futures, avoid_print, prefer_const_constructors, avoid_unnecessary_containers, file_names
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:goproperti/controller/paystack_controller.dart';
import 'package:goproperti/controller/reviewsummary_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../controller/wallet_controller.dart';
import '../../utils/Custom_widget.dart';

int verifyPaystack = -1;
class Paystackweb extends StatefulWidget {
  final String? url;
  final String skID;
  const Paystackweb({this.url, required this.skID});

  @override
  State<Paystackweb> createState() => _PaystackwebState();
}

class _PaystackwebState extends State<Paystackweb> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late WebViewController _controller;

  var progress;
  String? accessToken;
  String? payerID;
  bool isLoading = true;
  WalletController walletController = Get.put(WalletController());
  ReviewSummaryController reviewSummaryController = Get.put(ReviewSummaryController());
  PaystackController paystackController = Get.put(PaystackController());

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
            print(" > <> <> <> <> <> <> <>? <> <> <> <> <> <> <> ${widget.skID}");
            paystackController.paystackCheck(skKey: widget.skID).then((value) {
              print("PAYMENT STATUS Response: >>>>>>>>>>>>>>>> ${value["status"]}");
              if(value["status"] == true){
                verifyPaystack = 1;
                Get.back();
              } else {
                verifyPaystack = 0;
              }
            },);
          },
          onProgress: (val) {
            progress = val;
            setState(() {});
          },
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.parse(request.url);
            print("PAYMENT STATUS: >>>>>>>>>>>>>>>> $uri");
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

      ..loadRequest(Uri.parse("${widget.url}"));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;

  }

  @override
  Widget build(BuildContext context) {
    if (_scaffoldKey.currentState == null) {
      return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
          backgroundColor: Colors.black12,
          elevation: 0.0,
        ),
        body: Center(
          child: Container(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
  }

  void _verifyTransaction(String reference) async {
    final url = 'https://api.paystack.co/transaction/verify/$reference';
    final headers = {
      'Authorization': 'Bearer YOUR_SECRET_KEY',
      'Content-Type': 'application/json'
    };

    final response = await http.get(Uri.parse(url), headers: headers);
    print(">::>:>:>:>:>:>:> ${response.body}");
    if (response.statusCode == 200) {

      final Map<String, dynamic> responseBody = json.decode(response.body);
      if (responseBody['data']['status'] == 'success') {
        print("PAYMENT GET SUCCESSFUL");
        Navigator.pop(context, {'status': 'successful', 'transaction_id': reference});
      } else {
        print("PAYMENT GET FAILiER");
        Navigator.pop(context, {'status': 'failed'});
      }
    } else {
      print("PAYMENT GET ERROR");
      Navigator.pop(context, {'status': 'error'});
    }
  }
}
