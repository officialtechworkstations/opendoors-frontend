// ignore_for_file: avoid_print, unused_local_variable, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/firebase/auth_service.dart';
import 'package:opendoors/model/msgotp_model.dart';
import 'package:opendoors/screen/viewprofile_screen.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpController extends GetxController implements GetxService {
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController number = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController referralCode = TextEditingController();

  bool showPassword = true;
  bool chack = false;
  bool newsletter = false;
  int currentIndex = 0;

  String userMessage = "";
  String resultCheck = "";
  String signUpMsg = "";

  showOfPassword() {
    showPassword = !showPassword;
    update();
  }

  checkTermsAndCondition(bool? newbool) {
    chack = newbool ?? false;
    update();
  }

  newsLetterCheck(bool? newbool) {
    newsletter = newbool ?? false;
    update();
  }

  cleanFild() {
    name.text = "";
    email.text = "";
    number.text = "";
    password.text = "";
    referralCode.text = "";
    chack = false;
    update();
  }

  changeIndex(int index) {
    currentIndex = index;
    update();
  }

  Future smstype() async {
    var response =
        await http.get(Uri.parse(Config.path + Config.smstype), headers: {
      'Content-Type': 'application/json',
    });

    print('=======================smstype======================');
    print(response.body.toString());
    print('=======================smstype======================');

    if (response.statusCode == 200) {
      var smsdecode = jsonDecode(response.body);
      update();
      print(response.body.toString());
      print(
          " SMS CODE TYPE >>>>>>>>>>>>>> : : : : : :${smsdecode["SMS_TYPE"]}");
      return smsdecode;
    }
  }

  ensureNoZeroInitial(String number) {
    String localNumber = number.trim();
    if (localNumber.startsWith('0')) {
      localNumber = localNumber.substring(1);
    }
    return localNumber;
  }

  Future checkMobileNumber(String cuntryCode) async {
    print("${cuntryCode}");

    try {
      final nb = ensureNoZeroInitial(number.text);

      Map map = {
        "mobile": nb,
        "ccode": cuntryCode,
      };
      Uri uri = Uri.parse(Config.path + Config.mobileChack);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );

      print('=======================checkMobileNumber======================');
      print(response.body.toString());
      print('=======================checkMobileNumber======================');

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        userMessage = result["ResponseMsg"];
        resultCheck = result["Result"];
        print(userMessage.toString());
        print("MMMMMMMMMMMMMMMMMM$result");
        return resultCheck;
      }
      update();
    } catch (e) {
      print(e.toString());
    }
  }

  Future checkMobileInResetPassword(
      {String? number, String? cuntryCode}) async {
    log('-----------------');
    log('number : $number');
    log('cuntryCode : $cuntryCode');
    log('-----------------');

    final nb = ensureNoZeroInitial(number ?? '');
    try {
      Map map = {
        "mobile": nb,
        "ccode": cuntryCode,
      };
      Uri uri = Uri.parse(Config.path + Config.mobileChack);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );

      log('response status code : ${response.statusCode}');
      log('response body : ${response.body}');

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        userMessage = result["ResponseMsg"];
        resultCheck = result["Result"];

        return resultCheck;
      }
      update();
    } catch (e) {
      print(e.toString());
    }
  }

  MsgotpModel? msgotpData;
  String otpCode = "";
  Future sendOtp(cuntryCode, number) async {
    final nb = ensureNoZeroInitial(number);
    Map body = {"mobile": cuntryCode + nb};

    var response = await http.post(Uri.parse(Config.path + Config.msgotp),
        body: jsonEncode(body),
        headers: {
          'Content-Type': 'application/json',
        });
    print("><<<<<<<<<<<<<<<<<<$body");

    if (response.statusCode == 200) {
      var msgdecode = jsonDecode(response.body);

      if (msgdecode["Result"] == "true") {
        msgotpData = msgotpModelFromJson(response.body);
        otpCode = msgotpData!.otp.toString();
        print("><<<<<<<<<<<<<<<<<<$otpCode");
        update();
        return msgdecode;
      } else {
        showToastMessage(msgdecode["ResponseMsg"]);
      }
    } else {
      showToastMessage("Something went wrong!");
    }
  }

  String twilloCode = "";
  Future twilloOtp(cuntryCode, number) async {
    final nb = ensureNoZeroInitial(number);

    Map body = {"mobile": cuntryCode + nb};

    var response = await http.post(Uri.parse(Config.path + Config.twillotp),
        body: jsonEncode(body),
        headers: {
          'Content-Type': 'application/json',
        });
    print("><<<<<<<<<<<<<<<<<<$body");

    if (response.statusCode == 200) {
      var msgdecode = jsonDecode(response.body);
      print(" OTP CODE : >>> ${response.body}");

      if (msgdecode["Result"] == "true") {
        update();
        showToastMessage(msgdecode["ResponseMsg"]);
        return msgdecode;
      } else {
        showToastMessage(msgdecode["ResponseMsg"]);
      }
    } else {
      showToastMessage("Something went wrong!");
    }
  }

  Future termiOtp(cuntryCode, number) async {
    final nb = ensureNoZeroInitial(number);
    Map body = {"mobile": cuntryCode + nb};

    var response = await http.post(Uri.parse(Config.path + Config.termiotp),
        body: jsonEncode(body),
        headers: {
          'Content-Type': 'application/json',
        });
    print("><<<<<<<<<<<<<<<<<<$body");

    if (response.statusCode == 200) {
      var msgdecode = jsonDecode(response.body);
      print(" OTP CODE : >>> ${response.body}");

      if (msgdecode["Result"] == "true") {
        update();
        showToastMessage(msgdecode["ResponseMsg"]);
        return msgdecode;
      } else {
        showToastMessage(msgdecode["ResponseMsg"]);
      }
    } else {
      showToastMessage("Something went wrong!");
    }
  }

  Future emailOtp(email) async {
    Map body = {"email": email};

    var response = await http.post(
        Uri.parse(Config.path + Config.sendEmailSmsApi),
        body: jsonEncode(body),
        headers: {
          'Content-Type': 'application/json',
        });
    print("><<<<<<<<<<<<<<<<<<$body");

    if (response.statusCode == 200) {
      var msgdecode = jsonDecode(response.body);
      print(" OTP EMAIL CODE : >>> ${response.body}");

      if (msgdecode["Result"] == "true") {
        update();
        showToastMessage(msgdecode["ResponseMsg"]);
        return msgdecode;
      } else {
        showToastMessage(msgdecode["ResponseMsg"]);
      }
    } else {
      showToastMessage("Something went wrong!");
    }
  }

  Future setUserApiData(String cuntryCode) async {
    final prefs = await SharedPreferences.getInstance();
    final nb = ensureNoZeroInitial(number.text);
    Map map = {
      "name": name.text,
      "email": email.text,
      "mobile": nb,
      "ccode": cuntryCode,
      "password": password.text,
      "accept_newsletter": newsletter ? "1" : "0",
    };
    log('-----------------------------------');
    // log(map.toString());
    log('-----------------------------------');

    Uri uri = Uri.parse(Config.path + Config.registerUser);
    var response = await http.post(
      uri,
      body: jsonEncode(map),
    );

    if (response.statusCode == 200) {
      var result = jsonDecode(response.body);
      if (result["Result"] == "true") {
        await prefs.setBool('Firstuser', true);
        signUpMsg = result["ResponseMsg"];
        showToastMessage(signUpMsg);
        save("UserLogin", result["UserLogin"]);
        firebaseNewuser();
        OneSignal.User.addTags({"user_id": getData.read("UserLogin")["id"]});
        update();
      }
    }
    print("${jsonDecode(response.body)}");
    return jsonDecode(response.body);
  }

  firebaseNewuser() async {
    AuthService authService = AuthService();
    // final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.singUpAndStore(
          proPicPath: getData.read("UserLogin")["pro_pic"],
          email: name.text,
          uid: getData.read("UserLogin")["id"]);
    } catch (e) {
      print(e);
    }
  }

  editProfileApi({String? name, String? email}) async {
    try {
      Map map = {
        "name": name,
        "uid": getData.read("UserLogin")["id"].toString(),
        "password": getData.read("UserLogin")["password"],
        "email": email,
      };

      Uri uri = Uri.parse(Config.path + Config.editProfileApi);

      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      print("jsonEncode(map)" + jsonEncode(map));
      print("uri" + uri.toString());
      if (response.statusCode == 200) {
        print("resulaat_________________" + response.body);
        var result = jsonDecode(response.body);
        print("result_________________" + jsonEncode(result));

        save("UserLogin", result["UserLogin"]);
        editProfile(getData.read("UserLogin")["id"], name ?? "");
      }

      Get.back();
      update();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<dynamic> socialRegisterInit({
    required String provider,
    required String token,
    required String mobile,
    required String ccode,
    String? email,
    String? name,
  }) async {
    final nb = ensureNoZeroInitial(mobile);
    try {
      Map map = {
        "provider": provider,
        "token": token,
        "mobile": nb,
        "ccode": ccode,
      };

      if (email != null && email.trim().isNotEmpty) {
        map["email"] = email.trim();
      }
      if (name != null && name.trim().isNotEmpty) {
        map["name"] = name.trim();
      }

      log(map.toString(), name: 'map ');

      Uri uri = Uri.parse(Config.path + Config.socialRegisterInit);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      log(uri.path.toString());
      log(response.body.toString());

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        return result;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("socialRegisterInit error: ${e.toString()}");
      return {
        "Result": "false",
        "ResponseMsg": "Something went wrong. Please try again."
      };
    }
  }

  Future<dynamic> finalizeSocialRegister({
    required String provider,
    required String token,
    required String mobile,
    required String ccode,
    required String name,
    String? email,
    required String refercode,
    required int acceptNewsletter,
    required int acceptPrivacyPolicy,
    required int acceptTermsCondition,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final nb = ensureNoZeroInitial(mobile);
    try {
      Map map = {
        "provider": provider,
        "token": token,
        "mobile": nb,
        "name": name,
        "ccode": ccode,
        "refercode": refercode,
        "accept_newsletter": acceptNewsletter,
        "accept_privacy_policy": acceptPrivacyPolicy,
        "accept_terms_condition": acceptTermsCondition,
      };

      if (email != null && email.trim().isNotEmpty) {
        map["email"] = email.trim();
      }
      // if (name.trim().isNotEmpty) {
      //   map["name"] = name.trim();
      // }

      log(map.toString(), name: 'map ');
      Uri uri = Uri.parse(Config.path + Config.socialRegister);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );

      log(uri.path.toString());
      log(response.body.toString());

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        if (result["Result"] == "true") {
          await prefs.setBool('Firstuser', true);
          signUpMsg = result["ResponseMsg"] ?? "Sign Up Done Successfully!";
          save("UserLogin", result["UserLogin"]);

          try {
            await firebaseNewuser();
          } catch (firebaseErr) {
            print("Firebase registration error: $firebaseErr");
          }

          OneSignal.User.addTags({"user_id": getData.read("UserLogin")["id"]});
          update();
        }
        return result;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("finalizeSocialRegister error: ${e.toString()}");
      return {
        "Result": "false",
        "ResponseMsg": "Something went wrong. Please try again."
      };
    }
  }
}
