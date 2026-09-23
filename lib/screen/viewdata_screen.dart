// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, sort_child_properties_last, use_key_in_widget_constructors, must_be_immutable, prefer_interpolation_to_compose_strings, unnecessary_brace_in_string_interps, unused_field, unused_element, avoid_print, unrelated_type_equality_checks, unnecessary_string_interpolations, avoid_unnecessary_containers, prefer_adjacent_string_concatenation
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/controller/bookrealestate_controller.dart';
import 'package:opendoors/controller/calendar_controller.dart';
import 'package:opendoors/controller/gallery_controller.dart';
import 'package:opendoors/controller/homepage_controller.dart';
import 'package:opendoors/controller/reviewsummary_controller.dart';
import 'package:opendoors/firebase/chat_screen.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/model/routes_helper.dart';
import 'package:opendoors/screen/home_screen.dart';
import 'package:opendoors/screen/login_screen.dart';
import 'package:opendoors/screen/reels_feed_screen.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:opendoors/utils/formaters.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:opendoors/utils/fast_spinner.dart';

class ViewDataScreen extends StatefulWidget {
  @override
  State<ViewDataScreen> createState() => _ViewDataScreenState();
}

class _ViewDataScreenState extends State<ViewDataScreen> {
  late ColorNotifire notifire;
  HomePageController homePageController = Get.find();
  ReviewSummaryController reviewSummaryController = Get.find();
  BookrealEstateController bookrealEstateController = Get.find();
  GalleryController galleryController = Get.find();
  CalendarController calendarController = Get.put(CalendarController());

  int selectIndex = 0;

  String? _mediaUrl(String? path) {
    final value = path?.trim();
    if (value == null || value.isEmpty || value == 'null') return null;
    return Uri.parse(Config.imageUrl).resolve(value).toString();
  }

  void _openImagePreview(int initialIndex) {
    final images = homePageController.propetydetailsInfo?.propetydetails?.image
            ?.map((image) => _mediaUrl(image.image))
            .whereType<String>()
            .toList() ??
        [];
    if (images.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => _PropertyImagePreview(
        images: images,
        initialIndex: initialIndex.clamp(0, images.length - 1),
      ),
    );
  }

  void _openReel() {
    final reel = homePageController.propetydetailsInfo?.reel;
    if (reel?.isReady != true) return;
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: ReelPlayerPage(reel: reel!, active: true),
      ),
    );
  }

  Widget _mediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      Material(
        color: const Color(0xCC141414),
        elevation: 4,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: FontFamily.gilroyBold,
                    )),
              ],
            ),
          ),
        ),
      );
  getdarkmodepreviousstate() async {
    final prefs = await SharedPreferences.getInstance();
    bool? previusstate = prefs.getBool("setIsDark");
    if (previusstate == null) {
      notifire.setIsDark = false;
    } else {
      notifire.setIsDark = previusstate;
    }
  }

  Future<void> isMeassageAvalable(String uid) async {
    if (uid.trim().isEmpty) return;
    final document =
        FirebaseFirestore.instance.collection('opendoors_users').doc(uid);

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final value = await document.get();
        if (!mounted) return;
        final fields = value.data();
        setState(() {
          useremail = fields?["name"]?.toString() ?? '';
          fmctoken = fields?["token"]?.toString() ?? '';
        });
        return;
      } on FirebaseException catch (error) {
        final retryable = error.code == 'unavailable' ||
            error.code == 'deadline-exceeded' ||
            error.code == 'resource-exhausted';
        if (!retryable || attempt == 2) return;
        await Future<void>.delayed(
          Duration(milliseconds: 300 * (1 << attempt)),
        );
      } catch (_) {
        return;
      }
    }
  }

  String latitude = "";
  String longitude = "";

  late GoogleMapController mapController;
  LatLng showLocation = LatLng(27.7089427, 85.3086209);

  final List<Marker> _markers = <Marker>[];

  Future<Uint8List> getImages(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  String useremail = '';
  String fmctoken = '';
  String selectedId = '';
  bool isBooked = false;

  @override
  void initState() {
    super.initState();
    if (Get.arguments is Map) {
      selectedId =
          (Get.arguments["id"] ?? Get.arguments["propertyId"])?.toString() ??
              "";
    } else if (Get.arguments != null) {
      selectedId = Get.arguments.toString();
    }
    setBookedStatus();
    homePageController
        .getPropertyDetailsApi(
      id: selectedId,
    )
        .then(
      (value) {
        loadData();
        isMeassageAvalable(
            "${homePageController.propetydetailsInfo!.propetydetails!.userId}");
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    homePageController.isProperty = false;
  }

  setBookedStatus() {
    if (Get.arguments is Map) {
      final bookedValue = Get.arguments['booked'];
      isBooked = bookedValue == true;
    }
    setState(() {});
  }

  loadData() async {
    final Uint8List markIcons =
        await getImages("assets/images/MapPin.png", 100);

    _markers.add(
      Marker(
        markerId: MarkerId(showLocation.toString()),
        icon: BitmapDescriptor.bytes(markIcons),
        position: LatLng(
          double.parse(
              homePageController.propetydetailsInfo?.propetydetails!.latitude ??
                  ""),
          double.parse(homePageController
                  .propetydetailsInfo!.propetydetails!.longtitude ??
              ""),
        ),
        infoWindow: InfoWindow(),
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    final isDark = notifire.isDark;
    return GetBuilder<HomePageController>(builder: (context) {
      return Scaffold(
        backgroundColor: notifire.getbgcolor,
        body: homePageController.isProperty
            ? NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 300,
                      floating: false,
                      pinned: true,
                      backgroundColor: notifire.getbgcolor,
                      leading: InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(17),
                          child: Image.asset(
                            "assets/images/Arrow - Left.png",
                            color: blueColor,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      actions: [
                        GetBuilder<HomePageController>(builder: (context) {
                          return InkWell(
                            onTap: () {
                              if (getData.read("UserLogin") != null) {
                                homePageController.addFavouriteList(
                                  pid: homePageController
                                      .propetydetailsInfo!.propetydetails!.id,
                                  propertyType: homePageController
                                      .propetydetailsInfo
                                      ?.propetydetails!
                                      .propertyType,
                                );
                              }
                            },
                            child: homePageController.propetydetailsInfo
                                        ?.propetydetails!.isFavourite ==
                                    1
                                ? Container(
                                    height: 50,
                                    width: 50,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.all(14),
                                    child: Image.asset(
                                      "assets/images/Fev-Bold.png",
                                      color: blueColor,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : Container(
                                    height: 50,
                                    width: 50,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.all(14),
                                    child: Image.asset(
                                      "assets/images/favorite.png",
                                      color: blueColor,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                          );
                        }),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          children: [
                            SizedBox(
                              height: 470,
                              child: PageView.builder(
                                itemCount: homePageController.propetydetailsInfo
                                    ?.propetydetails!.image!.length,
                                physics: BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _openImagePreview(index),
                                    child: FadeInImage.assetNetwork(
                                      fadeInCurve: Curves.easeInCirc,
                                      placeholder:
                                          "assets/images/ezgif.com-crop.gif",
                                      height: 470,
                                      width: Get.size.width,
                                      imageErrorBuilder:
                                          (context, error, stackTrace) {
                                        return Center(
                                          child: Image.asset(
                                            "assets/images/emty.gif",
                                            fit: BoxFit.cover,
                                            height: Get.height,
                                          ),
                                        );
                                      },
                                      image:
                                          "${Config.imageUrl}${homePageController.propetydetailsInfo?.propetydetails!.image![index].image ?? ""}",
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                                onPageChanged: (value) {
                                  setState(() {
                                    selectIndex = value;
                                  });
                                },
                              ),
                            ),
                            Positioned(
                              left: 16,
                              bottom: 34,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _mediaButton(
                                    icon: Icons.photo_library_outlined,
                                    label: 'View Image',
                                    onTap: () => _openImagePreview(selectIndex),
                                  ),
                                  if (homePageController
                                          .propetydetailsInfo?.reel?.isReady ==
                                      true) ...[
                                    const SizedBox(height: 8),
                                    _mediaButton(
                                      icon: Icons.play_circle_outline,
                                      label: 'View Reel',
                                      onTap: _openReel,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            homePageController.propetydetailsInfo!
                                        .propetydetails!.image!.length ==
                                    1
                                ? SizedBox()
                                : Positioned(
                                    bottom: 0,
                                    child: SizedBox(
                                      height: 25,
                                      width: Get.size.width,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ...List.generate(
                                              homePageController
                                                  .propetydetailsInfo!
                                                  .propetydetails!
                                                  .image!
                                                  .length, (index) {
                                            return IndicatorViewPage(
                                              isActive: selectIndex == index
                                                  ? true
                                                  : false,
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),
                            homePageController
                                        .propetydetailsInfo
                                        ?.propetydetails!
                                        .image![selectIndex]
                                        .isPanorama ==
                                    1
                                ? Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: InkWell(
                                      onTap: () {
                                        Get.toNamed(Routes.imageViewerSreen,
                                            arguments: {
                                              "img": homePageController
                                                  .propetydetailsInfo
                                                  ?.propetydetails!
                                                  .image![selectIndex]
                                                  .image,
                                            });
                                      },
                                      child: Container(
                                        height: 30,
                                        width: 70,
                                        padding: EdgeInsets.all(4),
                                        child: Image.asset(
                                            "assets/images/360.png"),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: BlackColor.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: Stack(
                  children: [
                    SizedBox(
                      height: Get.size.height,
                      width: Get.size.width,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 15, top: 10),
                              child: Text(
                                homePageController.propetydetailsInfo
                                        ?.propetydetails!.title ??
                                    "",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontFamily: FontFamily.gilroyBold,
                                  color: notifire.getwhiteblackcolor,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 15,
                                ),
                                Container(
                                  height: 25,
                                  padding: EdgeInsets.all(5),
                                  child: Text(
                                    homePageController.propetydetailsInfo
                                            ?.propetydetails!.propertyTitle ??
                                        "",
                                    style: TextStyle(
                                      fontFamily: FontFamily.gilroyMedium,
                                      fontSize: 12,
                                      color: blueColor,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFeef4ff),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Image.asset(
                                  "assets/images/Rating.png",
                                  height: 20,
                                  width: 20,
                                ),
                                SizedBox(
                                  width: 7,
                                ),
                                Text(
                                  "${homePageController.propetydetailsInfo?.propetydetails!.rate ?? ""}",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 15,
                                    fontFamily: FontFamily.gilroyMedium,
                                  ),
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      height: 40,
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        "assets/images/Frame1.png",
                                        height: 20,
                                        width: 20,
                                        color: blueColor,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFeef4ff),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      "${homePageController.propetydetailsInfo?.propetydetails!.beds ?? ""} ${"Beds".tr}",
                                      style: TextStyle(
                                        fontFamily: FontFamily.gilroyMedium,
                                        fontSize: 16,
                                        color: notifire.getwhiteblackcolor,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      height: 40,
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        "assets/images/bath.png",
                                        height: 20,
                                        width: 20,
                                        color: blueColor,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFeef4ff),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      "${homePageController.propetydetailsInfo?.propetydetails!.bathroom ?? ""} ${"Bath".tr}",
                                      style: TextStyle(
                                        fontFamily: FontFamily.gilroyMedium,
                                        fontSize: 16,
                                        color: notifire.getwhiteblackcolor,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      height: 40,
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        "assets/images/sqft.png",
                                        height: 20,
                                        width: 20,
                                        color: blueColor,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFeef4ff),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      "${homePageController.propetydetailsInfo?.propetydetails!.sqrft ?? ""} ${"sqft".tr}",
                                      style: TextStyle(
                                        fontFamily: FontFamily.gilroyMedium,
                                        fontSize: 16,
                                        color: notifire.getwhiteblackcolor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Wrap(
                                runSpacing: 10,
                                spacing: 4,
                                // crossAxisAlignment:
                                //     WrapCrossAlignment.,
                                children: [
                                  // SizedBox(
                                  //   width: 10,
                                  // ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 40,
                                          width: 40,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            homePageController
                                                        .propetydetailsInfo
                                                        ?.propetydetails!
                                                        .partyAllowed ==
                                                    "1"
                                                ? Icons.celebration_outlined
                                                : Icons.block,

                                            // "assets/images/Frame1.png",
                                            // height: 20,
                                            // width: 20,
                                            size: 20,
                                            color: blueColor,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFeef4ff),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        // CONTINUE EDIT FROM HERE;
                                        Text(
                                          "${homePageController.propetydetailsInfo?.propetydetails!.partyAllowed == "1" ? 'Party Allowed' : "Party Not Allowed"}",
                                          style: TextStyle(
                                            fontFamily: FontFamily.gilroyMedium,
                                            fontSize: 16,
                                            color: notifire.getwhiteblackcolor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (homePageController.propetydetailsInfo
                                          ?.propetydetails!.partyAllowed ==
                                      "1")
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 40,
                                            width: 40,
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.wallet,
                                              size: 20,
                                              color: blueColor,
                                            ),
                                            // child: Image.asset(
                                            //   "assets/images/bath.png",
                                            //   height: 20,
                                            //   width: 20,
                                            //   color: blueColor,
                                            // ),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFeef4ff),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                  text:
                                                      "N${AppFormater.formatAmount(double.parse(homePageController.propetydetailsInfo?.propetydetails!.partyCost ?? "0"))}",
                                                  style: TextStyle(
                                                    fontFamily:
                                                        FontFamily.gilroyMedium,
                                                    fontSize: 16,
                                                    color: notifire
                                                        .getwhiteblackcolor,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: " party charges",
                                                      style: TextStyle(
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontFamily: FontFamily
                                                            .gilroyMedium,
                                                        fontSize: 14,
                                                        color: isDark
                                                            ? Colors.grey
                                                            : Colors.black54,
                                                      ),
                                                    )
                                                  ]),

                                              // child: Text(
                                              //   "N${AppFormater.formatAmount(double.parse(homePageController.propetydetailsInfo?.propetydetails!.partyCost ?? "0"))} party charges",
                                              //   style: TextStyle(
                                              //     fontFamily:
                                              //         FontFamily.gilroyMedium,
                                              //     fontSize: 16,
                                              //     color:
                                              //         notifire.getwhiteblackcolor,
                                              //   ),
                                              // ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (homePageController.propetydetailsInfo
                                              ?.propetydetails!.cautionFee !=
                                          null &&
                                      homePageController.propetydetailsInfo
                                              ?.propetydetails!.cautionFee !=
                                          '0.00')
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 40,
                                            width: 40,
                                            alignment: Alignment.center,
                                            child: Text('₦',
                                                style: TextStyle(
                                                    fontFamily: 'Roboto',
                                                    fontSize: 20,
                                                    color: blueColor,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            //  Icon(
                                            //   Icons.attach_money_sharp,
                                            //   size: 20,
                                            //   color: blueColor,
                                            // ),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFeef4ff),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                  text:
                                                      "N${AppFormater.formatAmount(double.parse(homePageController.propetydetailsInfo?.propetydetails!.cautionFee ?? "0"))}",
                                                  style: TextStyle(
                                                    fontFamily:
                                                        FontFamily.gilroyMedium,
                                                    fontSize: 16,
                                                    color: notifire
                                                        .getwhiteblackcolor,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          " caution fee payable on arrival",
                                                      style: TextStyle(
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontFamily: FontFamily
                                                            .gilroyMedium,
                                                        fontSize: 14,
                                                        color: isDark
                                                            ? Colors.grey
                                                            : Colors.black54,
                                                      ),
                                                    )
                                                  ]),
                                              // child: Text(
                                              //   "N${AppFormater.formatAmount(double.parse(homePageController.propetydetailsInfo?.propetydetails!.cautionFee ?? "0"))} Caution Fee payable on arrival",
                                              //   maxLines: 1,
                                              //   overflow: TextOverflow.ellipsis,
                                              //   style: TextStyle(
                                              //     fontFamily:
                                              //         FontFamily.gilroyMedium,
                                              //     fontSize: 16,
                                              //     color:
                                              //         notifire.getwhiteblackcolor,
                                              //   ),
                                              // ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            if (homePageController
                                        .propetydetailsInfo?.facility !=
                                    null &&
                                homePageController.propetydetailsInfo!.facility!
                                    .isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Divider(),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 15, top: 10),
                                child: Text(
                                  "Facilities",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontFamily: FontFamily.gilroyBold,
                                    color: notifire.getwhiteblackcolor,
                                  ),
                                ),
                              ),
                            ],

                            // SizedBox(
                            //   height: 10,
                            // ),
                            // homePageController.propetydetailsInfo?.facility.
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Row(
                                  // spacing: 8,
                                  // runSpacing: 8,
                                  children: homePageController
                                              .propetydetailsInfo?.facility ==
                                          null
                                      ? []
                                      : homePageController
                                          .propetydetailsInfo!.facility!
                                          .map((amenity) => Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: FilterChip(
                                                    onSelected: (value) {},
                                                    label: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          child: FadeInImage
                                                              .assetNetwork(
                                                            height: 20,
                                                            width: 20,
                                                            fit: BoxFit.cover,
                                                            imageErrorBuilder:
                                                                (context, error,
                                                                    stackTrace) {
                                                              return Center(
                                                                child:
                                                                    Image.asset(
                                                                  "assets/images/ezgif.com-crop.gif",
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  height: Get
                                                                      .height,
                                                                ),
                                                              );
                                                            },
                                                            image:
                                                                "${Config.imageUrl}${amenity.img ?? ""}",
                                                            placeholder:
                                                                "assets/images/ezgif.com-crop.gif",
                                                          ),
                                                        ),
                                                        // Icon(
                                                        //   amenity.icon,
                                                        //   size: 16,
                                                        //   color:
                                                        //       Colors.white,
                                                        // ),
                                                        const SizedBox(
                                                            width: 6),
                                                        Text(amenity.title ??
                                                            ''),
                                                      ],
                                                    ),
                                                    checkmarkColor:
                                                        Colors.white,
                                                    backgroundColor: Color(
                                                        0xFFeef4ff) // Colors.grey.shade300,
                                                    ),
                                              ))
                                          .toList(),
                                ),
                              ),
                            ),

                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15, top: 10),
                              child: Text(
                                "Hosted by".tr,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontFamily: FontFamily.gilroyBold,
                                  color: notifire.getwhiteblackcolor,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            ListTile(
                              leading: Builder(builder: (context) {
                                final avatarUrl = _mediaUrl(homePageController
                                    .propetydetailsInfo
                                    ?.propetydetails
                                    ?.ownerImage);
                                final fallback = Image.asset(
                                  'assets/images/profile-default.png',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                );
                                return ClipOval(
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: avatarUrl == null
                                        ? fallback
                                        : Image.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                fallback,
                                          ),
                                  ),
                                );
                              }),
                              title: Text(
                                homePageController.propetydetailsInfo
                                        ?.propetydetails!.ownerName ??
                                    "",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontFamily: FontFamily.gilroyBold,
                                  color: notifire.getwhiteblackcolor,
                                ),
                              ),
                              subtitle: Text(
                                "Partner".tr,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: FontFamily.gilroyMedium,
                                ),
                              ),
                              trailing: SizedBox(
                                width: 100,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Spacer(),
                                    InkWell(
                                      onTap: !isBooked
                                          ? () => _showErrorSnackbar(
                                              "Phone number will be available after booking")
                                          : () async {
                                              final mobile = homePageController
                                                  .propetydetailsInfo
                                                  ?.propetydetails!
                                                  .mobile;
                                              if (mobile == null ||
                                                  mobile.isEmpty ||
                                                  mobile.contains('*')) {
                                                _showErrorSnackbar(
                                                    "Phone number is not available");
                                                return;
                                              }
                                              await Permission.phone.request();
                                              print("F FS D FDSF 00");
                                              if (getData.read("UserLogin") !=
                                                  null) {
                                                var url = Uri(
                                                    scheme: 'tel',
                                                    path: mobile);
                                                print("Phone: $mobile");
                                                print("Formatted URI: $url");
                                                print(
                                                    "Can launch: ${await canLaunchUrl(url)}");
                                                if (await canLaunchUrl(url)) {
                                                  await launchUrl(
                                                    url,
                                                    mode: LaunchMode
                                                        .externalApplication,
                                                  );
                                                } else {
                                                  throw 'Could not launch $url';
                                                }
                                              } else {
                                                showToastMessage(
                                                    "Please login and send enquery"
                                                        .tr);
                                                Get.to(() => LoginScreen());
                                              }
                                            },
                                      child: Image.asset(
                                        "assets/images/phone Icon.png",
                                        height: 25,
                                        width: 25,
                                        fit: BoxFit.cover,
                                        color:
                                            !isBooked ? Colors.grey : blueColor,
                                      ),
                                    ),
                                    // homePageController.propetydetailsInfo
                                    //             ?.propetydetails!.userId ==
                                    //         "0"
                                    //     ? SizedBox()
                                    SizedBox(
                                      width: 15,
                                    ),
                                    // homePageController.propetydetailsInfo
                                    //             ?.propetydetails!.userId ==
                                    //         "0"
                                    //     ? SizedBox()
                                    InkWell(
                                      onTap: () {
                                        if (getData.read("UserLogin") != null) {
                                          _showPropertyInquirySheet();
                                        } else {
                                          showToastMessage(
                                              "Please login and send enquery"
                                                  .tr);
                                          Get.to(() => LoginScreen());
                                        }
                                      },
                                      child: Image.asset(
                                        "assets/images/Chat.png",
                                        height: 28,
                                        width: 28,
                                        fit: BoxFit.cover,
                                        color: blueColor,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 15,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15, top: 10),
                              child: Text(
                                "About this space".tr,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontFamily: FontFamily.gilroyBold,
                                  color: notifire.getwhiteblackcolor,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15, top: 10),
                              child: ReadMoreText(
                                homePageController.propetydetailsInfo
                                        ?.propetydetails!.description ??
                                    "",
                                trimLines: 4,
                                colorClickableText: blueColor,
                                trimMode: TrimMode.Line,
                                trimCollapsedText: 'Read more'.tr,
                                trimExpandedText: 'Show less'.tr,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: FontFamily.gilroyMedium,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15, top: 10),
                              child: Text(
                                "What this place offers".tr,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontFamily: FontFamily.gilroyBold,
                                  color: notifire.getwhiteblackcolor,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              itemCount: homePageController
                                  .propetydetailsInfo?.facility!.length,
                              physics: NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                              ),
                              itemBuilder: (context, index) {
                                return Column(
                                  children: [
                                    Container(
                                      height: 60,
                                      width: 60,
                                      alignment: Alignment.center,
                                      child: FadeInImage.assetNetwork(
                                        height: 25,
                                        width: 25,
                                        placeholder:
                                            "assets/images/loading2.gif",
                                        imageErrorBuilder:
                                            (context, error, stackTrace) {
                                          return Center(
                                            child: Image.asset(
                                              "assets/images/emty.gif",
                                              fit: BoxFit.cover,
                                              height: Get.height,
                                            ),
                                          );
                                        },
                                        image:
                                            "${Config.imageUrl}${homePageController.propetydetailsInfo!.facility![index].img}",
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFeef4ff),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      homePageController.propetydetailsInfo
                                              ?.facility![index].title ??
                                          "",
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: FontFamily.gilroyMedium,
                                        overflow: TextOverflow.ellipsis,
                                        color: notifire.getwhiteblackcolor,
                                      ),
                                    )
                                  ],
                                );
                              },
                            ),
                            homePageController
                                    .propetydetailsInfo!.gallery!.isNotEmpty
                                ? Column(
                                    children: [
                                      gallaryAndSeeAllWidget(
                                          "Gallary".tr, "See All".tr),
                                      Container(
                                        height: 110,
                                        alignment: Alignment.center,
                                        margin: EdgeInsets.only(left: 15),
                                        child: ListView.builder(
                                          itemCount: homePageController
                                              .propetydetailsInfo
                                              ?.gallery!
                                              .length,
                                          scrollDirection: Axis.horizontal,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              height: 110,
                                              width: 110,
                                              margin: EdgeInsets.all(5),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: FadeInImage.assetNetwork(
                                                  fadeInCurve:
                                                      Curves.easeInCirc,
                                                  placeholder:
                                                      "assets/images/ezgif.com-crop.gif",
                                                  height: 110,
                                                  imageErrorBuilder: (context,
                                                      error, stackTrace) {
                                                    return Center(
                                                      child: Image.asset(
                                                        "assets/images/emty.gif",
                                                        fit: BoxFit.cover,
                                                        height: Get.height,
                                                      ),
                                                    );
                                                  },
                                                  image:
                                                      "${Config.imageUrl}${homePageController.propetydetailsInfo?.gallery![index]}",
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color:
                                                    notifire.getblackwhitecolor,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                : SizedBox(),
                            Padding(
                              padding: const EdgeInsets.only(left: 15, top: 10),
                              child: Text(
                                "Location".tr,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontFamily: FontFamily.gilroyBold,
                                  color: notifire.getwhiteblackcolor,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 15,
                                ),
                                Image.asset(
                                  "assets/images/Location.png",
                                  height: 25,
                                  width: 25,
                                  fit: BoxFit.cover,
                                  color: Darkblue,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  homePageController.propetydetailsInfo
                                          ?.propetydetails!.city ??
                                      "",
                                  style: TextStyle(
                                    fontFamily: FontFamily.gilroyMedium,
                                    color: notifire.getgreycolor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 200,
                              width: Get.size.width,
                              margin: EdgeInsets.all(10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                      double.parse(homePageController
                                              .propetydetailsInfo
                                              ?.propetydetails!
                                              .latitude ??
                                          ""),
                                      double.parse(homePageController
                                              .propetydetailsInfo
                                              ?.propetydetails!
                                              .longtitude ??
                                          ""),
                                    ),
                                    zoom: 15.0,
                                  ),
                                  markers: Set<Marker>.of(_markers),
                                  mapType: MapType.normal,
                                  myLocationEnabled: true,
                                  compassEnabled: true,
                                  zoomGesturesEnabled: true,
                                  tiltGesturesEnabled: true,
                                  zoomControlsEnabled: true,
                                  onMapCreated: (controller) {
                                    setState(() {
                                      mapController = controller;
                                    });
                                  },
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: notifire.getblackwhitecolor,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    offset: const Offset(
                                      0.5,
                                      0.5,
                                    ),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            homePageController
                                    .propetydetailsInfo!.reviewlist!.isNotEmpty
                                ? reviewWidget(
                                    "${homePageController.propetydetailsInfo?.propetydetails!.rate ?? ""}(${homePageController.propetydetailsInfo?.totalReview} ${"reviews".tr})",
                                    "See All".tr,
                                    Icon(
                                      Icons.star,
                                      color: yelloColor,
                                    ),
                                  )
                                : SizedBox(),
                            homePageController
                                    .propetydetailsInfo!.reviewlist!.isNotEmpty
                                ? ListView.builder(
                                    itemCount: homePageController
                                        .propetydetailsInfo?.reviewlist!.length,
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return InkWell(
                                        onTap: () {},
                                        child: ListTile(
                                          leading: Container(
                                            height: 60,
                                            width: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  "${Config.imageUrl}${homePageController.propetydetailsInfo?.reviewlist![index].userImg ?? ""}",
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            "${homePageController.propetydetailsInfo?.reviewlist![index].userTitle ?? ""}",
                                            style: TextStyle(
                                              color:
                                                  notifire.getwhiteblackcolor,
                                              fontFamily: FontFamily.gilroyBold,
                                              fontSize: 17,
                                            ),
                                          ),
                                          subtitle: Text(
                                            "${homePageController.propetydetailsInfo?.reviewlist![index].userDesc ?? ""}",
                                            textAlign: TextAlign.start,
                                            maxLines: 2,
                                            style: TextStyle(
                                              color: notifire.getgreycolor,
                                              fontFamily:
                                                  FontFamily.gilroyMedium,
                                            ),
                                          ),
                                          trailing: Container(
                                            height: 40,
                                            width: 70,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.star,
                                                  color: blueColor,
                                                ),
                                                SizedBox(
                                                  width: 5,
                                                ),
                                                Text(
                                                  "${homePageController.propetydetailsInfo?.reviewlist![index].userRate ?? ""}",
                                                  style: TextStyle(
                                                    fontFamily:
                                                        FontFamily.gilroyBold,
                                                    color: blueColor,
                                                  ),
                                                )
                                              ],
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: blueColor,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : SizedBox(),
                            SizedBox(
                              height: 100,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        height: 78,
                        width: Get.size.width,
                        decoration: BoxDecoration(
                          color: notifire.getblackwhitecolor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 14,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 16, right: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      homePageController.propetydetailsInfo
                                                  ?.propetydetails?.buyorrent ==
                                              "1"
                                          ? '${"Price".tr} / ${"night".tr}'
                                          : "Price".tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: FontFamily.gilroyMedium,
                                        color: greycolor,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '$currency ${AppFormater.formatAmount(double.tryParse(homePageController.propetydetailsInfo?.propetydetails?.price ?? "0") ?? 0)}',
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Darkblue,
                                          fontFamily: FontFamily.gilroyBold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: Get.width * 0.34,
                              child: homePageController.propetydetailsInfo
                                          ?.propetydetails!.buyorrent ==
                                      "1"
                                  ? GestButton(
                                      height: 50,
                                      buttoncolor: Darkblue,
                                      margin: EdgeInsets.only(right: 16),
                                      buttontext: "Reserve".tr,
                                      // buttontext: "Book".tr,
                                      onclick: () {
                                        if (getData.read("UserLogin") != null) {
                                          bookrealEstateController.cleanDate();
                                          Get.toNamed(Routes.bookRealEstate);
                                          print(
                                              ">:>:>:>:>:>:>:>:>:> PROPERTY ID : > ${homePageController.propetydetailsInfo?.propetydetails!.id}");
                                          calendarController
                                              .calendar(homePageController
                                                  .propetydetailsInfo!
                                                  .propetydetails!
                                                  .id)
                                              .then(
                                                (value) {},
                                              );
                                          reviewSummaryController
                                              .getProductObject(
                                            pim: homePageController
                                                .propetydetailsInfo
                                                ?.propetydetails!
                                                .image![0]
                                                .image,
                                            pti: homePageController
                                                    .propetydetailsInfo
                                                    ?.propetydetails!
                                                    .title ??
                                                "",
                                            pci: homePageController
                                                    .propetydetailsInfo
                                                    ?.propetydetails!
                                                    .city ??
                                                "",
                                            pPr: homePageController
                                                .propetydetailsInfo
                                                ?.propetydetails!
                                                .price,
                                            pId: homePageController
                                                    .propetydetailsInfo
                                                    ?.propetydetails!
                                                    .id ??
                                                "",
                                            pLimit: homePageController
                                                    .propetydetailsInfo
                                                    ?.propetydetails!
                                                    .plimit ??
                                                "1",
                                          );
                                        } else {
                                          showToastMessage(
                                              "Please login and Book".tr);

                                          Get.to(() => LoginScreen());
                                        }
                                      },
                                      style: TextStyle(
                                        fontFamily: FontFamily.gilroyBold,
                                        color: WhiteColor,
                                        fontSize: 16,
                                      ),
                                    )
                                  : homePageController.propetydetailsInfo
                                              ?.propetydetails!.isEnquiry ==
                                          1
                                      ? GestButton(
                                          height: 50,
                                          buttoncolor: RedColor,
                                          margin: EdgeInsets.only(right: 16),
                                          buttontext: "Contacted".tr,
                                          onclick: () {
                                            Fluttertoast.showToast(
                                              msg: "Enquiry Already Send!!".tr,
                                              gravity: ToastGravity.BOTTOM,
                                              timeInSecForIosWeb: 1,
                                              backgroundColor: RedColor,
                                              textColor: Colors.white,
                                              fontSize: 14.0,
                                            );
                                          },
                                          style: TextStyle(
                                            fontFamily: FontFamily.gilroyBold,
                                            color: WhiteColor,
                                            fontSize: 16,
                                          ),
                                        )
                                      : GestButton(
                                          height: 50,
                                          buttoncolor: Darkblue,
                                          margin: EdgeInsets.only(right: 16),
                                          buttontext: "Inquiry".tr,
                                          onclick: () {
                                            if (getData.read("UserLogin") !=
                                                null) {
                                              homePageController.enquirySetApi(
                                                pId: homePageController
                                                    .propetydetailsInfo
                                                    ?.propetydetails!
                                                    .id,
                                              );
                                              Get.back();
                                            } else {
                                              showToastMessage(
                                                  "Please login and send enquery"
                                                      .tr);
                                            }
                                          },
                                          style: TextStyle(
                                            fontFamily: FontFamily.gilroyBold,
                                            color: WhiteColor,
                                            fontSize: 16,
                                          ),
                                        ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: FastSpinner(
                  color: Darkblue,
                ),
              ),
      );
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ui.Color.fromARGB(255, 21, 12, 12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 10),
      ),
    );
  }

  Widget gallaryAndSeeAllWidget(String name, String buttonName) {
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
            galleryController.getGalleryData(
                pId: homePageController.propetydetailsInfo?.propetydetails!.id);
            Get.toNamed(Routes.galleryScreen);
          },
          child: Text(
            buttonName,
            style: TextStyle(
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

  Widget reviewWidget(String name, String buttonName, Icon icon) {
    return Row(
      children: [
        SizedBox(
          width: 15,
        ),
        icon,
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
            Get.toNamed(Routes.reviewScreen, arguments: {
              "list": homePageController.propetydetailsInfo?.reviewlist
            });
          },
          child: Text(
            buttonName,
            style: TextStyle(
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

  void _showPropertyInquirySheet() {
    final inquiryController = TextEditingController();
    final details = homePageController.propetydetailsInfo?.propetydetails;
    if (details == null) return;

    final propertyTitle = details.title?.toString() ?? '';
    final propertyAddress = details.address?.toString() ?? '';
    final propertyImageUrl =
        (details.image != null && details.image!.isNotEmpty)
            ? details.image![0].image?.toString()
            : null;
    final propertyId = details.id?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: notifire.getbgcolor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Property preview card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: notifire.getwhiteblackcolor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (propertyImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            propertyImageUrl.startsWith('http')
                                ? propertyImageUrl
                                : '${Config.imageUrl}$propertyImageUrl',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.home, color: Colors.grey),
                            ),
                          ),
                        ),
                      if (propertyImageUrl != null) SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              propertyTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: FontFamily.gilroyBold,
                                color: notifire.getwhiteblackcolor,
                              ),
                            ),
                            if (propertyAddress.isNotEmpty) ...[
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      propertyAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                        fontFamily: FontFamily.gilroyMedium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Inquiry text field with send button
                Text(
                  'Your Message'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: FontFamily.gilroyBold,
                    color: notifire.getwhiteblackcolor,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: inquiryController,
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontFamily: FontFamily.gilroyMedium,
                    color: notifire.getwhiteblackcolor,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Please provide me more details on this property. I am interested!'
                            .tr,
                    hintStyle: TextStyle(
                      fontFamily: FontFamily.gilroyMedium,
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: notifire.getwhiteblackcolor.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),

                SizedBox(height: 16),

                // Send button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      final customMessage = inquiryController.text.trim();
                      Get.to(ChatPage(
                        proPic: details.ownerImage.toString(),
                        resiverUseremail: useremail,
                        resiverUserId: details.userId ?? "0",
                        propertyImage: propertyImageUrl,
                        propertyTitle: propertyTitle,
                        propertyAddress: propertyAddress,
                        propertyId: propertyId,
                        propertyMessage:
                            customMessage.isNotEmpty ? customMessage : null,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Send Inquiry'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: FontFamily.gilroyBold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PropertyImagePreview extends StatefulWidget {
  const _PropertyImagePreview({
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<_PropertyImagePreview> createState() => _PropertyImagePreviewState();
}

class _PropertyImagePreviewState extends State<_PropertyImagePreview> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 60),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Stack(
            children: [
              PhotoViewGallery.builder(
                pageController: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                loadingBuilder: (_, __) =>
                    const Center(child: FastSpinner(color: Colors.white)),
                builder: (context, index) => PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(widget.images[index]),
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close image preview',
                ),
              ),
              if (widget.images.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

class IndicatorViewPage extends StatelessWidget {
  final bool isActive;
  const IndicatorViewPage({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        height: isActive ? 6 : 8,
        width: isActive ? 30 : 8,
        decoration: BoxDecoration(
          color: isActive ? Darkblue : Colors.grey,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
