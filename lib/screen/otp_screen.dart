// ignore_for_file: prefer_const_constructors, must_be_immutable, use_key_in_widget_constructors, unnecessary_brace_in_string_interps, avoid_print, sort_child_properties_last, unrelated_type_equality_checks

import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/controller/login_controller.dart';
import 'package:opendoors/controller/selectcountry_controller.dart';
import 'package:opendoors/controller/signup_controller.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/model/routes_helper.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Api/data_store.dart';
import '../controller/homepage_controller.dart';
import '../controller/search_controller.dart';

class OtpScreen extends StatefulWidget {
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  TextEditingController pinPutController = TextEditingController();
  LoginController loginController = Get.find();
  SignUpController signUpController = Get.find();
  SelectCountryController selectCountryController = Get.find();
  HomePageController homePageController = Get.find();
  SearchPropertyController searchController = Get.find();

  FirebaseAuth auth = FirebaseAuth.instance;

  String code = "";
  String phoneNumber = Get.arguments["number"];

  String countryCode = Get.arguments["cuntryCode"];

  String rout = Get.arguments["route"];

  String otpCode = Get.arguments["otpCode"].toString();

  String email = Get.arguments["email"];

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

  Future getCountryData() async {
    selectCountryController.getCountryApi().then((value) {
      print(
          "COUNTRY SELECTED $countrySelected -= ${selectCountryController.countryInfo?.countryData![countrySelected].title}");
      for (int a = 0;
          a < selectCountryController.countryInfo!.countryData!.length;
          a++) {
        if (selectCountryController.countryInfo?.countryData![a].dCon == "1") {
          setState(() {
            countrySelected = a;
            print(
                "COUNTRY SELECTED $countrySelected -= ${selectCountryController.countryInfo?.countryData![countrySelected].title}");
            setState(() {
              save(
                  "countryId",
                  selectCountryController
                          .countryInfo?.countryData![countrySelected].id ??
                      "");
              save(
                  "countryName",
                  selectCountryController
                          .countryInfo?.countryData![countrySelected].title ??
                      "");
            });
          });
        } else {
          save(
              "countryId",
              selectCountryController
                      .countryInfo?.countryData![countrySelected].id ??
                  "");
          save(
              "countryName",
              selectCountryController
                      .countryInfo?.countryData![countrySelected].title ??
                  "");
        }
      }
      setState(() {
        isLoading = false;
      });
    });
  }

  int countrySelected = 0;

  bool isLoading = false;
  bool isResending = false;
  @override
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    final message = rout == "resetScreen"
        ? "${"We have sent a reset password otp code to".tr}\n${email}"
        : "${"We have sent the verification code to".tr}\n${email}";
    return Scaffold(
      backgroundColor: notifire.getbgcolor,
      body: Stack(
        children: [
          SafeArea(
            child: SizedBox(
              height: Get.size.height,
              width: Get.size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(left: 10),
                      padding: EdgeInsets.all(15),
                      child: Image.asset(
                        'assets/images/back.png',
                        color: notifire.getwhiteblackcolor,
                      ),
                      decoration: BoxDecoration(
                        color: notifire.getboxcolor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      "Verification Code".tr,
                      style: TextStyle(
                        fontSize: 25,
                        fontFamily: FontFamily.gilroyBold,
                        color: notifire.getwhiteblackcolor,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      // "${"We have sent the code verification to".tr}\n${countryCode} ${phoneNumber}",
                      message,

                      maxLines: 3,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        fontFamily: FontFamily.gilroyMedium,
                        color: notifire.getgreycolor,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Container(
                    alignment: Alignment.center,
                    child: Pinput(
                        length: 6,
                        keyboardType: TextInputType.number,
                        obscureText: false,
                        defaultPinTheme: PinTheme(
                          width: 52,
                          height: 52,
                          textStyle: TextStyle(
                            fontSize: 20,
                            color: notifire.getwhiteblackcolor,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: notifire.getborderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                        showCursor: true,
                        controller: pinPutController,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        onCompleted: (pin) => print(pin),
                        onChanged: (value) {
                          code = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your otp'.tr;
                          }
                          return null;
                        }),
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ".tr,
                          style: TextStyle(
                            fontFamily: FontFamily.gilroyMedium,
                            color: notifire.getgreycolor,
                          ),
                        ),
                        InkWell(
                          onTap: isResending
                              ? null
                              : () {
                                  // signUpController.smstype().then((value) {
                                  //   if(value["SMS_TYPE"] == "Msg91"){
                                  //     signUpController.sendOtp(countryCode, phoneNumber).then((value) {
                                  //       setState(() {
                                  //         otpCode = value["otp"].toString();
                                  //       });
                                  //     },);
                                  //   } else if(value["SMS_TYPE"] == "Twilio") {
                                  //     signUpController.twilloOtp(countryCode, phoneNumber).then((value) {
                                  //       setState(() {
                                  //         otpCode = value["otp"].toString();
                                  //       });
                                  //     },);
                                  //   }
                                  // });
                                  setState(() {
                                    isResending = true;
                                  });
                                  signUpController.emailOtp(email).then((res) {
                                    if (res["Result"] == "true") {
                                      setState(() {
                                        otpCode = res["otp"].toString();
                                      });
                                    }
                                  }).whenComplete(() {
                                    setState(() {
                                      isResending = false;
                                    });
                                  });

                                  pinPutController.text = "";
                                },
                          child: Container(
                            height: 30,
                            alignment: Alignment.center,
                            child: Text(
                              "Resend New Code ".tr,
                              style: TextStyle(
                                color: blueColor,
                                fontFamily: FontFamily.gilroyBold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                          width: 10,
                          child: Visibility(
                            visible: isResending,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(blueColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 60,
                  ),
                  GestButton(
                    Width: Get.size.width,
                    height: 50,
                    buttoncolor: blueColor,
                    margin: EdgeInsets.only(top: 15, left: 30, right: 30),
                    buttontext: "Verify".tr,
                    style: TextStyle(
                      fontFamily: "Gilroy Bold",
                      color: WhiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    onclick: () {
                      print("OTP CODE :   $otpCode");
                      if (otpCode == code) {
                        setState(() {
                          isLoading = true;
                        });
                        getCountryData().then(
                          (value) {
                            if (rout == "signUpScreen") {
                              setState(() {
                                isLoading = true;
                              });
                              try {
                                signUpController
                                    .setUserApiData(countryCode)
                                    .then(
                                  (value) {
                                    print(
                                        ">>>>>>>>>>>>>>>>> >>>>>>>>>>>> >>>>>>>>>> >>>> ${value}");
                                    if (value["Result"] == "true") {
                                      selectCountryController
                                          .changeCountryIndex(countrySelected);
                                      homePageController.getHomeDataApi(
                                          countryId: getData.read("countryId"));
                                      homePageController.getCatWiseData(
                                          countryId: getData.read("countryId"),
                                          cId: "0");
                                      searchController.getSearchData(
                                          countryId: getData.read("countryId"));
                                      Get.offAndToNamed(Routes.bottoBarScreen);
                                      setState(() {
                                        isLoading = false;
                                      });
                                    } else {
                                      setState(() {
                                        isLoading = false;
                                      });
                                      showToastMessage(value["ResponseMsg"]);
                                    }
                                  },
                                );
                                initPlatformState();
                                showToastMessage(signUpController.signUpMsg);
                              } catch (e) {
                                setState(() {
                                  isLoading = false;
                                });
                                print("525 --- 525  --- 525 ${e}");
                              }
                            } else if (rout == "resetScreen") {
                              setState(() {
                                isLoading = false;
                              });
                              forgetPasswordBottomSheet();
                            }
                          },
                        );
                      } else {
                        showToastMessage("Please enter your valid OTP".tr);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          isLoading
              ? Center(
                  child: CircularProgressIndicator(
                  color: Darkblue,
                ))
              : SizedBox()
        ],
      ),
    );
  }

  Future<void> initPlatformState() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(Config.oneSignel);
    OneSignal.Notifications.requestPermission(true).then(
      (value) {
        print("Signal value:- $value");
      },
    );
  }

  Future forgetPasswordBottomSheet() {
    return Get.bottomSheet(
      GetBuilder<LoginController>(builder: (context) {
        return SingleChildScrollView(
          child: Container(
            height: 350,
            width: Get.size.width,
            child: Column(
              children: [
                SizedBox(
                  height: 15,
                ),
                Text(
                  "Forgot Password".tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: FontFamily.gilroyBold,
                    color: notifire.getwhiteblackcolor,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Divider(
                    color: notifire.getgreycolor,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.only(top: 5, left: 15),
                  child: Text(
                    "Create Your New Password".tr,
                    style: TextStyle(
                      fontFamily: FontFamily.gilroyMedium,
                      color: notifire.getwhiteblackcolor,
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextFormField(
                    controller: loginController.newPassword,
                    obscureText: loginController.newShowPassword,
                    cursorColor: notifire.getwhiteblackcolor,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: FontFamily.gilroyMedium,
                      color: notifire.getwhiteblackcolor,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password'.tr;
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: greycolor),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: greycolor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: greycolor),
                      ),
                      suffixIcon: InkWell(
                        onTap: () {
                          loginController.newShowOfPassword();
                        },
                        child: !loginController.newShowPassword
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  "assets/images/showpassowrd.png",
                                  height: 10,
                                  width: 10,
                                  color: notifire.getgreycolor,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  "assets/images/HidePassword.png",
                                  height: 10,
                                  width: 10,
                                  color: notifire.getgreycolor,
                                ),
                              ),
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          "assets/images/Unlock.png",
                          height: 10,
                          width: 10,
                          color: notifire.getgreycolor,
                        ),
                      ),
                      labelText: "Password".tr,
                      labelStyle: TextStyle(
                        color: notifire.getgreycolor,
                        fontFamily: FontFamily.gilroyMedium,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextFormField(
                    controller: loginController.newConformPassword,
                    obscureText: loginController.conformPassword,
                    cursorColor: notifire.getwhiteblackcolor,
                    style: TextStyle(
                      fontFamily: FontFamily.gilroyMedium,
                      fontSize: 14,
                      color: notifire.getwhiteblackcolor,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password'.tr;
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: greycolor),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: greycolor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: greycolor),
                      ),
                      suffixIcon: InkWell(
                        onTap: () {
                          loginController.newConformShowOfPassword();
                        },
                        child: !loginController.conformPassword
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  "assets/images/showpassowrd.png",
                                  height: 10,
                                  width: 10,
                                  color: notifire.getgreycolor,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  "assets/images/HidePassword.png",
                                  height: 10,
                                  width: 10,
                                  color: notifire.getgreycolor,
                                ),
                              ),
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          "assets/images/Unlock.png",
                          height: 10,
                          width: 10,
                          color: notifire.getgreycolor,
                        ),
                      ),
                      labelText: "Conform Password".tr,
                      labelStyle: TextStyle(
                        color: notifire.getgreycolor,
                        fontFamily: FontFamily.gilroyMedium,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                GestButton(
                  Width: Get.size.width,
                  height: 50,
                  buttoncolor: blueColor,
                  margin: EdgeInsets.only(top: 15, left: 30, right: 30),
                  buttontext: "Continue".tr,
                  isLoading: loginController.isSending ? true : false,
                  style: TextStyle(
                    fontFamily: "Gilroy Bold",
                    color: WhiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  onclick: loginController.isSending
                      ? null
                      : () {
                          log('message');
                          if (loginController.newPassword.text ==
                              loginController.newConformPassword.text) {
                            log('message');
                            loginController.setForgetPasswordApi(
                                ccode: countryCode,
                                mobile: phoneNumber,
                                email: email);
                          } else {
                            showToastMessage("Please Enter Valid Password".tr,
                                ToastGravity.TOP);
                          }
                        },
                ),
              ],
            ),
            decoration: BoxDecoration(
              color: notifire.getbgcolor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
          ),
        );
      }),
    );
  }
}
