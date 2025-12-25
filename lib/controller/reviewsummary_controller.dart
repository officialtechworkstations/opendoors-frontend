// ignore_for_file: unused_local_variable, avoid_print, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/model/payment_info.dart';
import 'package:http/http.dart' as http;

class ReviewSummaryController extends GetxController implements GetxService {
  TextEditingController note = TextEditingController();

  TextEditingController firstName = TextEditingController();
  TextEditingController lastName = TextEditingController();
  TextEditingController gmail = TextEditingController();
  TextEditingController mobile = TextEditingController();

  PaymentInfo? paymentInfo;
  bool isLodding = false;

  String pImage = "";
  String pTitle = "";
  String pCity = "";
  String pPrice = "";
  String id = "";
  String plimit = "";

  ReviewSummaryController() {
    getpaymentgatewayList();
  }

  var commissionRate = [
    {
      "amount": "2.50",
      "type": "percentage",
      "max_amount": "0.00",
      "range_from": "0.00",
      "range_to": "400000.00"
    },
    {
      "amount": "1.00",
      "type": "percentage",
      "max_amount": "0.00",
      "range_from": "400001.00",
      "range_to": "1000000.00"
    },
    {
      "amount": "0.50",
      "type": "percentage",
      "max_amount": "0.00",
      "range_from":
          "1000001.00", // Fixed: was 1000000.00, overlapped with previous range
      "range_to": "100000000.00"
    }
  ];

// ======================================
  double getOrderCommissionRate(double amount) {
    for (var i = 0; i < commissionRate.length; i++) {
      final rangeFrom = double.parse(commissionRate[i]["range_from"]!);
      final rangeTo = double.parse(commissionRate[i]["range_to"]!);

      if (amount >= rangeFrom && amount <= rangeTo) {
        return double.parse(commissionRate[i]["amount"]!);
      }
    }
    return 0;
  }

  double calculateTheOrderCommission(double amount) {
    final rate = getOrderCommissionRate(amount);

    // Convert percentage to decimal (2.50% = 0.025)
    final commissionAmount = (rate / 100) * amount;
    return commissionAmount;
  }

  getCommisionData() async {
    // isLodding = true;
    // update();

    try {
      Uri uri = Uri.parse(Config.path + Config.commissionApi);
      var response =
          await http.post(uri, body: jsonEncode({"user_type": "user"}));

      log(response.body.toString());

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        final checkResult = result["Result"];
        final commisionrate = result["commisionRate"];

        if (checkResult == true) {
          commissionRate = commisionrate;
        }
        // isLodding = false;
        update();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // ======================================

  cleanOtherDetails() {
    note.text = '';
    firstName.text = '';
    lastName.text = '';
    gmail.text = '';
    mobile.text = '';
    update();
  }

  getpaymentgatewayList() async {
    try {
      Uri uri = Uri.parse(Config.path + Config.paymentgatewayApi);
      var response = await http.post(uri);
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        paymentInfo = PaymentInfo.fromJson(result);
        isLodding = true;
        update();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  getProductObject({
    String? pim,
    String? pti,
    String? pci,
    String? pPr,
    String? pId,
    String? pLimit,
  }) {
    pImage = pim ?? "";
    pTitle = pti ?? "";
    pCity = pci ?? "";
    pPrice = pPr ?? "";
    id = pId ?? "";
    plimit = pLimit ?? "";
    print("::::::::::" + pImage);
    print("::::::::::" + pTitle);
    print("::::::::::" + pCity);
    print("::::::::::" + pPrice);
    print("::::::::::" + id);
    update();
  }
}
