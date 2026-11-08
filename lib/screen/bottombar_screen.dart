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
    tabController.addListener(_syncSelectedTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleFCMNavigation();
    });
  }

  void _syncSelectedTab() {
    if (mounted && _currentIndex != tabController.index) {
      setState(() => _currentIndex = tabController.index);
    }
  }

  @override
  void dispose() {
    tabController.removeListener(_syncSelectedTab);
    tabController.dispose();
    super.dispose();
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

  double _tabShift(int index, bool hasCreate, double navWidth) {
    if (!hasCreate) return 0;
    return switch (index) {
      0 => -navWidth * 0.025,
      1 => -navWidth * 0.075,
      2 => navWidth * 0.075,
      _ => navWidth * 0.025,
    };
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
            children: [
              myChilders[0],
              MapScreen(active: _currentIndex == 1),
              ReelsFeedScreen(active: _currentIndex == 2),
              myChilders[1],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 16),
              child: PhysicalShape(
                clipper: _CenterConvexNavClipper(
                  bumpHeight: homePageController.addProp == "Yes" ? 7 : 0,
                ),
                color: notifire.getbgcolor,
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                child: SizedBox(
                  height: homePageController.addProp == "Yes" ? 79 : 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        top: homePageController.addProp == "Yes" ? 7 : 0,
                        child: TabBar(
                          onTap: (index) async {
                            setState(() {});

                            if (isLogin != null || index <= 2) {
                              _currentIndex = index;
                              if (index == 1) {
                                LocationPermission permission;
                                permission = await Geolocator.checkPermission();
                                permission =
                                    await Geolocator.requestPermission();
                                if (permission == LocationPermission.denied) {
                                  lat = 0.0;
                                  long = 0.0;
                                }
                              }
                            } else {
                              Get.to(() => LoginScreen());
                            }
                          },
                          indicator: UnderlineTabIndicator(
                            insets: EdgeInsets.only(bottom: 52),
                            borderSide: BorderSide(
                                color: notifire.getbgcolor, width: 2),
                          ),
                          labelColor: Colors.blueAccent,
                          indicatorSize: TabBarIndicatorSize.label,
                          unselectedLabelColor: Colors.grey,
                          controller: tabController,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          tabs: [
                            Tab(
                              child: Transform.translate(
                                offset: Offset(
                                  _tabShift(
                                      0,
                                      homePageController.addProp == "Yes",
                                      MediaQuery.sizeOf(context).width - 32),
                                  0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Icon(
                                          _currentIndex == 0
                                              ? Icons.house_rounded
                                              : Icons.house_outlined,
                                          size: 24,
                                          color: _currentIndex == 0
                                              ? Darkblue
                                              : notifire.getwhiteblackcolor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    SizedBox(
                                      height: 18,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Home".tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: FontFamily.gilroyMedium,
                                            color: _currentIndex == 0
                                                ? Darkblue
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Tab(
                              child: Transform.translate(
                                offset: Offset(
                                  _tabShift(
                                      1,
                                      homePageController.addProp == "Yes",
                                      MediaQuery.sizeOf(context).width - 32),
                                  0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Icon(
                                          _currentIndex == 1
                                              ? Icons.explore_rounded
                                              : Icons.explore_outlined,
                                          size: 24,
                                          color: _currentIndex == 1
                                              ? Darkblue
                                              : notifire.getwhiteblackcolor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    SizedBox(
                                      height: 18,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Nearby".tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: FontFamily.gilroyMedium,
                                            color: _currentIndex == 1
                                                ? Darkblue
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Tab(
                              child: Transform.translate(
                                offset: Offset(
                                  _tabShift(
                                      2,
                                      homePageController.addProp == "Yes",
                                      MediaQuery.sizeOf(context).width - 32),
                                  0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Icon(
                                          _currentIndex == 2
                                              ? Icons.smart_display_rounded
                                              : Icons.smart_display_outlined,
                                          size: 24,
                                          color: _currentIndex == 2
                                              ? Darkblue
                                              : notifire.getwhiteblackcolor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    SizedBox(
                                      height: 18,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Reels".tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: FontFamily.gilroyMedium,
                                            color: _currentIndex == 2
                                                ? Darkblue
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Tab(
                              child: Transform.translate(
                                offset: Offset(
                                  _tabShift(
                                      3,
                                      homePageController.addProp == "Yes",
                                      MediaQuery.sizeOf(context).width - 32),
                                  0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Icon(
                                          _currentIndex == 3
                                              ? Icons.account_circle_rounded
                                              : Icons.account_circle_outlined,
                                          size: 24,
                                          color: _currentIndex == 3
                                              ? Darkblue
                                              : notifire.getwhiteblackcolor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    SizedBox(
                                      height: 18,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Profile".tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: FontFamily.gilroyMedium,
                                            color: _currentIndex == 3
                                                ? Darkblue
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (homePageController.addProp == "Yes")
                        Positioned(
                          top: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Material(
                              color: Darkblue,
                              elevation: 3,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: _openAddProperty,
                                customBorder: const CircleBorder(),
                                child: const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
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

class _CenterConvexNavClipper extends CustomClipper<Path> {
  const _CenterConvexNavClipper({required this.bumpHeight});

  final double bumpHeight;

  @override
  Path getClip(Size size) {
    const radius = 40.0;
    final center = size.width / 2;
    final shoulder = (size.width * 0.105).clamp(34.0, 38.0);
    final top = bumpHeight;
    final path = Path()..moveTo(radius, top);

    if (bumpHeight > 0) {
      path
        ..lineTo(center - shoulder, top)
        ..cubicTo(center - shoulder * .86, top, center - shoulder * .72,
            top * .74, center - shoulder * .52, top * .38)
        ..cubicTo(center - shoulder * .32, top * .02, center - shoulder * .18,
            0, center, 0)
        ..cubicTo(center + shoulder * .18, 0, center + shoulder * .32,
            top * .02, center + shoulder * .52, top * .38)
        ..cubicTo(center + shoulder * .72, top * .74, center + shoulder * .86,
            top, center + shoulder, top);
    }

    path
      ..lineTo(size.width - radius, top)
      ..quadraticBezierTo(size.width, top, size.width, top + radius)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(
          size.width, size.height, size.width - radius, size.height)
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, top + radius)
      ..quadraticBezierTo(0, top, radius, top)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _CenterConvexNavClipper oldClipper) =>
      oldClipper.bumpHeight != bumpHeight;
}
