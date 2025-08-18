// ignore_for_file: prefer_const_constructors, prefer_typing_uninitialized_variables, sort_child_properties_last, prefer_const_literals_to_create_immutables, unnecessary_brace_in_string_interps, unnecessary_string_interpolations, unused_local_variable, no_leading_underscores_for_local_identifiers, avoid_print, prefer_interpolation_to_compose_strings, unrelated_type_equality_checks, use_build_context_synchronously
import 'dart:convert';
import 'dart:io';

import 'package:badges/badges.dart' as bg;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/controller/homepage_controller.dart';
import 'package:opendoors/controller/search_controller.dart';
import 'package:opendoors/controller/signup_controller.dart';
import 'package:opendoors/firebase/chat_screen.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/model/routes_helper.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_accesstoken.dart';

var lat;
var long;
var first;
var currency;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomePageController homePageController = Get.find();
  SignUpController signUpController = Get.find();
  bool isLoding = false;
  Position? currentLocation;
  String fevId = "";

  String userName = "";
  String? base64Image;

  String? networkimage;

  List facilities = [
    "assets/images/beds.svg",
    "assets/images/bath.svg",
    "assets/images/sqft.svg",
  ];

  @override
  void initState() {
    FirebaseMessaging.onMessageOpenedApp.listen((remoteMessage) {
      print("object");
      Get.to(ChatPage(
        proPic: remoteMessage.data["propic"],
        resiverUserId: remoteMessage.data["id"],
        resiverUseremail: remoteMessage.data["name"],
      ));
    });
    homePageController.getHomeDataApi(countryId: getData.read("countryId"));
    homePageController.getCatWiseData(countryId: getData.read("countryId"), cId: "0");
    getdarkmodepreviousstate();
    if (getData.read("UserLogin") != null) {
      isUserOnlie(getData.read("UserLogin")["id"], false);
    }

    lat == null || long == null ? getUserLocation() : getUserLocation1();
    super.initState();
    getData.read("UserLogin") != null
        ? setState(() {
            userName = getData.read("UserLogin")["name"] ?? "";
            networkimage = getData.read("UserLogin")["pro_pic"] ?? "";
            getData.read("UserLogin")["pro_pic"] != "null"
                ? setState(() {
                    networkimageconvert();
                  })
                : const SizedBox();
          })
        : null;

    FirebaseAccesstoken accesstoken = new FirebaseAccesstoken();
    accesstoken.getAccessToken();

  }

  networkimageconvert() {
    (() async {
      http.Response response =
          await http.get(Uri.parse(Config.imageUrl + networkimage.toString()));

      if (mounted) {
        print(response.bodyBytes);
        setState(() {
          base64Image = const Base64Encoder().convert(response.bodyBytes);
        });
      }
    })();
  }

  Future<Position> locateUser() async {
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }


  Future getUserLocation() async {
    setState(() {});

    var currentLocation = await locateUser();
    debugPrint('location: ${currentLocation.latitude}');
    lat = currentLocation.latitude;
    long = currentLocation.longitude;

    List<Placemark> addresses = await placemarkFromCoordinates(
        currentLocation.latitude, currentLocation.longitude);
    setState(() {
      if (getData.read("homeCall") == true) {
        setState(() {
          homePageController.getHomeDataApi(
            countryId: getData.read("countryId"),
          );
        });
        save("homeCall", false);
      }
      first = addresses.first.name;
    });
  }

  Future getUserLocation1() async {
    isLoding = true;
    setState(() {});
    var currentLocation = await locateUser();
    debugPrint('location: ${currentLocation.latitude}');
  }

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
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    return WillPopScope(
      onWillPop: () => exit(0),
      child: Scaffold(
        backgroundColor: notifire.getbgcolor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: AppBar(
            toolbarHeight: 100,
            automaticallyImplyLeading: false,
            backgroundColor: notifire.getbgcolor,
            elevation: 0,
            title: Row(
              children: [
                getData.read("UserLogin") != null && networkimage != ""
                    ? InkWell(
                        onTap: () {},
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(
                                  "${Config.imageUrl}${networkimage ?? ""}"),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: () {},
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(
                                  "assets/images/profile-default.png"),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello Welcome 👋".tr,
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontFamily: FontFamily.gilroyMedium,
                        fontSize: 14,
                      ),
                    ),
                    userName != ""
                        ? Text(
                            userName,
                            style: TextStyle(
                              color: notifire.getwhiteblackcolor,
                              fontFamily: FontFamily.gilroyBold,
                              fontSize: 18,
                            ),
                          )
                        : Text(
                            "User".tr,
                            style: TextStyle(
                              color: notifire.getwhiteblackcolor,
                              fontFamily: FontFamily.gilroyBold,
                              fontSize: 18,
                            ),
                          ),
                  ],
                )
              ],
            ),
            actions: [
              InkWell(
                onTap: () {
                  if (getData.read("UserLogin") != null) {
                    Get.toNamed(Routes.notificationScreen);
                  } else {
                    Get.toNamed(Routes.login);
                  }
                },
                child: Center(
                  child: bg.Badge(
                    badgeStyle: bg.BadgeStyle(
                      badgeColor: Colors.red,
                      shape: bg.BadgeShape.circle,
                    ),
                    badgeContent: Text(''),
                    badgeAnimation: bg.BadgeAnimation.slide(),
                    position: bg.BadgePosition.topEnd(end: 14, top: 3),
                    child: CircleAvatar(
                      radius: 24,
                      child: Container(
                        height: 50,
                        width: 50,
                        alignment: Alignment.center,
                        child: Image.asset(
                          "assets/images/Notification.png",
                          height: 25,
                          width: 25,
                          color: notifire.getwhiteblackcolor,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                      ),
                      backgroundColor: notifire.getblackwhitecolor,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 10,
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
        color: Darkblue,
          onRefresh: () {
            return Future.delayed(
              Duration(seconds: 2),
              () {
                homePageController.getHomeDataApi(
                  countryId: getData.read("countryId"),
                );
                homePageController.getCatWiseData(
                  cId: "0",
                  countryId: getData.read("countryId"),
                );
              },
            );
          },
          child: GetBuilder<HomePageController>(
              builder: (homePageController) {
            return SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: homePageController.isLoading
                  ? Column(
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        searchWidget(),
                        SizedBox(
                          height: 20,
                        ),
                        categoryAndSeeAllWidget("Featured".tr, "See All".tr),
                        listFeatured(),
                        categoryAndSeeAllWidget("Our Recommendation".tr, "See All".tr),
                        SizedBox(
                          height: 55,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: ListView.builder(
                              itemCount: homePageController
                                  .homeDatatInfo!.homeData!.catlist!.length,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () {
                                    homePageController.changeCategoryIndex(index);

                                    homePageController.getCatWiseData(
                                      cId: homePageController.homeDatatInfo!.homeData!.catlist![index].id,
                                      countryId: getData.read("countryId"),
                                    );
                                    print("IMEA ${Config.imageUrl}${homePageController.homeDatatInfo?.homeData!.catlist![index].img}");
                                  },
                                  child: Container(
                                    height: 50,
                                    padding: EdgeInsets.all(8),
                                    margin: EdgeInsets.only(
                                        left: 5, right: 5, top: 7, bottom: 7),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        FadeInImage.assetNetwork(
                                          height: 25,
                                          width: 25,
                                          fit: BoxFit.cover,
                                          imageErrorBuilder: (context, error, stackTrace) {
                                          return Center(child: Image.asset("assets/images/ezgif.com-crop.gif",fit: BoxFit.cover,height: Get.height,),);
                                          },
                                          image: "${Config.imageUrl}${homePageController.homeDatatInfo?.homeData!.catlist![index].img ?? ""}",
                                          placeholder:  "assets/images/ezgif.com-crop.gif",
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          homePageController
                                                  .homeDatatInfo
                                                  ?.homeData
                                                  !.catlist![index]
                                                  .title ??
                                              "",
                                          style: TextStyle(
                                            fontFamily: FontFamily.gilroyBold,
                                            color: homePageController
                                                        .catCurrentIndex ==
                                                    index
                                                ? WhiteColor
                                                : blueColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: blueColor, width: 2),
                                      borderRadius: BorderRadius.circular(25),
                                      color:
                                          homePageController.catCurrentIndex == index ? blueColor : notifire.getbgcolor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        homePageController.isCatWise
                            ? homePageController
                                    .catWiseInfo!.propertyCat!.isNotEmpty
                                ? Padding(
                                  padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                                  child: GridView.builder(
                                      itemCount: homePageController
                                          .catWiseInfo?.propertyCat!.length,
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisExtent: 250,
                                      ),
                                      itemBuilder: (context, index) {
                                            return InkWell(
                                              onTap: () async {
                                                homePageController.chnageObjectIndex(index);
                                                Get.toNamed(Routes.viewDataScreen, arguments: {
                                                  "id" : homePageController.catWiseInfo?.propertyCat![index].id
                                                });
                                                setState(() {
                                                  homePageController.rate = homePageController.catWiseInfo?.propertyCat![index].rate ?? "";
                                                });
                                              },
                                              child: Container(
                                                height: 250,
                                                margin: EdgeInsets.all(8),
                                                child: Column(
                                                  children: [
                                                    Stack(
                                                      children: [
                                                        Container(
                                                          height: 140,
                                                          width: Get.size.width,
                                                          margin: EdgeInsets.only(right: 8,left: 8,top: 8,),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    15),
                                                            child: FadeInImage
                                                                .assetNetwork(
                                                              fadeInCurve:
                                                                  Curves.easeInCirc,
                                                              placeholder:
                                                                  "assets/images/ezgif.com-crop.gif",
                                                              height: 130,
                                                              width: Get.size.width,
                                                              imageErrorBuilder: (context, error, stackTrace) {
                                                              return Center(child: Image.asset("assets/images/emty.gif",fit: BoxFit.cover,height: Get.height,),);
                                                              },
                                                              image:
                                                                  "${Config.imageUrl}${homePageController.catWiseInfo?.propertyCat![index].image ?? ""}",
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                        ),
                                                        homePageController
                                                                    .catWiseInfo
                                                                    ?.propertyCat![
                                                                        index]
                                                                    .buyorrent ==
                                                                "1"
                                                            ? Positioned(
                                                                top: 15,
                                                                right: 20,
                                                                child: Container(
                                                                  height: 30,
                                                                  width: 45,
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Container(
                                                                        margin: const EdgeInsets
                                                                            .fromLTRB(
                                                                            0,
                                                                            0,
                                                                            3,
                                                                            0),
                                                                        child: Image
                                                                            .asset(
                                                                          "assets/images/Rating.png",
                                                                          height: 15,
                                                                          width: 15,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        "${homePageController.catWiseInfo?.propertyCat![index].rate ?? ""}",
                                                                        style:
                                                                            TextStyle(
                                                                          fontFamily:
                                                                              FontFamily
                                                                                  .gilroyMedium,
                                                                          color:
                                                                              blueColor,
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Color(
                                                                        0xFFedeeef),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                                15),
                                                                  ),
                                                                ),
                                                              )
                                                            : Positioned(
                                                                top: 15,
                                                                right: 20,
                                                                child: Container(
                                                                  height: 30,
                                                                  width: 60,
                                                                  alignment: Alignment
                                                                      .center,
                                                                  child: Text(
                                                                    "BUY".tr,
                                                                    style: TextStyle(
                                                                        color:
                                                                            blueColor,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w600),
                                                                  ),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Color(
                                                                        0xFFedeeef),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                                15),
                                                                  ),
                                                                ),
                                                              ),
                                                      ],
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        height: 128,
                                                        width: Get.size.width,
                                                        margin: EdgeInsets.all(5),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                              const EdgeInsets
                                                                  .only(left: 10),
                                                              child: Text(
                                                                homePageController
                                                                    .catWiseInfo
                                                                    ?.propertyCat![
                                                                index]
                                                                    .title ??
                                                                    "",
                                                                maxLines: 1,
                                                                style: TextStyle(
                                                                  fontSize: 17,
                                                                  fontFamily:
                                                                  FontFamily
                                                                      .gilroyBold,
                                                                  color: notifire
                                                                      .getwhiteblackcolor,
                                                                  overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 10,
                                                                  top: 6),
                                                              child: Row(
                                                                children: [
                                                                  SvgPicture.asset("assets/images/location.svg",height: 16, colorFilter: ColorFilter.mode(notifire.getwhiteblackcolor, BlendMode.srcIn),),
                                                                  SizedBox(width: 2,),
                                                                  Flexible(
                                                                    child: Text(
                                                                      homePageController
                                                                          .catWiseInfo
                                                                          ?.propertyCat![
                                                                      index]
                                                                          .city ??
                                                                          "",
                                                                      maxLines: 1,
                                                                      style: TextStyle(
                                                                        color: notifire
                                                                            .getgreycolor,
                                                                        fontFamily: FontFamily
                                                                            .gilroyMedium,
                                                                        overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                              const EdgeInsets
                                                                  .only(left: 10),
                                                              child: Row(
                                                                children: [
                                                                  Padding(
                                                                    padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: 7),
                                                                    child: Text(
                                                                      "${currency}${homePageController.catWiseInfo?.propertyCat![index].price ?? ""}",
                                                                      style:
                                                                      TextStyle(
                                                                        color: blueColor,
                                                                        fontFamily:
                                                                        FontFamily
                                                                            .gilroyBold,
                                                                        fontSize: 17,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  homePageController
                                                                      .catWiseInfo
                                                                      ?.propertyCat![
                                                                  index]
                                                                      .buyorrent ==
                                                                      "1"
                                                                      ? Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left: 3,
                                                                        top: 7),
                                                                    child: Text(
                                                                      "/night"
                                                                          .tr,
                                                                      style:
                                                                      TextStyle(
                                                                        color: notifire
                                                                            .getgreycolor,
                                                                        fontFamily:
                                                                        FontFamily.gilroyMedium,
                                                                      ),
                                                                    ),
                                                                  )
                                                                      : Text(""),
                                                                ],
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: notifire.getborderColor),
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  color: notifire.getbgcolor,
                                                ),
                                              ),
                                            );
                                      },
                                    ),
                                )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 5),
                                    child: Column(
                                      children: [
                                        SizedBox(height: Get.height * 0.10),
                                        Image(
                                          image: AssetImage(
                                            "assets/images/Door Icon.png",
                                          ),
                                          height: 110,
                                          width: 110,
                                        ),
                                        Center(
                                          child: SizedBox(
                                            width: Get.width * 0.80,
                                            child: Text(
                                              "Nothing here yet,\n but your next move could change that"
                                                  .tr,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: notifire.getgreycolor,
                                                fontFamily:
                                                    FontFamily.gilroyBold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                            : Center(
                                child: CircularProgressIndicator(color: Darkblue,),
                              )
                      ],
                    )
                  : SizedBox(
                      height: Get.height,
                      width: Get.width,
                      child: Center(
                        child: CircularProgressIndicator(color: Darkblue,),
                      ),
                    ),
            );
          }),
        ),
      ),
    );
  }

  Widget searchWidget() {
    SearchPropertyController searchController =
        Get.put(SearchPropertyController());
    return InkWell(
      onTap: () {
        searchController.search.text = "";
        Get.toNamed(Routes.homeSearchScreen);
      },
      child: Container(
        height: 50,
        width: Get.size.width,
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                "assets/images/SearchHomescreen.png",
                height: 22,
                width: 22,
                fit: BoxFit.cover,
                color: notifire.getlightblack,
              ),
            ),
            Text(
              "Search".tr,
              style: TextStyle(
                fontFamily: FontFamily.gilroyMedium,
                color: notifire.getlightblack,
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          color: notifire.getlightblackwhite,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget categoryAndSeeAllWidget(String name, String buttonName) {
    return Row(
          children: [
            SizedBox(
              width: 15,
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: 17,
                fontFamily: FontFamily.gilroyBold,
                color: notifire.getwhiteblackcolor,
              ),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                if (name == "Featured".tr) {
                  Get.toNamed(Routes.featuredScreen);
                }
                if (name == "Our Recommendation".tr) {
                    Get.toNamed(Routes.ourRecommendationScreen);
                    homePageController.getCatWiseData(cId: "0",countryId: getData.read("countryId"));
                }
              },
              child: Text(
                buttonName,
                style: TextStyle(
                  color: Darkblue,
                  fontFamily: FontFamily.gilroyBold,
                ),
              ),
            ),
            SizedBox(
              width: 10,
            ),
          ],
        );
  }

  Widget listFeatured() {
    return GetBuilder<HomePageController>(builder: (context) {
      return SizedBox(
        height: 320,
        width: Get.size.width,
        child: homePageController
                .homeDatatInfo!.homeData!.featuredProperty!.isNotEmpty
            ? ListView.builder(
                itemCount: homePageController
                    .homeDatatInfo?.homeData!.featuredProperty!.length,
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index1) {
                  currency = homePageController.homeDatatInfo?.homeData!.currency ?? "";
                  return InkWell(
                    onTap: () async {
                      setState(() {
                      Get.toNamed(
                        Routes.viewDataScreen,
                        arguments: {
                          "id" : homePageController.homeDatatInfo?.homeData!.featuredProperty![index1].id
                        }
                      );
                        homePageController.rate = homePageController.homeDatatInfo?.homeData!.featuredProperty![index1].rate ?? "";
                      });
                      print("IDDD ? >> >>> >>> >>> > ${homePageController.homeDatatInfo?.homeData!.featuredProperty![index1].id}");
                      homePageController.chnageObjectIndex(index1);
                    },
                    child: Container(
                      height: 320,
                      width: 240,
                      margin: EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Stack(
                          children: [
                            SizedBox(
                              height: 320,
                              width: 240,
                              child: FadeInImage.assetNetwork(
                                fadeInCurve: Curves.easeInCirc,
                                placeholder: "assets/images/ezgif.com-crop.gif",
                                height: 320,
                                width: 240,
                                placeholderCacheHeight: 320,
                                placeholderCacheWidth: 240,
                                placeholderFit: BoxFit.fill,
                                imageErrorBuilder: (context, error, stackTrace) {
                                return Center(child: Image.asset("assets/images/emty.gif",fit: BoxFit.cover,height: Get.height,),);
                                },
                                image:
                                    "${Config.imageUrl}${homePageController.homeDatatInfo?.homeData!.featuredProperty![index1].image ?? ""}",
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0.6, 0.8, 1.5],
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.5),
                                    Colors.black.withOpacity(0.5),
                                  ],
                                ),
                              ),
                            ),
                            homePageController.homeDatatInfo?.homeData!.featuredProperty![index1].buyorrent ==
                                    "1"
                                ? Positioned(
                                    top: 15,
                                    right: 20,
                                    child: Container(
                                      height: 30,
                                      width: 45,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.fromLTRB(
                                                0, 0, 3, 0),
                                            child: Image.asset(
                                              "assets/images/Rating.png",
                                              height: 15,
                                              width: 15,
                                            ),
                                          ),
                                          Text(
                                            "${homePageController.homeDatatInfo?.homeData!.featuredProperty![index1].rate ?? ""}",
                                            style: TextStyle(
                                              fontFamily:
                                                  FontFamily.gilroyMedium,
                                              color: blueColor,
                                            ),
                                          )
                                        ],
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFedeeef),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  )
                                : Positioned(
                                    top: 15,
                                    right: 20,
                                    child: Container(
                                      height: 30,
                                      width: 60,
                                      alignment: Alignment.center,
                                      child: Text(
                                        "BUY".tr,
                                        style: TextStyle(
                                            color: blueColor,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFedeeef),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                            Positioned(
                              bottom: 10,
                              child: SizedBox(
                                height: 130,
                                width: 240,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 12, top: 10),
                                      child: Text(
                                        homePageController
                                                .homeDatatInfo
                                                ?.homeData
                                                !.featuredProperty![index1]
                                                .title ??
                                            "",
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontFamily: FontFamily.gilroyBold,
                                          color: WhiteColor,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 9, top: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset("assets/images/location.svg",height: 15, colorFilter: ColorFilter.mode(WhiteColor, BlendMode.srcIn),),
                                          SizedBox(width: 2),
                                          Flexible(
                                            child: Text(
                                              homePageController
                                                      .homeDatatInfo
                                                      ?.homeData
                                                      !.featuredProperty![index1]
                                                      .city ??
                                                  "",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: FontFamily.gilroyMedium,
                                                color: WhiteColor,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 12, top: 11),
                                      child: SizedBox(
                                        height: 13,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: facilities.length,
                                          itemBuilder: (context, index) {
                                            return Row(
                                              children: [
                                                SvgPicture.asset(facilities[index],height: 12,),
                                                SizedBox(width: 5,),
                                                index == 0 ? Text("${homePageController.homeDatatInfo?.homeData!.featuredProperty![index1].beds} Beds", style: TextStyle(fontFamily: FontFamily.gilroyMedium, color: WhiteColor, overflow: TextOverflow.ellipsis,fontSize: 12),)
                                                    : index == 1 ? Text("${homePageController.homeDatatInfo?.homeData!.featuredProperty![index1].bathroom} Bath", style: TextStyle(fontFamily: FontFamily.gilroyMedium, color: WhiteColor, overflow: TextOverflow.ellipsis,fontSize: 12),)
                                                    : Text("${homePageController.homeDatatInfo?.homeData!.featuredProperty![index1].sqrft} Sqft", style: TextStyle(fontFamily: FontFamily.gilroyMedium, color: WhiteColor, overflow: TextOverflow.ellipsis,fontSize: 12),),
                                                   SizedBox(width: 8,),
                                              ],
                                            );
                                        },),
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 12, top: 10),
                                          child: Text(
                                            "${currency}${homePageController.homeDatatInfo?.homeData!.featuredProperty![index1].price}",
                                            style: TextStyle(
                                              color: WhiteColor,
                                              fontFamily: FontFamily.gilroyBold,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                        homePageController
                                                    .homeDatatInfo
                                                    ?.homeData
                                                    !.featuredProperty![index1]
                                                    .buyorrent ==
                                                "1"
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 5, top: 10),
                                                child: Text(
                                                  "/night".tr,
                                                  style: TextStyle(
                                                    color: WhiteColor,
                                                    fontFamily:
                                                        FontFamily.gilroyMedium,
                                                  ),
                                                ),
                                              )
                                            : Text(""),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  );
                },
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                child: Column(
                  children: [
                    SizedBox(height: Get.height * 0.10),
                    Image(
                      image: AssetImage(
                        "assets/images/Door Icon.png",
                      ),
                      height: 110,
                      width: 110,
                    ),
                    Center(
                      child: SizedBox(
                        width: Get.width * 0.80,
                        child: Text(
                          "Nothing here yet,\n but your next move could change that"
                              .tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: notifire.getgreycolor,
                            fontFamily: FontFamily.gilroyBold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );
    });
  }
}

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void listenFCM() async {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null && !kIsWeb) {
      flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
              presentBadge: true,
            ),
          ),
          payload: jsonEncode({
            "name": message.data["name"],
            "id": message.data["id"],
            "propic": message.data["propic"]
          }));
    }
  });
}

Future<void> initializeNotifications() async {
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsIos = DarwinInitializationSettings();


  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIos);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,

    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );
}

Future<void> onDidReceiveNotificationResponse(NotificationResponse response) async {
  // Handle the notification response. You can access the payload via response.payload.
  String? payload = response.payload;
  if(payload != null){
    Map data = jsonDecode(payload);
    Get.to(
        ChatPage(
          proPic: data["propic"],
          resiverUserId: data["id"],
          resiverUseremail: data["name"],
        ));
  }
  // Implement your logic based on the notification response here.
}

Future<void> onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  if(payload != null){
    Map data = jsonDecode(payload);
    Get.to(
        ChatPage(
          proPic: data["propic"],
          resiverUserId: data["id"],
          resiverUseremail: data["name"],
        ));
  }
}

void handleFCMNavigation() async {
  // Case: App terminated
  RemoteMessage? initialMessage =
  await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    navigateToChat(initialMessage);
  }

  // Case: App opened from background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    navigateToChat(message);
  });
}

void navigateToChat(RemoteMessage message) {
  final data = message.data;

  // Ensure required keys exist
  if (data.containsKey("id") && data.containsKey("name")) {
    Get.to(() => ChatPage(
      proPic: data["propic"],
      resiverUserId: data["id"],
      resiverUseremail: data["name"],
    ));
  }
}

void loadFCM() async {
  if (!kIsWeb) {
    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
      enableVibration: true,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);


    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}
