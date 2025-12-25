// ignore_for_file: avoid_print, unused_local_variable, prefer_interpolation_to_compose_strings, prefer_typing_uninitialized_variables, prefer_if_null_operators, prefer_const_constructors

import 'dart:convert';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/model/app_settings.dart';
import 'package:opendoors/model/catwise_info.dart';
import 'package:opendoors/model/favourite_info.dart';
import 'package:opendoors/model/homedata_info.dart';
import 'package:opendoors/model/map_info.dart';
import 'package:opendoors/model/propetydetails_Info.dart';
// import 'package:opendoors/model/routes_helper.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:http/http.dart' as http;

import '../screen/home_screen.dart';

class HomePageController extends GetxController implements GetxService {
  HomeDatatInfo? homeDatatInfo;
  PropetydetailsInfo? propetydetailsInfo;
  FavouriteInfo? favouriteInfo;

  List<MapInfo> mapInfo = [];

  String searchLocation = "";

  String chatNotice = "";
  AppSetting appSetting = AppSetting.initial();

  String rate = "";

  CatWiseInfo? catWiseInfo;

  List<int> selectedIndex = [];

  int currentIndex = 0;
  int catCurrentIndex = 0;
  int ourCurrentIndex = 0;

  bool isLoading = false;
  bool isProperty = false;
  bool isfevorite = false;
  bool isCatWise = false;

  String fevResult = "";
  String fevMsg = "";
  String enquiry = "";

  var lattitude;
  var longtitude;

  void getCameraposition() {
    kGoogle = CameraPosition(
      target: LatLng(lattitude, longtitude),
      zoom: 12,
    );
  }

  PageController pageController = PageController();

  CameraPosition kGoogle = CameraPosition(
    target: LatLng(21.2381962, 72.8879607),
    zoom: 5,
  );

  List<Marker> markers = <Marker>[];

  Future<Uint8List> getImages(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  HomePageController() {
    getHomeDataApi();
    getCatWiseData(cId: "0", countryId: getData.read("countryId"));
  }

  chnageObjectIndex(int index) {
    currentIndex = 0;
    currentIndex = index;
    update();
  }

  changeCategoryIndex(int index) {
    catCurrentIndex = 0;
    catCurrentIndex = index;
    update();
  }

  changeOurCurrentIndex(int index) {
    ourCurrentIndex = index;
    update();
  }

  getChangeLocation(String location) {
    searchLocation = location;
    Get.back();

    update();
  }

  updateMapPosition({int? index}) {
    pageController.animateToPage(index ?? 0,
        duration: Duration(seconds: 1), curve: Curves.decelerate);
    update();
  }

  String addProp = "";
  Future getHomeDataApi({String? countryId}) async {
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>COUNTRy CODE ${countryId}");
    try {
      isLoading = false;
      Map map = {
        "uid": getData.read("UserLogin") == null
            ? "0"
            : "${getData.read("UserLogin")["id"]}",
        "country_id": countryId,
      };
      print("--------(Map)-------->>" + map.toString());
      Uri uri = Uri.parse(Config.path + Config.homeDataApi);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      log(">>>>>>>>>>>>>>>>>>>>>>>> ????????????????????? ${response.body}");
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        homeDatatInfo = HomeDatatInfo.fromJson(result);
        addProp = homeDatatInfo?.homeData!.showAddProperty ?? "";
        print("ADDDPORP >>>>>>>>>>>>>>>>>> ${addProp}");
        print("CAT PROP >>>>>>>>>>>>>>>>>> ${result["HomeData"]["Catlist"]}");
        var maplist = mapInfo.reversed.toList();
        currency = homeDatatInfo?.homeData!.currency ?? "";
        update();
      }
      isLoading = true;
      update();
    } catch (e) {
      print(e.toString());
    }
  }

  Future getPropertyDetailsApi({String? id}) async {
    try {
      Map map = {
        "pro_id": id,
        "uid": getData.read("UserLogin") == null
            ? "0"
            : "${getData.read("UserLogin")["id"]}",
      };

      print("(Map)------------->>" + map.toString());

      Uri uri = Uri.parse(Config.path + Config.propertyDetails);

      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );

      print("DDDDDDDDDDDDDDDD ${response.statusCode}");

      if (response.statusCode == 200) {
        print("DATA GATED >>>>>>>>>>>>> ${response.body}");
        var result = json.decode(response.body);
        print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $result");
        propetydetailsInfo = PropetydetailsInfo.fromJson(result);
        print("> <> <> <> <> <><> <> <> ${propetydetailsInfo}");
      }

      isProperty = true;
      update();
    } catch (e) {
      print("IPL 2025 ${e.toString()}");
    }
  }

  Future getChatNoApi() async {
    try {
      // Map map = {
      //   "pro_id": id,
      //   "uid": getData.read("UserLogin") == null
      //       ? "0"
      //       : "${getData.read("UserLogin")["id"]}",
      // };

      // print("(Map)------------->>" + map.toString());

      Uri uri = Uri.parse(Config.path + Config.getAdminSetting);

      var response = await http.get(uri);

      print("CHAT NOTICE FETCHED ${response.statusCode}");

      if (response.statusCode == 200) {
        print("DATA GETED >>>>>>>>>>>>> ${response.body}");
        var result = json.decode(response.body);
        print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $result");
        chatNotice = result['FaqData']['notice_message'].toString();
        final appSDetup = AppSetting.fromJson(result['FaqData']);
        appSetting = appSDetup;
      }

      update();
    } catch (e) {
      print("Err Getting chat Notice: ${e.toString()}");
    }
  }

  addFavouriteList({String? pid, String? propertyType}) async {
    try {
      Map map = {
        "uid": getData.read("UserLogin")["id"].toString(),
        "pid": pid,
        "property_type": propertyType,
      };

      Uri uri = Uri.parse(Config.path + Config.addAndRemoveFavourite);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        fevResult = result["Result"];
        fevMsg = result["ResponseMsg"];
        getPropertyDetailsApi(id: pid);
        getFavouriteList(countryId: getData.read("countryId"));
        showToastMessage(fevMsg);
      }
      update();
    } catch (e) {
      print(e.toString());
    }
  }

  getFavouriteList({String? countryId}) async {
    try {
      Map map = {
        "uid": getData.read("UserLogin")["id"].toString(),
        "property_type": "0",
        "country_id": countryId,
      };
      print("AAAAAAAAAAAAAAA" + map.toString());
      Uri uri = Uri.parse(Config.path + Config.favouriteList);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      print("-------==========" + response.body);
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        favouriteInfo = FavouriteInfo.fromJson(result);
      }
      isfevorite = true;
      update();
    } catch (e) {
      print(e.toString());
    }
  }

  Future getCatWiseData(
      {required String? cId, required String? countryId}) async {
    print("++++++ -------- %##%#%#%#%# ${countryId}");
    Map map = {
      "cid": cId ?? "0",
      "uid": getData.read("UserLogin") == null
          ? "0"
          : getData.read("UserLogin")["id"].toString(),
      "country_id": countryId,
    };

    Uri uri = Uri.parse(Config.path + Config.catWiseData);

    print("++++++ -------- +++++++ ------- ++++++${map}");
    print("++++++ -------- +++++++ ------- ++++++${uri}");

    var response = await http.post(
      uri,
      body: jsonEncode(map),
    );
    if (response.statusCode == 200) {
      var result = jsonDecode(response.body);
      catWiseInfo = CatWiseInfo.fromJson(result);
      isCatWise = true;
      update();
      print("< >? < > < > < > < > < > < > < > <>?${catWiseInfo!.responseMsg}>");
    }
  }

  enquirySetApi({String? pId}) async {
    try {
      Map map = {
        "uid": getData.read("UserLogin")["id"].toString(),
        "prop_id": pId,
      };
      print(map.toString());
      Uri uri = Uri.parse(Config.path + Config.enquiry);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      print("---------------" + response.body);
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        print("+++++++++++++++" + result.toString());
        enquiry = result["Result"];
        showToastMessage(result["ResponseMsg"].toString());
        update();
      }
      update();
    } catch (e) {
      print(e.toString());
    }
  }
}
