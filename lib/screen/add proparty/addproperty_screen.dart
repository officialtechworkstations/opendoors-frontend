// ignore_for_file: prefer_const_constructors, sort_child_properties_last, prefer_const_literals_to_create_immutables, non_constant_identifier_names, unused_element, prefer_typing_uninitialized_variables, prefer_interpolation_to_compose_strings, avoid_print, deprecated_member_use, unused_field

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/controller/addproperties_controller.dart';
import 'package:opendoors/controller/dashboard_controller.dart';
import 'package:opendoors/controller/enquiry_controller.dart';
import 'package:opendoors/controller/selectcountry_controller.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:opendoors/utils/fast_spinner.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  static String format(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final beforeCursor = newValue.text.substring(
        0, newValue.selection.baseOffset.clamp(0, newValue.text.length));
    final digitCount = beforeCursor.replaceAll(RegExp(r'\D'), '').length;
    final formatted = format(newValue.text);
    var offset = 0;
    var seen = 0;
    while (offset < formatted.length && seen < digitCount) {
      if (RegExp(r'\d').hasMatch(formatted[offset])) seen++;
      offset++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

List<String> list = ["Rent"];

List<String> propartyStatus = ["Publish", "UnPublish"];

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _moneyFormatter = _ThousandsSeparatorFormatter();
  AddPropertiesController addPropertiesController = Get.find();
  DashBoardController dashBoardController = Get.find();
  EnquiryController enquriryController = Get.find();
  SelectCountryController selectCountryController = Get.find();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  VideoPlayerController? _reelPreviewController;

  String manegeRoute = Get.arguments["add"];

  String selectValue = list.first;
  String? selectProperty;
  String? selectCountry;
  String slectStatus = propartyStatus.first;

  bool carCheck = false;
  bool sportCheck = false;
  bool laundaryCheck = false;

  late ColorNotifire notifire;
  getdarkmodepreviousstate() async {
    final prefs = await SharedPreferences.getInstance();
    bool? previusstate = prefs.getBool("setIsDark");
    if (slectStatus == "Rent") {
      addPropertiesController.pbuySell = "1";
    }
    if (previusstate == null) {
      notifire.setIsDark = false;
    } else {
      notifire.setIsDark = previusstate;
    }
  }

  Future<Position> locateUser() async {
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  void initState() {
    super.initState();
    print(".....//.......//.....//" + manegeRoute);
    if (manegeRoute == "edit") {
      setState(() {
        addPropertiesController.emptyAllDetails();
        addPropertiesController.existingReelId =
            addPropertiesController.eReelId;
        addPropertiesController.pTitle.text = addPropertiesController.eTitle;
        addPropertiesController.pNumber.text = addPropertiesController.eNumber;
        addPropertiesController.pAddress.text =
            addPropertiesController.eAddress;
        addPropertiesController.pPrice.text =
            _ThousandsSeparatorFormatter.format(addPropertiesController.ePrice);
        addPropertiesController.pPartyCost.text =
            addPropertiesController.eparty_cost;
        addPropertiesController.pCaution.text =
            _ThousandsSeparatorFormatter.format(
                addPropertiesController.ecaution_fee);
        // addPropertiesController.

        addPropertiesController.propertyAddress.text =
            addPropertiesController.ePropertyAddress;
        addPropertiesController.totalBeds.text =
            addPropertiesController.eTotalBeds;
        addPropertiesController.totalBathroom.text =
            addPropertiesController.eTotalBathroom;
        addPropertiesController.pSqft.text = addPropertiesController.eSqft;
        addPropertiesController.pRating.text = addPropertiesController.eRating;
        addPropertiesController.pCityAndCountry.text =
            addPropertiesController.eCityAndCountry;
        addPropertiesController.lat = addPropertiesController.elat;
        addPropertiesController.long = addPropertiesController.elong;
        addPropertiesController.pImage = addPropertiesController.eImage;
        addPropertiesController.pGest.text = addPropertiesController.eGest;
        List list = addPropertiesController.fList.split(",");
        for (var i = 0; i < list.length; i++) {
          if (dashBoardController.facilityInfo?.facilitylist![i].title ==
              list[i]) {
            addPropertiesController.selectedIndexes
                .add(dashBoardController.facilityInfo!.facilitylist![i].id);
          }
        }
        selectProperty = addPropertiesController.pName;
        selectCountry = addPropertiesController.countryName;
        setState(() {});
      });
    } else {
      addPropertiesController.emptyAllDetails();
      addPropertiesController.selectedIndexes = [];
      addPropertiesController.pType = "";
      addPropertiesController.countryId = "1";
      selectProperty = null;
      selectCountry = null;
      setState(() {});
    }
    getdarkmodepreviousstate();
  }

  @override
  void dispose() {
    _reelPreviewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    return Scaffold(
      backgroundColor: notifire.getfevAndSearch,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(
            Icons.arrow_back,
            color: notifire.getwhiteblackcolor,
          ),
        ),
        backgroundColor: notifire.getblackwhitecolor,
        elevation: 0,
        title: Text(
          manegeRoute == "Add" ? "Add Property".tr : "Edit Property".tr,
          style: TextStyle(
            color: notifire.getwhiteblackcolor,
            fontFamily: FontFamily.gilroyBold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Obx(
                () => Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              "Property".tr,
                              style: TextStyle(
                                fontFamily: FontFamily.gilroyBold,
                                fontSize: 16,
                                color: notifire.getwhiteblackcolor,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Container(
                            height: 60,
                            width: Get.size.width,
                            alignment: Alignment.center,
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            padding: EdgeInsets.only(left: 15, right: 15),
                            child: DropdownButton(
                              dropdownColor: notifire.getbgcolor,
                              value: selectValue,
                              icon: Image.asset(
                                'assets/images/Arrow - Down.png',
                                height: 20,
                                width: 20,
                                color: notifire.getwhiteblackcolor,
                              ),
                              isExpanded: true,
                              underline: SizedBox.shrink(),
                              items: list.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      fontFamily: FontFamily.gilroyMedium,
                                      color: notifire.getwhiteblackcolor,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  if (value == "Buy") {
                                    addPropertiesController.pbuySell = "2";
                                  } else if (value == "Rent") {
                                    addPropertiesController.pbuySell = "1";
                                  }
                                  selectValue = value ?? "";
                                });
                              },
                            ),
                            decoration: BoxDecoration(
                              color: notifire.getblackwhitecolor,
                              borderRadius: BorderRadius.circular(15),
                              border:
                                  Border.all(color: notifire.getborderColor),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              "Select Country".tr,
                              style: TextStyle(
                                fontFamily: FontFamily.gilroyBold,
                                fontSize: 16,
                                color: notifire.getwhiteblackcolor,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          GetBuilder<AddPropertiesController>(
                              builder: (context) {
                            // log(selectCountryController.countryList.toString());
                            // log(selectCountry.toString());
                            return Container(
                              height: 60,
                              width: Get.size.width,
                              alignment: Alignment.center,
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              padding: EdgeInsets.only(left: 15, right: 15),
                              child: DropdownButton(
                                dropdownColor: notifire.getbgcolor,
                                hint: Text(
                                  "Select Country".tr,
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                value: selectCountry,
                                icon: Image.asset(
                                  'assets/images/Arrow - Down.png',
                                  height: 20,
                                  width: 20,
                                  color: notifire.getwhiteblackcolor,
                                ),
                                isExpanded: true,
                                underline: SizedBox.shrink(),
                                items: selectCountryController
                                    .countryList //<String>[]
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        fontFamily: FontFamily.gilroyMedium,
                                        color: notifire.getwhiteblackcolor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  for (var i = 0;
                                      i <
                                          selectCountryController
                                              .countryInfo!.countryData!.length;
                                      i++) {
                                    if (value ==
                                        selectCountryController.countryInfo
                                            ?.countryData![i].title) {
                                      // log(selectCountryController
                                      //     .countryInfo!.countryData![i].id
                                      //     .toString());
                                      addPropertiesController.countryId =
                                          selectCountryController.countryInfo
                                                  ?.countryData![i].id ??
                                              "";
                                    }
                                  }
                                  log(addPropertiesController.countryId
                                      .toString());
                                  setState(() {
                                    selectCountry = value ?? "";
                                  });
                                },
                              ),
                              decoration: BoxDecoration(
                                color: notifire.getblackwhitecolor,
                                borderRadius: BorderRadius.circular(15),
                                border:
                                    Border.all(color: notifire.getborderColor),
                              ),
                            );
                          }),
                          textfield(
                            type: "Property Title".tr,
                            controller: addPropertiesController.pTitle,
                            labelText: "Full Name".tr,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please Enter Property Title'.tr;
                              }
                              return null;
                            },
                          ),
                          textfield(
                            type: "Mobile Number".tr,
                            controller: addPropertiesController.pNumber,
                            labelText: "Mobile Number".tr,
                            textInputType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11)
                            ],
                            validator: (value) {
                              if (value == null ||
                                  !RegExp(r'^\d{11}$').hasMatch(value)) {
                                return 'Enter an 11-digit mobile number';
                              }
                              return null;
                            },
                          ),
                          textfield(
                            type: "Address".tr,
                            controller: addPropertiesController.pAddress,
                            labelText: "Address".tr,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please Enter Your Address'.tr;
                              }
                              return null;
                            },
                          ),
                          textfield(
                            type: "Property Price".tr,
                            controller: addPropertiesController.pPrice,
                            labelText: "Price".tr,
                            textInputType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _moneyFormatter
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please Enter Property Price'.tr;
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              "Property Description".tr,
                              style: TextStyle(
                                fontFamily: FontFamily.gilroyBold,
                                fontSize: 16,
                                color: notifire.getwhiteblackcolor,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Container(
                            margin:
                                EdgeInsets.only(top: 5, left: 15, right: 15),
                            child: TextFormField(
                              controller:
                                  addPropertiesController.propertyAddress,
                              minLines: 5,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              cursorColor: notifire.getwhiteblackcolor,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: blueColor),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                contentPadding: EdgeInsets.all(10),
                                border: InputBorder.none,
                                hintText: "Description".tr,
                                hintStyle: TextStyle(
                                  fontFamily: FontFamily.gilroyMedium,
                                  fontSize: 15,
                                ),
                              ),
                              style: TextStyle(
                                fontFamily: FontFamily.gilroyMedium,
                                fontSize: 16,
                                color: notifire.getwhiteblackcolor,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please Enter Property Description'.tr;
                                }
                                return null;
                              },
                            ),
                            decoration: BoxDecoration(
                              color: notifire.getblackwhitecolor,
                              borderRadius: BorderRadius.circular(15),
                              border:
                                  Border.all(color: notifire.getborderColor),
                            ),
                          ),
                          _numberDropdown('Total Beds'.tr,
                              addPropertiesController.totalBeds, 0, 20),
                          _numberDropdown('Total Bathrooms'.tr,
                              addPropertiesController.totalBathroom, 0, 20),
                          textfield(
                            type: 'Property size (sqm)',
                            controller: addPropertiesController.pSqft,
                            labelText: 'Square metres (sqm)',
                            textInputType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the property size in sqm';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          _numberDropdown('Total people allowed',
                              addPropertiesController.pGest, 1, 30),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              "Property Type".tr,
                              style: TextStyle(
                                fontFamily: FontFamily.gilroyBold,
                                fontSize: 16,
                                color: notifire.getwhiteblackcolor,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Container(
                            height: 60,
                            width: Get.size.width,
                            alignment: Alignment.center,
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            padding: EdgeInsets.only(left: 15, right: 15),
                            child: DropdownButton(
                              dropdownColor: notifire.getbgcolor,
                              hint: Text(
                                "Select Property".tr,
                                style: TextStyle(color: Colors.grey),
                              ),
                              value: selectProperty,
                              icon: Image.asset(
                                'assets/images/Arrow - Down.png',
                                height: 20,
                                width: 20,
                                color: notifire.getwhiteblackcolor,
                              ),
                              underline: SizedBox.shrink(),
                              isExpanded: true,
                              items: dashBoardController.typeList
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      fontFamily: FontFamily.gilroyMedium,
                                      color: notifire.getwhiteblackcolor,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                for (var i = 0;
                                    i <
                                        dashBoardController
                                            .proTypeInfo!.typelist!.length;
                                    i++) {
                                  if (value ==
                                      dashBoardController
                                          .proTypeInfo?.typelist![i].title) {
                                    addPropertiesController.pType =
                                        dashBoardController
                                                .proTypeInfo?.typelist![i].id ??
                                            "";
                                    print(addPropertiesController.pType);
                                  }
                                }
                                setState(() {
                                  selectProperty = value ?? "";
                                });
                              },
                            ),
                            decoration: BoxDecoration(
                              color: notifire.getblackwhitecolor,
                              borderRadius: BorderRadius.circular(15),
                              border:
                                  Border.all(color: notifire.getborderColor),
                            ),
                          ),
                          textfield(
                            type: "City, Country".tr,
                            controller: addPropertiesController.pCityAndCountry,
                            labelText: "City, Country".tr,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please Enter City, Country'.tr;
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              "Select Property Facility".tr,
                              style: TextStyle(
                                fontFamily: FontFamily.gilroyBold,
                                fontSize: 16,
                                color: notifire.getwhiteblackcolor,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          GetBuilder<AddPropertiesController>(
                              builder: (context) {
                            return ListView.builder(
                              itemCount: dashBoardController
                                  .facilityInfo?.facilitylist!.length,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Transform.scale(
                                          scale: 1,
                                          child: Checkbox(
                                            value: addPropertiesController
                                                .selectedIndexes
                                                .contains(dashBoardController
                                                    .facilityInfo
                                                    ?.facilitylist![index]
                                                    .id),
                                            side: const BorderSide(
                                                color: Color(0xffC5CAD4)),
                                            activeColor: blueColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            onChanged: (_) {
                                              if (addPropertiesController
                                                  .selectedIndexes
                                                  .contains(dashBoardController
                                                      .facilityInfo
                                                      ?.facilitylist![index]
                                                      .id)) {
                                                addPropertiesController
                                                    .selectedIndexes
                                                    .remove(dashBoardController
                                                        .facilityInfo
                                                        ?.facilitylist![index]
                                                        .id); // unselect
                                                setState(() {});
                                              } else {
                                                addPropertiesController
                                                    .selectedIndexes
                                                    .add(dashBoardController
                                                        .facilityInfo
                                                        ?.facilitylist![index]
                                                        .id);
                                                setState(() {}); // select
                                              }
                                            },
                                          ),
                                        ),
                                        Text(
                                          dashBoardController
                                                  .facilityInfo
                                                  ?.facilitylist![index]
                                                  .title ??
                                              "",
                                          style: TextStyle(
                                            fontFamily: FontFamily.gilroyMedium,
                                            fontSize: 17,
                                            color: notifire.getwhiteblackcolor,
                                          ),
                                        ),
                                        Spacer(),
                                        Container(
                                          height: 40,
                                          width: 40,
                                          padding: EdgeInsets.all(8),
                                          child: Image.network(
                                            "${Config.imageUrl}${dashBoardController.facilityInfo?.facilitylist![index].img ?? ""}",
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFeef4ff),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 15,
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Divider(thickness: 1),
                                    ),
                                  ],
                                );
                              },
                            );
                          }),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              "Party Allowed?",
                              style: TextStyle(
                                fontFamily: FontFamily.gilroyBold,
                                fontSize: 16,
                                color: notifire.getwhiteblackcolor,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Transform.scale(
                                    scale: 1,
                                    child: Checkbox(
                                      value:
                                          addPropertiesController.party_allowed,
                                      side: const BorderSide(
                                          color: Color(0xffC5CAD4)),
                                      activeColor: blueColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      onChanged: (value) {
                                        addPropertiesController.party_allowed =
                                            value!;
                                        if (value == false) {
                                          addPropertiesController.pPartyCost
                                              .clear();
                                        }
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (addPropertiesController
                                          .party_allowed) {
                                        addPropertiesController.pPartyCost
                                            .clear();
                                      }
                                      addPropertiesController.party_allowed =
                                          !addPropertiesController
                                              .party_allowed;

                                      setState(() {});
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          "Party is Allowed",
                                          style: TextStyle(
                                            fontFamily: FontFamily.gilroyMedium,
                                            fontSize: 17,
                                            color: notifire.getwhiteblackcolor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (addPropertiesController.party_allowed)
                                textfield(
                                  type: "Party Cost",
                                  controller:
                                      addPropertiesController.pPartyCost,
                                  labelText: "Party cost",
                                  textInputType: TextInputType.number,
                                  // validator: (value) {
                                  //   if (value == null || value.isEmpty) {
                                  //     return 'Please Enter Property Price';
                                  //   }
                                  //   return null;
                                  // },
                                ),
                              textfield(
                                type: "Caution Fee",
                                controller: addPropertiesController.pCaution,
                                labelText: "Caution fee",
                                textInputType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  _moneyFormatter
                                ],
                                // validator: (value) {
                                //   if (value == null || value.isEmpty) {
                                //     return 'Please Enter Property Price';
                                //   }
                                //   return null;
                                // },
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              // Padding(
                              //   padding: const EdgeInsets.only(left: 15),
                              //   child: Text(
                              //     "Caution Fee Setting",
                              //     style: TextStyle(
                              //       fontFamily: FontFamily.gilroyBold,
                              //       fontSize: 16,
                              //       color: notifire.getwhiteblackcolor,
                              //     ),
                              //   ),
                              // ),
                              // Row(
                              //   children: [
                              //     SizedBox(
                              //       width: 10,
                              //     ),
                              //     Transform.scale(
                              //       scale: 1,
                              //       child: Checkbox(
                              //         value: addPropertiesController
                              //             .caution_fee_setting,
                              //         side: const BorderSide(
                              //             color: Color(0xffC5CAD4)),
                              //         activeColor: blueColor,
                              //         shape: RoundedRectangleBorder(
                              //           borderRadius: BorderRadius.circular(5),
                              //         ),
                              //         onChanged: (value) {
                              //           addPropertiesController
                              //               .caution_fee_setting = value!;

                              //           setState(() {});
                              //         },
                              //       ),
                              //     ),
                              //     GestureDetector(
                              //       onTap: () {
                              //         addPropertiesController
                              //                 .caution_fee_setting =
                              //             !addPropertiesController
                              //                 .caution_fee_setting;

                              //         setState(() {});
                              //       },
                              //       child: Row(
                              //         children: [
                              //           Text(
                              //             "On",
                              //             style: TextStyle(
                              //               fontFamily: FontFamily.gilroyMedium,
                              //               fontSize: 17,
                              //               color: notifire.getwhiteblackcolor,
                              //             ),
                              //           ),
                              //         ],
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              // SizedBox(
                              //   height: 10,
                              // ),
                            ],
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          InkWell(
                            onTap: () async {
                              LocationPermission permission;
                              permission = await Geolocator.checkPermission();
                              permission = await Geolocator.requestPermission();
                              if (permission == LocationPermission.denied) {}
                              var currentLocation = await locateUser();
                              debugPrint(
                                  'location: ${currentLocation.latitude}');
                              addPropertiesController.getCurrentLatAndLong(
                                currentLocation.latitude,
                                currentLocation.longitude,
                              );
                              print("????????????" +
                                  currentLocation.latitude.toString());
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: Row(
                                children: [
                                  Image.asset(
                                    "assets/images/Navigation.png",
                                    height: 25,
                                    width: 25,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    "Click for Current Location".tr,
                                    style: TextStyle(
                                      color: notifire.getwhiteblackcolor,
                                      fontFamily: FontFamily.gilroyMedium,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              "Upload Image".tr,
                              style: TextStyle(
                                fontFamily: FontFamily.gilroyBold,
                                fontSize: 16,
                                color: notifire.getwhiteblackcolor,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          DottedBorder(
                            borderType: BorderType.RRect,
                            color: Darkblue,
                            radius: Radius.circular(15),
                            borderPadding: EdgeInsets.symmetric(horizontal: 20),
                            child: InkWell(
                              onTap: () {
                                _openGallery(context);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: manegeRoute == "Add"
                                    ? Container(
                                        height: 80,
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 20),
                                        width: Get.size.width,
                                        alignment: Alignment.center,
                                        child: addPropertiesController.path ==
                                                null
                                            ? Image.asset(
                                                "assets/images/image-upload.png",
                                                height: 40,
                                                width: 42,
                                              )
                                            : Image.file(
                                                File(
                                                  addPropertiesController.path
                                                      .toString(),
                                                ),
                                                height: 50,
                                                width: 50,
                                                fit: BoxFit.cover,
                                              ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                      )
                                    : Container(
                                        height: 80,
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 20),
                                        width: Get.size.width,
                                        alignment: Alignment.center,
                                        child: addPropertiesController.pImage ==
                                                ""
                                            ? Image.asset(
                                                "assets/images/image-upload.png",
                                                height: 40,
                                                width: 42,
                                              )
                                            : addPropertiesController.path ==
                                                    null
                                                ? Image.network(
                                                    "${Config.imageUrl}${addPropertiesController.pImage}",
                                                    height: 50,
                                                    width: 50,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.file(
                                                    File(
                                                      addPropertiesController
                                                          .path
                                                          .toString(),
                                                    ),
                                                    height: 50,
                                                    width: 50,
                                                    fit: BoxFit.cover,
                                                  ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              manegeRoute == "Add"
                                  ? "Property Reel"
                                  : "Replace Property Reel (optional)",
                              style: TextStyle(
                                fontFamily: FontFamily.gilroyBold,
                                fontSize: 16,
                                color: notifire.getwhiteblackcolor,
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              "Upload a video up to 90 seconds, 1080p, and 300 MB.",
                              style: TextStyle(
                                fontFamily: FontFamily.gilroyMedium,
                                fontSize: 13,
                                color: notifire.getgreycolor,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          DottedBorder(
                            borderType: BorderType.RRect,
                            color: Darkblue,
                            radius: Radius.circular(15),
                            borderPadding: EdgeInsets.symmetric(horizontal: 20),
                            child: InkWell(
                              onTap: _pickReel,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  height: 150,
                                  width: Get.size.width,
                                  margin: EdgeInsets.symmetric(horizontal: 20),
                                  alignment: Alignment.center,
                                  child: _reelPreviewController == null ||
                                          !_reelPreviewController!
                                              .value.isInitialized
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.video_library_outlined,
                                              color: Darkblue,
                                              size: 42,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              "Choose reel",
                                              style: TextStyle(
                                                color:
                                                    notifire.getwhiteblackcolor,
                                                fontFamily:
                                                    FontFamily.gilroyMedium,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            AspectRatio(
                                              aspectRatio:
                                                  _reelPreviewController!
                                                      .value.aspectRatio,
                                              child: VideoPlayer(
                                                _reelPreviewController!,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (_reelPreviewController!
                                                      .value.isPlaying) {
                                                    _reelPreviewController!
                                                        .pause();
                                                  } else {
                                                    _reelPreviewController!
                                                        .play();
                                                  }
                                                });
                                              },
                                              child: Container(
                                                width: 52,
                                                height: 52,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.black
                                                      .withOpacity(0.35),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.85),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Icon(
                                                  _reelPreviewController!
                                                          .value.isPlaying
                                                      ? Icons.pause_rounded
                                                      : Icons
                                                          .play_arrow_rounded,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                          if (addPropertiesController.isBusy.value &&
                              addPropertiesController
                                  .reelUploadStage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: addPropertiesController
                                                .reelUploadStage ==
                                            'Uploading reel'
                                        ? addPropertiesController
                                            .reelUploadProgress
                                        : null,
                                    color: Darkblue,
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    addPropertiesController.reelUploadStage ==
                                            'Uploading reel'
                                        ? "Uploading reel ${(addPropertiesController.reelUploadProgress * 100).round()}%"
                                        : addPropertiesController
                                            .reelUploadStage,
                                    style: TextStyle(
                                      color: notifire.getgreycolor,
                                      fontFamily: FontFamily.gilroyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              "Property Status".tr,
                              style: TextStyle(
                                fontFamily: FontFamily.gilroyBold,
                                fontSize: 16,
                                color: notifire.getwhiteblackcolor,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Container(
                            height: 60,
                            width: Get.size.width,
                            alignment: Alignment.center,
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            padding: EdgeInsets.only(left: 15, right: 15),
                            child: DropdownButton(
                              value: slectStatus,
                              icon: Image.asset(
                                  'assets/images/Arrow - Down.png',
                                  height: 20,
                                  width: 20,
                                  color: notifire.getwhiteblackcolor),
                              isExpanded: true,
                              dropdownColor: notifire.getbgcolor,
                              underline: SizedBox.shrink(),
                              items: propartyStatus
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      fontFamily: FontFamily.gilroyMedium,
                                      color: notifire.getwhiteblackcolor,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == "Publish") {
                                  addPropertiesController.status = "1";
                                } else if (value == "UnPublish") {
                                  addPropertiesController.status = "0";
                                }
                                setState(() {
                                  slectStatus = value ?? "";
                                });
                              },
                            ),
                            decoration: BoxDecoration(
                              color: notifire.getblackwhitecolor,
                              borderRadius: BorderRadius.circular(15),
                              border:
                                  Border.all(color: notifire.getborderColor),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          addPropertiesController.pShell == "0"
                              ? addPropertiesController.isBusy.value
                                  ? Center(
                                      child: SizedBox(
                                        height: 25,
                                        width: 25,
                                        child: FastSpinner(
                                          color: Darkblue,
                                        ),
                                      ),
                                    )
                                  : GestButton(
                                      Width: Get.size.width,
                                      height: 55,
                                      buttoncolor: blueColor,
                                      margin: EdgeInsets.only(
                                          top: 5, left: 35, right: 35),
                                      buttontext: "Update".tr,
                                      style: TextStyle(
                                        fontFamily: FontFamily.gilroyBold,
                                        color: WhiteColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      onclick: addPropertiesController
                                              .isBusy.value
                                          ? null
                                          : () {
                                              // if (!addPropertiesController
                                              //     .isBusy) {
                                              //   print('sjkfdf');
                                              //   return;
                                              // }
                                              if (_formKey.currentState
                                                      ?.validate() ??
                                                  false) {
                                                if (selectCountry != null) {
                                                  if (selectProperty != null) {
                                                    if (addPropertiesController
                                                        .selectedIndexes
                                                        .isNotEmpty) {
                                                      // ===remove location validation (it can be null now)===
                                                      // if (addPropertiesController
                                                      //             .lat !=
                                                      //         null &&
                                                      //     addPropertiesController
                                                      //             .long !=
                                                      //         null) {
                                                      // ===remove location validation (it can be null now)===
                                                      if (addPropertiesController
                                                                  .path !=
                                                              null ||
                                                          addPropertiesController
                                                                  .pImage !=
                                                              "") {
                                                        if (manegeRoute ==
                                                            "Add") {
                                                          addPropertiesController
                                                              .submitPropertyWithReel();
                                                        } else if (manegeRoute ==
                                                            "edit") {
                                                          // log('in here');
                                                          // addPropertiesController
                                                          // .testLoading();
                                                          addPropertiesController
                                                              .editPropertyApi();
                                                        }
                                                      } else {
                                                        showToastMessage(
                                                            "Please Upload Image"
                                                                .tr);
                                                      }
                                                      // ===remove location validation (it can be null now)===
                                                      // }
                                                      //  else {
                                                      //   showToastMessage(
                                                      //       "Please Add Your Property Location"
                                                      //           .tr);
                                                      // }
                                                      // ===remove location validation (it can be null now)===
                                                    } else {
                                                      showToastMessage(
                                                          "Please Select Property Facility"
                                                              .tr);
                                                    }
                                                  } else {
                                                    showToastMessage(
                                                        "Please Select Property Type"
                                                            .tr);
                                                  }
                                                } else {
                                                  showToastMessage(
                                                      "Please Select Country"
                                                          .tr);
                                                }
                                              }
                                            },
                                    )
                              : SizedBox(),
                          SizedBox(
                            height: 25,
                          ),
                        ],
                      ),
                      decoration: BoxDecoration(
                        color: notifire.getblackwhitecolor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openGallery(BuildContext context) async {
    String? imagePath;
    try {
      imagePath =
          (await ImagePicker().pickImage(source: ImageSource.gallery))?.path;
    } on PlatformException catch (error) {
      if (error.code != 'invalid_image') {
        showToastMessage('Unable to open the photo. Please try again.');
        return;
      }
      showToastMessage(
          'iOS could not load that photo. Choose a saved copy from Files.');
      try {
        final result =
            await FilePicker.platform.pickFiles(type: FileType.image);
        imagePath = result?.files.single.path;
      } catch (_) {
        showToastMessage('Unable to open the photo from Files.');
        return;
      }
    } catch (_) {
      showToastMessage('Unable to open the photo. Please try again.');
      return;
    }
    if (imagePath == null) return;
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      if (imageBytes.isEmpty) throw const FormatException('Empty image');
      if (!mounted) return;
      setState(() {
        addPropertiesController.path = imagePath;
        addPropertiesController.base64Image = base64Encode(imageBytes);
      });
    } catch (_) {
      showToastMessage(
          'Unable to read the selected photo. Choose another image.');
    }
  }

  Future<void> _pickReel() async {
    final pickedVideo = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 90),
    );
    if (pickedVideo == null) return;

    final error = await addPropertiesController.validateReel(pickedVideo.path);
    if (error != null) {
      showToastMessage(error);
      return;
    }

    final preview = VideoPlayerController.file(File(pickedVideo.path));
    try {
      await preview.initialize();
      final size = preview.value.size;
      final longEdge = size.width > size.height ? size.width : size.height;
      final shortEdge = size.width > size.height ? size.height : size.width;
      if (preview.value.duration > const Duration(seconds: 90)) {
        await preview.dispose();
        showToastMessage('The reel must be 90 seconds or shorter.');
        return;
      }
      if (longEdge > 1920 || shortEdge > 1080) {
        await preview.dispose();
        showToastMessage('The reel resolution must not exceed 1080p.');
        return;
      }
      await _reelPreviewController?.dispose();
      _reelPreviewController = preview;
      addPropertiesController.reelVideoPath = pickedVideo.path;
      addPropertiesController.reelThumbnailPath = null;
      addPropertiesController.reelUploadProgress = 0;
      addPropertiesController.reelUploadStage = '';
      if (mounted) setState(() {});
    } catch (_) {
      await preview.dispose();
      showToastMessage('This video could not be opened. Choose another reel.');
    }
  }

  Widget _numberDropdown(String label, TextEditingController controller,
      int minimum, int maximum) {
    final values = [
      for (var value = minimum; value <= maximum; value++) '$value'
    ];
    final selected = controller.text.trim();
    if (selected.isNotEmpty && !values.contains(selected)) values.add(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Text(label,
              style: TextStyle(
                fontFamily: FontFamily.gilroyBold,
                fontSize: 16,
                color: notifire.getwhiteblackcolor,
              )),
        ),
        const SizedBox(height: 8),
        FormField<String>(
          initialValue: selected.isEmpty ? null : selected,
          validator: (value) =>
              value == null || value.isEmpty ? 'Please select $label' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 60,
                width: Get.size.width,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: notifire.getblackwhitecolor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color:
                        field.hasError ? Colors.red : notifire.getborderColor,
                  ),
                ),
                child: DropdownButton<String>(
                  value: field.value,
                  hint: Text('Select $label',
                      style: const TextStyle(color: Colors.grey)),
                  icon: Image.asset('assets/images/Arrow - Down.png',
                      height: 20,
                      width: 20,
                      color: notifire.getwhiteblackcolor),
                  underline: const SizedBox.shrink(),
                  isExpanded: true,
                  menuMaxHeight: 220,
                  dropdownColor: notifire.getbgcolor,
                  items: values
                      .map((value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,
                                style: TextStyle(
                                  fontFamily: FontFamily.gilroyMedium,
                                  color: notifire.getwhiteblackcolor,
                                  fontSize: 14,
                                )),
                          ))
                      .toList(),
                  onChanged: (value) {
                    field.didChange(value);
                    controller.text = value ?? '';
                  },
                ),
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 5),
                  child: Text(field.errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  textfield(
      {String? type,
      labelText,
      prefixtext,
      suffix,
      Color? labelcolor,
      prefixcolor,
      floatingLabelColor,
      focusedBorderColor,
      TextDecoration? decoration,
      bool? readOnly,
      double? Width,
      int? max,
      TextEditingController? controller,
      TextInputType? textInputType,
      List<TextInputFormatter>? inputFormatters,
      Function(String)? onChanged,
      String? Function(String?)? validator,
      Height}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Text(
            type ?? "",
            style: TextStyle(
              fontFamily: FontFamily.gilroyBold,
              fontSize: 16,
              color: notifire.getwhiteblackcolor,
            ),
          ),
        ),
        SizedBox(
          height: 6,
        ),
        Container(
          height: Height,
          width: Width,
          margin: EdgeInsets.only(top: 5, bottom: 5, left: 12, right: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: notifire.getblackwhitecolor),
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            cursorColor: notifire.getwhiteblackcolor,
            keyboardType: textInputType,
            inputFormatters: inputFormatters,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            maxLength: max,
            readOnly: readOnly ?? false,
            style: TextStyle(
                color: notifire.getwhiteblackcolor,
                fontFamily: FontFamily.gilroyMedium,
                fontSize: 18),
            decoration: InputDecoration(
              hintText: labelText,
              hintStyle: TextStyle(
                  color: Colors.grey,
                  fontFamily: "Gilroy Medium",
                  fontSize: 16),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: blueColor),
                borderRadius: BorderRadius.circular(15),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: notifire.getborderColor),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: notifire.getborderColor),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
