// ignore_for_file: prefer_const_constructors, sort_child_properties_last

import 'dart:convert';
import 'dart:math';
import 'dart:developer' as l;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:opendoors/controller/login_controller.dart';
import 'package:opendoors/controller/signup_controller.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/model/routes_helper.dart';
import 'package:opendoors/screen/webview_page.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocialPhoneScreen extends StatefulWidget {
  const SocialPhoneScreen({super.key});

  @override
  State<SocialPhoneScreen> createState() => _SocialPhoneScreenState();
}

class _SocialPhoneScreenState extends State<SocialPhoneScreen> {
  final SignUpController signUpController = Get.find();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final SocialAuthResult socialAuth;
  late ColorNotifire notifire;

  String cuntryCode = "+234";
  bool isValidate = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    socialAuth = Get.arguments as SocialAuthResult;
    signUpController.number.text = "";
    signUpController.chack = false;
    signUpController.newsletter = false;
  }

  @override
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    final providerName = socialAuth.provider.capitalizeFirst ?? "Social";

    return Scaffold(
      backgroundColor: notifire.getbgcolor,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(18.0),
          child: InkWell(
            onTap: () {
              Get.back();
            },
            child: Image.asset(
              'assets/images/back.png',
              color: notifire.getwhiteblackcolor,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: Get.size.height),
                child: SizedBox(
                  width: Get.size.width,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15),
                          child: Text(
                            "Add your phone number".tr,
                            style: TextStyle(
                              fontSize: 25,
                              fontFamily: FontFamily.gilroyBold,
                              color: notifire.getwhiteblackcolor,
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15),
                          child: Text(
                            "We need your phone number to finish your $providerName signup."
                                .tr,
                            style: TextStyle(
                              fontFamily: FontFamily.gilroyMedium,
                              color: notifire.getgreycolor,
                            ),
                          ),
                        ),
                        SizedBox(height: 25),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: IntlPhoneField(
                            disableLengthCheck: false,
                            keyboardType: TextInputType.number,
                            cursorColor: notifire.getwhiteblackcolor,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            controller: signUpController.number,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            initialCountryCode: "NG",
                            dropdownIcon: Icon(
                              Icons.arrow_drop_down,
                              color: notifire.getgreycolor,
                            ),
                            dropdownTextStyle: TextStyle(
                              color: notifire.getgreycolor,
                            ),
                            style: TextStyle(
                              fontFamily: FontFamily.gilroyBold,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: notifire.getwhiteblackcolor,
                            ),
                            onChanged: (value) {
                              setState(() {
                                isValidate =
                                    signUpController.number.text.isEmpty;
                                cuntryCode = value.countryCode;
                              });
                            },
                            onCountryChanged: (value) {
                              signUpController.number.text = "";
                            },
                            invalidNumberMessage:
                                'Please enter a valid phone number'.tr,
                            decoration: InputDecoration(
                              counterText: '',
                              helperText: '',
                              hintText: '7012345678',
                              hintStyle: TextStyle(color: Color(0xffb1b7c8)),
                              labelText: "Mobile Number".tr,
                              labelStyle: TextStyle(
                                color: notifire.getgreycolor,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: isValidate
                                      ? Colors.red.shade700
                                      : blueColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: isValidate
                                      ? Colors.red.shade700
                                      : notifire.getborderColor,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: isValidate
                                      ? Colors.red.shade700
                                      : notifire.getborderColor,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            validator: (phone) {
                              if (phone == null ||
                                  phone.completeNumber.isEmpty) {
                                return 'Please enter your number'.tr;
                              }
                              if (!phone.isValidNumber()) {
                                return 'Please enter a valid phone number'.tr;
                              }
                              if (phone.countryCode == 'NG' &&
                                  (phone.number.length < 10 ||
                                      phone.number.length > 11)) {
                                return 'Please enter a valid phone number'.tr;
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 25),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextFormField(
                            controller: signUpController.referralCode,
                            cursorColor: notifire.getwhiteblackcolor,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            style: TextStyle(
                              fontFamily: FontFamily.gilroyBold,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: notifire.getwhiteblackcolor,
                            ),
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: blueColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: notifire.getborderColor,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: notifire.getborderColor,
                                ),
                              ),
                              labelText: "Referral code (optional)".tr,
                              labelStyle: TextStyle(
                                color: notifire.getgreycolor,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        GetBuilder<SignUpController>(builder: (ctx) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Transform.scale(
                                    scale: 1,
                                    child: Checkbox(
                                      value: signUpController.chack,
                                      side: const BorderSide(
                                          color: Color(0xffC5CAD4)),
                                      activeColor: blueColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      onChanged: (newbool) async {
                                        signUpController
                                            .checkTermsAndCondition(newbool);
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        await prefs.setBool('Remember', true);
                                      },
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "By creating an account,you agree to our"
                                                .tr,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: notifire.getgreycolor,
                                              fontFamily:
                                                  FontFamily.gilroyMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              WebviewPage(
                                                                  url:
                                                                      "https://opendoors-tc.netlify.app/")));
                                                },
                                                child: Text(
                                                  "Terms and Condition".tr,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: blueColor,
                                                    fontFamily:
                                                        FontFamily.gilroyBold,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                ' & ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily:
                                                      FontFamily.gilroyBold,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              WebviewPage(
                                                                  url:
                                                                      "https://superb-meerkat-f0d4da.netlify.app/")));
                                                },
                                                child: Text(
                                                  "Our Privacy Policy".tr,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: blueColor,
                                                    fontFamily:
                                                        FontFamily.gilroyBold,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // SizedBox(
                              //   height: 5,
                              // ),
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.start,
                              //   children: [
                              //     SizedBox(
                              //       width: 10,
                              //     ),
                              //     Transform.scale(
                              //       scale: 1,
                              //       child: Checkbox(
                              //         value: signUpController.chack,
                              //         side: const BorderSide(
                              //             color: Color(0xffC5CAD4)),
                              //         activeColor: blueColor,
                              //         shape: RoundedRectangleBorder(
                              //             borderRadius:
                              //                 BorderRadius.circular(5)),
                              //         onChanged: (newbool) async {
                              //           signUpController
                              //               .checkTermsAndCondition(newbool);
                              //           final prefs = await SharedPreferences
                              //               .getInstance();
                              //           await prefs.setBool('Remember', true);
                              //         },
                              //       ),
                              //     ),
                              //     GestureDetector(
                              //       onTap: () {
                              //         Navigator.push(
                              //             context,
                              //             MaterialPageRoute(
                              //                 builder: (context) => WebviewPage(
                              //                     url:
                              //                         "https://superb-meerkat-f0d4da.netlify.app/")));
                              //       },
                              //       child: Column(
                              //         crossAxisAlignment:
                              //             CrossAxisAlignment.start,
                              //         children: [
                              //           Text(
                              //             "Our Privacy Policy".tr,
                              //             style: TextStyle(
                              //               fontSize: 12,
                              //               color: blueColor,
                              //               fontFamily: FontFamily.gilroyBold,
                              //               overflow: TextOverflow.ellipsis,
                              //             ),
                              //           )
                              //         ],
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              // SizedBox(
                              //   height: 5,
                              // ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Transform.scale(
                                    scale: 1,
                                    child: Checkbox(
                                      value: signUpController.newsletter,
                                      side: const BorderSide(
                                          color: Color(0xffC5CAD4)),
                                      activeColor: blueColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      onChanged: (newbool) async {
                                        signUpController
                                            .newsLetterCheck(newbool);
                                      },
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Subscribe to Our Newsletter".tr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              (notifire.getblackblue as Color)
                                                  .withOpacity(0.6),
                                          fontFamily: FontFamily.gilroyBold,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                        SizedBox(height: 10),
                        GestButton(
                          Width: Get.size.width,
                          height: 50,
                          buttoncolor: blueColor,
                          margin: EdgeInsets.only(top: 15, left: 30, right: 30),
                          buttontext: "Continue".tr,
                          isLoading: isLoading,
                          style: TextStyle(
                            fontFamily: FontFamily.gilroyBold,
                            color: WhiteColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          onclick: isLoading ? null : _continueToOtp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continueToOtp() async {
    setState(() {
      isValidate = signUpController.number.text.isEmpty;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!signUpController.chack) {
      showToastMessage("Please select Terms and Condition".tr);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      _prepareSocialSignupFields();
      final initRes = await signUpController.socialRegisterInit(
        provider: socialAuth.provider,
        token: socialAuth.token,
        mobile: signUpController.number.text,
        ccode: cuntryCode,
        email: socialAuth.email,
        name: socialAuth.name,
      );

      l.log(initRes.toString(), name: 'social reg init');

      if (initRes != null && initRes["Result"] == "true") {
        Get.toNamed(
          Routes.otpScreen,
          arguments: {
            "number": signUpController.number.text,
            "cuntryCode": cuntryCode,
            "route": "socialSignUpScreen",
            "email": signUpController.email.text.trim(),
            "otpCode": initRes["otp"].toString(),
            "provider": socialAuth.provider,
            "token": socialAuth.token,
            "name": socialAuth.name ?? signUpController.name.text,
            "real_name": socialAuth.name,
            "real_email": socialAuth.email,
            "refercode": signUpController.referralCode.text,
            "accept_newsletter": signUpController.newsletter ? 1 : 0,
            "accept_privacy_policy": signUpController.chack ? 1 : 0,
            "accept_terms_condition": signUpController.chack ? 1 : 0,
          },
        );
      } else if (initRes != null && initRes["ResponseCode"] == "409") {
        showToastMessage(
            initRes["ResponseMsg"] ?? "Account already exists. Please log in.");
        Get.offAllNamed(Routes.login);
      } else {
        showToastMessage(
            initRes?["ResponseMsg"] ?? "Mobile Number Already Used!");
      }
    } catch (e) {
      showToastMessage("Something went wrong!");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _prepareSocialSignupFields() {
    final tokenPrefix = socialAuth.token.substring(
      0,
      min(24, socialAuth.token.length),
    );
    final fallbackEmail =
        "${socialAuth.provider}_${base64Url.encode(utf8.encode(tokenPrefix))}@opendoors.social";

    signUpController.name.text = (socialAuth.name?.trim().isNotEmpty ?? false)
        ? socialAuth.name!.trim()
        : "${socialAuth.provider.capitalizeFirst ?? "Social"} User";
    signUpController.email.text = (socialAuth.email?.trim().isNotEmpty ?? false)
        ? socialAuth.email!.trim()
        : fallbackEmail;
    signUpController.password.text =
        "${socialAuth.provider}_${base64Url.encode(utf8.encode(tokenPrefix))}";
  }
}
