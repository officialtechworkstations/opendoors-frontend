// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:get/get.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/model/country_info.dart';
import 'package:http/http.dart' as http;
import 'package:opendoors/utils/app_logger.dart';

class SelectCountryController extends GetxController implements GetxService {
  CountryInfo? countryInfo;
  List<String> countryList = [];

  int? currentIndex;

  bool isLoading = false;

  Future changeCountryIndex(int index) async {
    currentIndex = index;
    save("currentIndex", currentIndex);
    update();
  }

  Future getCountryApi() async {
    if (isLoading && countryInfo != null) return;
    try {
      Map map = {
        "uid": getData.read("UserLogin") == null
            ? "0"
            : "${getData.read("UserLogin")["id"]}",
      };
      Uri uri = Uri.parse(Config.path + Config.allCountry);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        if (result['Result']?.toString() != 'true' ||
            result['CountryData'] is! List) {
          AppLogger.warning('CountryApi', 'Country request rejected', data: {
            'status': response.statusCode,
            'response_code': result['ResponseCode'],
            'message': result['ResponseMsg'],
          });
          return;
        }
        countryList = [];
        for (var element in result["CountryData"]) {
          countryList.add(element["title"]);
        }
        countryInfo = CountryInfo.fromJson(result);
      }
      isLoading = true;
      update();
    } catch (error, stackTrace) {
      AppLogger.error('CountryApi', 'Country request failed',
          error: error, stackTrace: stackTrace);
    }
  }
}
