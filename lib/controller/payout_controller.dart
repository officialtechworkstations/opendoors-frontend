// ignore_for_file: avoid_print, unused_local_variable

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/model/add%20property%20model/proout_info.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:http/http.dart' as http;

class PayOutController extends GetxController implements GetxService {
  PayoutInfo? payoutInfo;
  bool isLoading = false;
  RxBool isLoadingPayRequest = RxBool(false);

  TextEditingController amount = TextEditingController();
  TextEditingController upi = TextEditingController();
  TextEditingController accountNumber = TextEditingController();
  TextEditingController bankName = TextEditingController();
  TextEditingController accountHolderName = TextEditingController();
  TextEditingController ifscCode = TextEditingController();
  TextEditingController emailId = TextEditingController();

  PayOutController() {
    getPayOutList();
  }

  getPayOutList() async {
    try {
      Map map = {
        "owner_id": getData.read("UserLogin")["id"],
      };
      Uri uri = Uri.parse(Config.path + Config.payOutList);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      log(response.statusCode.toString());
      // log(response.body.toString());

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        log(result.toString());
        payoutInfo = PayoutInfo.fromJson(result);
      }
      isLoading = true;
      update();
    } catch (e) {
      print(e.toString());
    }
  }

  emptyDetails() {
    amount.text = "";
    accountNumber.text = "";
    bankName.text = "";
    accountHolderName.text = "";
    ifscCode.text = "";
    upi.text = "";
    emailId.text = "";
    update();
  }

  requestWithdraweApi({String? rType}) async {
    isLoadingPayRequest.value = true;
    update();
    try {
      Map map = {
        "owner_id": getData.read("UserLogin")["id"],
        "amt": amount.text,
        "r_type": rType,
        "acc_number": accountNumber.text,
        "bank_name": bankName.text,
        "acc_name": accountHolderName.text,
        "ifsc_code": '',

        // "ifsc_code": ifscCode.text, NOTE!REMOVED FOR NOW
        "upi_id": upi.text,
        "paypal_id": emailId.text,
      };
      // print(map.toString());

      Uri uri = Uri.parse(Config.path + Config.requestWithdraw);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );

      if (response.statusCode == 200) {
        // log('message');
        var result = jsonDecode(response.body);
        //log(result);

        // log(result.toString());

        // Check ResponseCode from the body, not HTTP status
        if (result["Result"] == "true") {
          emptyDetails();
          getPayOutList();
          Get.back();
          showToastMessage(result["ResponseMsg"], ToastGravity.TOP);
        } else {
          // Handle all error cases from the API
          showToastMessage(
              result["ResponseMsg"] ?? 'Unknown error', ToastGravity.TOP);
        }
      } else {
        // Handle HTTP-level errors
        showToastMessage(
            'Server error: ${response.statusCode}', ToastGravity.TOP);
      }

      // print(response.body);

      // if (response.statusCode == 200) {
      //   var result = jsonDecode(response.body);
      //   print(result.toString());
      //   if (result["Result"] == "true") {
      //     emptyDetails();
      //     getPayOutList();
      //     Get.back();
      //     showToastMessage(result["ResponseMsg"], ToastGravity.TOP);
      //   } else {
      //     showToastMessage(result["ResponseMsg"], ToastGravity.TOP);
      //   }
      // }

      // if (response.statusCode == 401) {
      //   var result = jsonDecode(response.body);
      //   print(result['ResponseMsg'].toString());
      //   showToastMessage(result['ResponseMsg'].toString(), ToastGravity.TOP);
      // }
    } catch (e) {
      print(e.toString());
      showToastMessage('something went wrong', ToastGravity.TOP);
    } finally {
      isLoadingPayRequest.value = false;
      update();
    }
  }
}
