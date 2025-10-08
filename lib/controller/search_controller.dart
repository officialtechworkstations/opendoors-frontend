// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, prefer_if_null_operators

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/model/homesearchmodel.dart';
import 'package:opendoors/model/search_info.dart';
import 'package:http/http.dart' as http;

class SearchPropertyController extends GetxController implements GetxService {
  TextEditingController search = TextEditingController();

  List<SearchInfo> searchData = [];
  bool isLoading = false;

  String searchText = "";

  changeValueUpdate(String value) async {
    searchText = value;
    await Future.delayed(const Duration(milliseconds: 100));
    update();
  }

  HomesearchModel? homesearchData;
  Future getSearchData(
      {String? countryId, List<String>? facility, int? price}) async {
    try {
      // List<dynamic>? savedAmenities = getData.read('selected_amenities');
      // getData.read('selected_budget');

      Map map = {
        "keyword": search.text,
        "uid": getData.read("UserLogin")?["id"]?.toString() ?? "0",
        "country_id": countryId,
        "facility": facility ?? [],
        "price": price ?? 0,
      };
      print("$map");

      Uri uri = Uri.parse(Config.path + Config.searchApi);
      print("uri {$uri}");

      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      log("response::::::::::::::::: {${response.body}}");

      if (response.statusCode == 200) {
        //  var result = response.body; // Already parsed
        // var result = jsonDecode(response.body);
        // var res = json.decode(response.body);
        // var result;
        // if (response.body is String) {
        //   result = jsonDecode(response.body);
        // } else {
        //   result = response.body; // Already parsed
        // }
        // log(res);
        homesearchData = homesearchModelFromJson(response.body);
        final d = searchIFromJson(response.body);
        // log(homesearchData!.searchPropety!.first.toString());
        // for (var element in result["search_propety"]) {
        //   searchData.add(SearchInfo.fromJson(element));
        // }
        if (d.searchInfos != null && d.searchInfos!.isNotEmpty) {
          searchData = [...d.searchInfos!];
        }
        update();
      }
      isLoading = true;
      update();
    } catch (e) {
      print("RRRRRRR");
      print(e.toString());
    } finally {
      update();
    }
  }
}
