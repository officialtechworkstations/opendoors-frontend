// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings

import 'dart:convert';

import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/model/add%20property%20model/proplist_info.dart';
import 'package:http/http.dart' as http;

class ListOfPropertiController extends GetxController implements GetxService {
  PropListInfo? propListInfo;
  bool isLodding = false;
  List<String> propertyList = [];

  ListOfPropertiController() {
    getPropertiList();
  }
  Future getPropertiList() async {
    try {
      isLodding = false;
      Map map = {
        "uid": getData.read("UserLogin") == null
            ? "0" : "${getData.read("UserLogin")["id"]}",
      };
      print(".....///......." + map.toString());
      Uri uri = Uri.parse(Config.path + Config.propertyList);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        propertyList = [];
        for (var element in result["proplist"]) {
          propertyList.add(element["title"]);
        }
        propListInfo = PropListInfo.fromJson(result);
      }
      isLodding = true;
      update();
    } catch (e) {
      print(e.toString());
    }
  }
}
