// // ignore_for_file: deprecated_member_use, file_names, prefer_typing_uninitialized_variables
//
// import 'dart:convert';
// import 'dart:developer';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:goevent2/Api/ApiWrapper.dart';
// import 'package:goevent2/Api/Config.dart';
// import 'package:goevent2/utils/AppWidget.dart';
// import 'package:goevent2/utils/colornotifire.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// import 'Payment_card.dart';
//
// class StripePaymentWeb extends StatefulWidget {
//   final PaymentCard paymentCard;
//   const StripePaymentWeb({Key? key, required this.paymentCard})
//       : super(key: key);
//
//   @override
//   State<StripePaymentWeb> createState() => _StripePaymentWebState();
// }
//
// class _StripePaymentWebState extends State<StripePaymentWeb> {
//   late WebViewController _controller;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   // final dMode = Get.put(DarkMode());
//
//   PaymentCard? payCard;
//   late ColorNotifire notifire;
//   var progress;
//
//   @override
//   void initState() {
//     super.initState();
//     setState(() {});
//     getdarkmodepreviousstate();
//
//     payCard = widget.paymentCard;
//     log(payCard.toString(), name: "Payment card Details :: ");
//   }
//
//   getdarkmodepreviousstate() async {
//     final prefs = await SharedPreferences.getInstance();
//     bool? previusstate = prefs.getBool("setIsDark");
//     if (previusstate == null) {
//       notifire.setIsDark = false;
//     } else {
//       notifire.setIsDark = previusstate;
//     }
//   }
//
//   String get initialUrl =>
//       Config.base_url+'/stripe/index.php?name=${payCard!.name}&email=${payCard!.email}&cardno=${payCard!.number}&cvc=${payCard!.cvv}&amt=${payCard!.amount}&mm=${payCard!.month}&yyyy=${payCard!.year}';
//   @override
//   Widget build(BuildContext context) {
//     notifire = Provider.of<ColorNotifire>(context, listen: true);
//     log(initialUrl.toString(), name: "Payment url ::");
//     if (_scaffoldKey.currentState == null) {
//       return WillPopScope(
//         onWillPop: (() async => true),
//         child: Scaffold(
//           backgroundColor: notifire.getprimerycolor,
//           body: SafeArea(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       // loading(size: 60),
//                       SizedBox(height: Get.height * 0.02),
//                       SizedBox(
//                         width: Get.width * 0.80,
//                         child: Text(
//                           'Please don`t press back until the transaction is complete'
//                               .tr,
//                           maxLines: 2,
//                           textAlign: TextAlign.center,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                               color: notifire.getdarkscolor,
//                               fontSize: 15,
//                               fontWeight: FontWeight.w500,
//                               letterSpacing: 0.5),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: Get.height * 0.01),
//                 Stack(
//                   children: [
//                     Container(
//                       color: Colors.grey.shade200,
//                       height: 25,
//                       child: WebView(
//                         backgroundColor: Colors.grey.shade200,
//                         initialUrl: initialUrl,
//                         javascriptMode: JavascriptMode.unrestricted,
//                         gestureNavigationEnabled: true,
//                         onWebViewCreated: (controller) =>
//                             _controller = controller,
//                         onPageFinished: (String url) {
//                           readJS();
//                         },
//                         onProgress: (val) {
//                           setState(() {});
//                           progress = val;
//                           log(val.toString(), name: "onProgress");
//                         },
//                       ),
//                     ),
//                     Container(
//                         height: 25,
//                         color: notifire.getprimerycolor,
//                         width: Get.width),
//                   ],
//                 )
//               ],
//             ),
//           ),
//         ),
//       );
//     } else {
//       return Scaffold(
//           key: _scaffoldKey,
//           appBar: AppBar(
//               leading: IconButton(
//                   icon: const Icon(Icons.arrow_back),
//                   onPressed: () => Get.back()),
//               backgroundColor: Colors.black12,
//               elevation: 0.0),
//           body: Center(child: loading(size: 60)));
//     }
//   }
//
//   void readJS() async {
//     setState(() {
//       _controller
//           .evaluateJavascript("document.documentElement.innerText")
//           .then((value) async {

//         if (value.contains("Transaction_id")) {
//           String fixed = value.replaceAll(r"\'", "");
//           if (GetPlatform.isAndroid) {
//             String json = jsonDecode(fixed);
//             var val = jsonStringToMap(json);
//             if ((val['ResponseCode'] == "200") && (val['Result'] == "true")) {
//               Get.back(result: val["Transaction_id"]);
//               ApiWrapper.showToastMessage(val["ResponseMsg"]);
//             } else {
//               ApiWrapper.showToastMessage(val["ResponseMsg"]);
//               Get.back();
//             }
//           } else {
//             var val = jsonStringToMap(fixed);
//             if ((val['ResponseCode'] == "200") && (val['Result'] == "true")) {
//               Get.back(result: val["Transaction_id"]);
//               ApiWrapper.showToastMessage(val["ResponseMsg"]);
//             } else {
//               ApiWrapper.showToastMessage(val["ResponseMsg"]);
//               Get.back();
//             }
//           }
//         }
//         return "";
//
//       });

//     });
//   }
//
//   jsonStringToMap(String data) {
//     List<String> str = data
//         .replaceAll("{", "")
//         .replaceAll("}", "")
//         .replaceAll("\"", "")
//         .replaceAll("'", "")
//         .split(",");
//     Map<String, dynamic> result = {};
//     for (int i = 0; i < str.length; i++) {
//       List<String> s = str[i].split(":");
//       result.putIfAbsent(s[0].trim(), () => s[1].trim());
//     }
//     return result;
//   }
// }











// ignore_for_file: deprecated_member_use, file_names, prefer_typing_uninitialized_variables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../Api/config.dart';
import '../../utils/Custom_widget.dart';


class StripePaymentWeb extends StatefulWidget {
  final String url;
  const StripePaymentWeb({Key? key,  required this.url}) : super(key: key);

  @override
  State<StripePaymentWeb> createState() => _StripePaymentWebState();
}

class _StripePaymentWebState extends State<StripePaymentWeb> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // final dMode = Get.put(DarkMode());
  late final WebViewController controller;

  var progress;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setBackgroundColor(Colors.grey.shade200)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(

          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            print("Navigating to URL: ${request.url}");
            print("Parsed URI: $uri");

            // Check the status parameter instead of Result
            var status = uri.queryParameters["status"];
            var transaction_id = uri.queryParameters["Transaction_id"];
            print("Hello Status:---- $status");
            print("Hello Status:---- $transaction_id");

            if (status == null) {
              var tranId = uri.queryParameters["Transaction_id"];
            } else {
              if(status == "success"){
                Get.back(result: uri.queryParameters["Transaction_id"]);
                showToastMessage("Payment Done Successfully");
              } else {
                showToastMessage("Something went wrong!");
                Get.back();
              }
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            readJS();
            print("URL L L L L > > > > ${Config.paymentBaseUrl}${widget.url}");
          },
          onProgress: (val) {
            progress = val;
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }

  String get initialUrl =>
      '${Config.paymentBaseUrl}${widget.url}';
  @override
  Widget build(BuildContext context) {
    if (_scaffoldKey.currentState == null) {
      return WillPopScope(
        onWillPop: (() async => true),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // loading(size: 60),
                      SizedBox(height: Get.height * 0.02),
                      SizedBox(
                        width: Get.width * 0.80,
                        child: const Text(
                          'Please don`t press back until the transaction is complete',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Get.height * 0.01),
                Stack(
                  children: [
                    Container(
                      color: Colors.grey.shade200,
                      height: 25,
                      child: WebViewWidget(
                        controller: controller,
                      ),
                    ),
                    Container(
                        height: 25, color: Colors.white, width: Get.width),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Get.back()),
              backgroundColor: Colors.black12,
              elevation: 0.0),
          body: Center(child: CircularProgressIndicator()));
    }
  }

  void readJS() async {
    controller
        .runJavaScriptReturningResult("document.documentElement.innerText")
        .then((value) {
      print("VALUE OF $value");
      if (value.toString().contains("Transaction_id")) {
        String fixed = value.toString().replaceAll(r"\'", "");
        if (GetPlatform.isAndroid) {
          String json = jsonDecode(fixed);
          var val = jsonStringToMap(json);
          if ((val['ResponseCode'] == "200") && (val['Result'] == "true")) {
            Get.back(result: val["Transaction_id"]);
            showToastMessage(val["ResponseMsg"]);
          } else {
            showToastMessage(val["ResponseMsg"]);
            Get.back();
          }
        } else {
          var val = jsonStringToMap(fixed);
          if ((val['ResponseCode'] == "200") && (val['Result'] == "true")) {
            Get.back(result: val["Transaction_id"]);
            showToastMessage(val["ResponseMsg"]);
          } else {
            showToastMessage(val["ResponseMsg"]);
            Get.back();
          }
        }
      }
      return "";
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
