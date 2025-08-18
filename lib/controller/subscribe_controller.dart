// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/controller/dashboard_controller.dart';
import 'package:opendoors/model/add%20property%20model/subscribe_info.dart';
import 'package:opendoors/model/routes_helper.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:http/http.dart' as http;

class SubscribeController extends GetxController implements GetxService {
  DashBoardController dashBoardController = Get.find();
  SubscribeInfo? subscribeInfo;
  bool isLoading = true;

  int? currentIndex;
  String price = "";
  String planId = "";

  changeSubscribe(int index) {
    currentIndex = index;
    update();
  }

  getSubscribeDetailsList() async {
    isLoading = false;
    update();
    try {
      Map map = {
        "uid": getData.read("UserLogin")["id"],
      };
      Uri uri = Uri.parse(Config.path + Config.subScribeList);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        if (result["is_subscribe"] == 0) {
          Get.offAndToNamed(Routes.subscribeScreen);
          isLoading = true;
          update();
        } else {
          Get.offAndToNamed(Routes.membershipScreen);
          isLoading = true;
          update();
        }
        subscribeInfo = SubscribeInfo.fromJson(result);
      }
    } catch (e) {
      isLoading = true;
      update();
      print(e.toString());
    }
  }

  bool isPlanLoading = false;
  packagePurchaseApi({String? otid, String? pName, String? walAmt}) async {

    try {
      Map map = {
        "uid": getData.read("UserLogin")["id"],
        "plan_id": planId,
        "transaction_id": otid,
        "pname": price != "0" ? pName : "Trial",
        "wall_amt" : walAmt ?? "0",
      };
      debugPrint(map.toString());
      Uri uri = Uri.parse(Config.path + Config.packagePurchase);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        print(result.toString());
        if (result["Result"] == "true") {
          dashBoardController.getDashBoardData();
          getSubscribeDetailsList();
          isPlanLoading = false;
          update();
          showToastMessage(result["ResponseMsg"]);
        } else {
          isPlanLoading = false;
          update();
        }
      } else {
        isPlanLoading = false;
        update();
      }
    } catch (e) {
      isPlanLoading = false;
      update();
      print(e.toString());
    }
  }
}
