// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:developer';

import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/model/add%20property%20model/dashboard_info.dart';
import 'package:opendoors/model/add%20property%20model/facility_info.dart';
import 'package:opendoors/model/add%20property%20model/protype_info.dart';
import 'package:opendoors/model/add%20property%20model/subdetails_info.dart';
import 'package:http/http.dart' as http;

class DashBoardController extends GetxController implements GetxService {
  DashBoardInfo? dashBoardInfo;
  ProTypeInfo? proTypeInfo;
  FacilityInfo? facilityInfo;
  SubDetailsInfo? subDetailsInfo;

  List<String> typeList = [];
  List<String> membershipData = [];

  String payOut = "";

  bool isLoading = false;
  bool isSubLoading = false;

  DashBoardController() {
    getDashBoardData();
    getPropartyTypeList();
    getFacilityList();
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
          await http.post(uri, body: jsonEncode({"user_type": "host"}));

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

  Future getDashBoardData() async {
    try {
      isLoading = false;
      update();
      Map map = {
        "uid": getData.read("UserLogin")["id"],
      };
      Uri uri = Uri.parse(Config.path + Config.dashboardApi);
      print(" SD:JSLDJSLJLSJDLSJDLSJDLSJDLSJDSLJDSLDJ");
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        print(result.toString());
        membershipData = [];
        for (var element in result["member_data"]) {
          membershipData.add(element["report_data"].toString());
          print("?????????????????????????? ${result["member_data"]}");
        }
        for (var element in result["report_data"]) {
          if (element["title"] == "My Earning") {
            payOut = element["report_data"].toString();
          }
        }
        Future.delayed(
          Duration(seconds: 3),
        ).then(
          (value) {
            isLoading = true;
            update();
          },
        );
        dashBoardInfo = DashBoardInfo.fromJson(result);
        print(
            "USEWRLOGIN OR NOT > <> <> <> <> <> <> <> <> <> ${dashBoardInfo}");
      }
    } catch (e) {
      isLoading = true;
      update();
      print(e.toString());
    }
  }

  getPropartyTypeList() async {
    try {
      isLoading = false;
      update();
      Uri uri = Uri.parse(Config.path + Config.propertyType);
      var response = await http.post(uri);
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        for (var element in result["typelist"]) {
          typeList.add(element["title"]);
        }
        proTypeInfo = ProTypeInfo.fromJson(result);
      }
      isLoading = true;
      update();
    } catch (e) {
      print(e.toString());
    }
  }

  getFacilityList() async {
    try {
      isLoading = false;
      update();
      Uri uri = Uri.parse(Config.path + Config.facilityList);
      var response = await http.post(uri);
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        facilityInfo = FacilityInfo.fromJson(result);
      }
      isLoading = true;
      update();
    } catch (e) {
      print(e.toString());
    }
  }

  getSubScribeDetails() async {
    try {
      Map map = {
        "uid": getData.read("UserLogin")["id"],
      };
      Uri uri = Uri.parse(Config.path + Config.subScribeDetails);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        subDetailsInfo = SubDetailsInfo.fromJson(result);
      }
      isSubLoading = true;
      update();
    } catch (e) {
      print(e.toString());
    }
  }
}
