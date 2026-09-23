// ignore_for_file: prefer_const_constructors, unused_field, prefer_final_fields, prefer_typing_uninitialized_variables, sort_child_properties_last
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/controller/dashboard_controller.dart';
import 'package:opendoors/controller/homepage_controller.dart';
import 'package:opendoors/controller/listofproperti_controller.dart';
import 'package:opendoors/controller/selectcountry_controller.dart';
import 'package:opendoors/controller/wallet_controller.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/screen/add%20proparty/addintro_screen.dart';
import 'package:opendoors/screen/add%20proparty/membarship_screen.dart';
import 'package:opendoors/screen/home_screen.dart';
import 'package:opendoors/screen/login_screen.dart';
import 'package:opendoors/screen/near%20by%20map/map_screen.dart';
import 'package:opendoors/screen/profile_screen.dart';
import 'package:opendoors/screen/reels_feed_screen.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/Colors.dart';

class BottoBarScreen extends StatefulWidget {
  const BottoBarScreen({super.key});

  @override
  State<BottoBarScreen> createState() => _BottoBarScreenState();
}

late TabController tabController;

class _BottoBarScreenState extends State<BottoBarScreen>
    with TickerProviderStateMixin {
  WalletController walletController = Get.find();
  DashBoardController dashBoardController = Get.find();
  ListOfPropertiController listOfPropertiController = Get.find();
  SelectCountryController selectCountryController = Get.find();
  HomePageController homePageController = Get.find();

  int _currentIndex = 0;

  var isLogin;

  List<Widget> myChilders = [
    HomeScreen(),
    MapScreen(),
    ReelsFeedScreen(),
    ProfileScreen(),
  ];

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

    isLogin = getData.read("UserLogin");
    tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleFCMNavigation();
    });
  }

  DateTime? lastBackPressed;

  Future popScopeBack() async {
    DateTime now = DateTime.now();
    if (lastBackPressed == null ||
        now.difference(lastBackPressed!) > Duration(seconds: 2)) {
      lastBackPressed = now;
      showToastMessage("Press back again to exit");
      return false;
    }
    return true;
  }

  void _openAddProperty() {
    dashBoardController.getDashBoardData().then((value) {
      if (isLogin != null) {
        if (dashBoardController.dashBoardInfo?.isSubscribe == 1) {
          dashBoardController.getDashBoardData();
          listOfPropertiController.getPropertiList();
          selectCountryController.getCountryApi();
          Get.to(MembershipScreen());
        } else {
          selectCountryController.getCountryApi();
          Get.to(BoardingPage());
        }
      } else {
        Get.to(() => LoginScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    return WillPopScope(
      onWillPop: () async {
        return await popScopeBack();
      },
      child: GetBuilder<HomePageController>(builder: (homePageController) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          extendBody: true,
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: tabController,
            children: myChilders,
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 16),
              decoration: BoxDecoration(
                color: notifire.getbgcolor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BottomAppBar(
                  color: Colors.transparent,
                  elevation: 0,
                  height: 80,
                  padding: EdgeInsets.zero,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TabBar(
                        onTap: (index) async {
                          setState(() {});

                          if (isLogin != null) {
                            _currentIndex = index;
                            if (index == 1) {
                              LocationPermission permission;
                              permission = await Geolocator.checkPermission();
                              permission = await Geolocator.requestPermission();
                              if (permission == LocationPermission.denied) {
                                lat = 0.0;
                                long = 0.0;
                              }
                            }
                          } else {
                            if (index == 0) {
                              _currentIndex = index;
                            } else {
                              Get.to(() => LoginScreen());
                            }
                          }
                        },
                        indicator: UnderlineTabIndicator(
                          insets: EdgeInsets.only(bottom: 52),
                          borderSide:
                              BorderSide(color: notifire.getbgcolor, width: 2),
                        ),
                        labelColor: Colors.blueAccent,
                        indicatorSize: TabBarIndicatorSize.label,
                        unselectedLabelColor: Colors.grey,
                        controller: tabController,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        tabs: [
                          Tab(
                            child: Column(
                              children: [
                                Image.asset(
                                  "assets/images/${_currentIndex == 0 ? "HomeBold.png" : "Home.png"}",
                                  scale: 21,
                                  color: _currentIndex == 0
                                      ? Darkblue
                                      : notifire.getwhiteblackcolor,
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "Home".tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: FontFamily.gilroyMedium,
                                    color: _currentIndex == 0
                                        ? Darkblue
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 50,
                            width: 80,
                            margin: EdgeInsets.only(
                                left: homePageController.addProp == "Yes"
                                    ? 0
                                    : 9),
                            alignment: getData.read("lCode") == "ar_IN"
                                ? Alignment.topRight
                                : Alignment.topLeft,
                            child: Tab(
                              child: Column(
                                children: [
                                  Image.asset(
                                    "assets/images/${_currentIndex == 1 ? "mapbold.png" : "map.png"}",
                                    scale: 3.7,
                                    color: _currentIndex == 1
                                        ? Darkblue
                                        : notifire.getwhiteblackcolor,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Nearby".tr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: FontFamily.gilroyMedium,
                                      color: _currentIndex == 1
                                          ? Darkblue
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 50,
                            width: 80,
                            margin: EdgeInsets.only(
                                right: homePageController.addProp == "Yes"
                                    ? 0
                                    : 9),
                            alignment: getData.read("lCode") == "ar_IN"
                                ? Alignment.topLeft
                                : Alignment.topRight,
                            child: Tab(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 2,
                                  ),
                                  Icon(
                                    _currentIndex == 2
                                        ? Icons.video_collection
                                        : Icons.video_collection_outlined,
                                    size: 24,
                                    color: _currentIndex == 2
                                        ? Darkblue
                                        : notifire.getwhiteblackcolor,
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    "Reels".tr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: FontFamily.gilroyMedium,
                                      color: _currentIndex == 2
                                          ? Darkblue
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            child: Column(
                              children: [
                                Image.asset(
                                  "assets/images/${_currentIndex == 3 ? "userBold.png" : "userline.png"}",
                                  scale: 21,
                                  color: _currentIndex == 3
                                      ? Darkblue
                                      : notifire.getwhiteblackcolor,
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "Account".tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: FontFamily.gilroyMedium,
                                    color: _currentIndex == 3
                                        ? Darkblue
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (homePageController.addProp == "Yes")
                        Material(
                          color: Darkblue,
                          elevation: 3,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: _openAddProperty,
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 46,
                              height: 46,
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
