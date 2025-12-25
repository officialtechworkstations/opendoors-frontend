// ignore_for_file: prefer_const_constructors, prefer_interpolation_to_compose_strings, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, avoid_print

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/controller/homepage_controller.dart';
import 'package:opendoors/model/app_settings.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/screen/app_update_screen.dart';
import 'package:opendoors/screen/bottombar_screen.dart';
import 'package:opendoors/screen/login_screen.dart';
import 'package:opendoors/screen/onbording_screen.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:version/version.dart';
import 'add proparty/membarship_screen.dart';
import 'home_screen.dart';

class SpleshScreen extends StatefulWidget {
  const SpleshScreen({super.key});

  @override
  State<SpleshScreen> createState() => _SpleshScreenState();
}

class _SpleshScreenState extends State<SpleshScreen> {
  HomePageController homePageController = Get.find();
  late ColorNotifire notifire;

  getdarkmodepreviousstate() async {
    final prefs = await SharedPreferences.getInstance();
    bool? previusstate = prefs.getBool("setIsDark");
    if (previusstate == null) {
      notifire.setIsDark = false;
    } else {
      notifire.setIsDark = previusstate;
    }
  }

  @override
  void initState() {
    super.initState();

    currency = getData.read("currency");

    getData.remove("lCode");
    save("lanValue", 0);
    homePageController.getHomeDataApi(
      countryId: getData.read("countryId"),
    );
    homePageController.getChatNoApi().then((val) {
      appUpdateCheck();
    });

    // homePageController
    //     .getCatWiseData(
    //   cId: "0",
    //   countryId: getData.read("countryId"),
    // )
    //     .then(
    //   (value) {
    //     setScreen();
    //   },
    // );
  }

  setScreenInit() {
    homePageController
        .getCatWiseData(
      cId: "0",
      countryId: getData.read("countryId"),
    )
        .then(
      (value) {
        setScreen();
      },
    );
  }

  setScreen() async {
    final prefs = await SharedPreferences.getInstance();
    print("OPERN DOOORS ###");
    Timer(
        const Duration(seconds: 3),
        () => prefs.getBool('Firstuser') != true
            ? Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => OnBordingScreen()))
            : prefs.getBool('Remember') != true
                ? Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()))
                : getData.read("userType") == "admin"
                    ? Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MembershipScreen()))
                    : Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BottoBarScreen())));
  }

  appUpdateCheck() async {
    try {
      final AppSetting _appSetting = homePageController.appSetting;

      final String? latestAndroidVersion =
          _appSetting.providerCurrentVersionAndroidApp;
      final String? latestIOSVersion = _appSetting.providerCurrentVersionIosApp;

      // Get build numbers from your backend
      final String? latestAndroidBuildNumber =
          _appSetting.providerCurrentBuildNumberAndroidApp;
      final String? latestIOSBuildNumber =
          _appSetting.providerCurrentBuildNumberIosApp;

      final PackageInfo packageInfo = await PackageInfo.fromPlatform();

      final String currentApplicationVersion = packageInfo.version;
      final String currentBuildNumber = packageInfo.buildNumber;

      final Version currentVersion = Version.parse(currentApplicationVersion);
      final int currentBuild = int.parse(currentBuildNumber);

      if (Platform.isAndroid) {
        final Version latestVersionAndroid = Version.parse(
            latestAndroidVersion?.isEmpty ?? true
                ? "1.0.0"
                : latestAndroidVersion!);
        final int latestBuildAndroid = int.parse(
            latestAndroidBuildNumber?.isEmpty ?? true
                ? "1"
                : latestAndroidBuildNumber!);

        // Check if either version OR build number is higher
        if (latestVersionAndroid > currentVersion ||
            (latestVersionAndroid == currentVersion &&
                latestBuildAndroid > currentBuild)) {
          _showUpdateScreen(_appSetting);
          return;
        }
      } else if (Platform.isIOS) {
        final Version latestVersionIos = Version.parse(
            latestIOSVersion?.isEmpty ?? true ? "1.0.0" : latestIOSVersion!);
        final int latestBuildIos = int.parse(
            latestIOSBuildNumber?.isEmpty ?? true
                ? "1"
                : latestIOSBuildNumber!);

        if (latestVersionIos > currentVersion ||
            (latestVersionIos == currentVersion &&
                latestBuildIos > currentBuild)) {
          _showUpdateScreen(_appSetting);
          return;
        }
      }

      // No update available
      setScreenInit();
    } catch (e) {
      log('App update check error: $e');
      setScreenInit(); // Fail gracefully
    }
  }

  void _showUpdateScreen(AppSetting appSetting) {
    final bool isForceUpdate =
        appSetting.providerCompulsaryUpdateForceUpdate == '1';

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                AppUpdateScreen(isForceUpdate: isForceUpdate)));
  }

  @override
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    return Scaffold(
      backgroundColor: notifire.getbgcolor,
      body: SizedBox(
          width: double.infinity,
          child: Image.asset(
            "assets/OpenDoor Splash Screen 1A.png",
            fit: BoxFit.fitWidth,
          )),
    );
  }
}
// permissionRequest() async {
//   await getStorage();
//   await getphone();
// }
//
// Future getStorage() async{
//   await Permission.storage.request();
// }
//
// Future getphone() async {
//    await Permission.phone.request();
// }

Future getLocation() async {
  LocationPermission permission;
  permission = await Geolocator.checkPermission();
  permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied) {
    lat = 0.0;
    long = 0.0;
  } else {}
}
