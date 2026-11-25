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
  String challengeId = "";

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
    try {
      var response = await http.get(
        Uri.parse(Config.path + Config.smstype),
        headers: {'Content-Type': 'application/json'},
      );

      print('=======================smstype======================');
      print(response.body.toString());
      print('=======================smstype======================');

      if (response.statusCode == 200) {
        var smsdecode = jsonDecode(response.body);
        update();
        print(response.body.toString());
        print(
          " SMS CODE TYPE >>>>>>>>>>>>>> : : : : : :${smsdecode["SMS_TYPE"]}",
        );
        return smsdecode;
      }
    } catch (e) {
      print("smstype error: $e");
    }
    return null;
  }

  ensureNoZeroInitial(String number) {
    String localNumber = number.trim();
    if (localNumber.startsWith('+')) {
      localNumber = localNumber.substring(1);
    }
    if (localNumber.startsWith('234')) {
      localNumber = localNumber.substring(3);
    }
    if (localNumber.startsWith('0')) {
      localNumber = localNumber.substring(1);
    }
    return localNumber;
  }

  Future checkMobileNumber(String cuntryCode) async {
    print(cuntryCode);

    try {
      final nb = ensureNoZeroInitial(number.text);

      Map map = {"mobile": nb, "ccode": cuntryCode};
      Uri uri = Uri.parse(Config.path + Config.mobileChack);
      var response = await http.post(uri, body: jsonEncode(map));

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

  Future checkMobileInResetPassword({
    String? number,
    String? cuntryCode,
  }) async {
    log('-----------------');
    log('number : $number');
    log('cuntryCode : $cuntryCode');
    log('-----------------');

    final nb = ensureNoZeroInitial(number ?? '');
    try {
      Map map = {"mobile": nb, "ccode": cuntryCode};
      Uri uri = Uri.parse(Config.path + Config.mobileChack);
      var response = await http.post(uri, body: jsonEncode(map));

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
  Future sendOtp(cuntryCode, number) async {
    final nb = ensureNoZeroInitial(number);
    Map body = {"mobile": nb, "ccode": cuntryCode};

    var response = await http.post(
      Uri.parse(Config.path + Config.msgotp),
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
    print("><<<<<<<<<<<<<<<<<<$body");

    if (response.statusCode == 200) {
      var msgdecode = jsonDecode(response.body);

      if (msgdecode["Result"] == "true") {
        msgotpData = msgotpModelFromJson(response.body);
        challengeId = msgotpData?.challengeId?.toString() ?? "";
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

    Map body = {"mobile": nb, "ccode": cuntryCode};

    var response = await http.post(
      Uri.parse(Config.path + Config.twillotp),
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
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
    Map body = {"mobile": nb, "ccode": cuntryCode};

    var response = await http.post(
      Uri.parse(Config.path + Config.termiotp),
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
    print("><<<<<<<<<<<<<<<<<<$body");

    try {
      var msgdecode = jsonDecode(response.body);
      print(" OTP CODE : >>> ${response.body}");

      if (response.statusCode == 200 && msgdecode["Result"] == "true") {
        challengeId = msgdecode["challenge_id"]?.toString() ?? "";
        update();
        showToastMessage(msgdecode["ResponseMsg"]);
      }
      return msgdecode;
    } catch (_) {
      return {
        "Result": "false",
        "ResponseCode": response.statusCode.toString(),
        "ResponseMsg": "Unable to send OTP. Please try again.",
      };
    }
  }

  Future emailOtp(email) async {
    Map body = {"email": email};

    var response = await http.post(
      Uri.parse(Config.path + Config.sendEmailSmsApi),
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
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

  Future setUserApiData(
    String cuntryCode, {
    required String challengeId,
    required String otp,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nb = ensureNoZeroInitial(number.text);
      Map map = {
        "name": name.text,
        "email": email.text,
        "mobile": nb,
        "ccode": cuntryCode,
        "password": password.text,
        "challenge_id": challengeId,
        "otp": otp,
        "refercode": referralCode.text,
        "accept_newsletter": newsletter ? 1 : 0,
        "accept_privacy_policy": chack ? 1 : 0,
        "accept_terms_condition": chack ? 1 : 0,
      };
      log('-----------------------------------');
      log('-----------------------------------');

      Uri uri = Uri.parse(Config.path + Config.registerUser);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
        headers: {'Content-Type': 'application/json'},
      );

      try {
        var result = jsonDecode(response.body);
        if (response.statusCode == 200 && result["Result"] == "true") {
          await prefs.setBool('Firstuser', true);
          signUpMsg = result["ResponseMsg"];
          showToastMessage(signUpMsg);
          save("UserLogin", result["UserLogin"]);
          final accessToken = result['access_token']?.toString();
          if (accessToken != null && accessToken.isNotEmpty) {
            final expiresIn =
                int.tryParse(result['expires_in']?.toString() ?? '') ?? 86400;
            save('accessToken', accessToken);
            save(
              'accessTokenExpiresAt',
              DateTime.now()
                  .add(Duration(seconds: expiresIn))
                  .millisecondsSinceEpoch,
            );
          }
          firebaseNewuser();
          OneSignal.User.addTags({"user_id": getData.read("UserLogin")["id"]});
          update();
        }
        return result;
      } catch (_) {
        return {
          "Result": "false",
          "ResponseCode": response.statusCode.toString(),
          "ResponseMsg":
              "Unable to sign up (HTTP ${response.statusCode}). Please try again.",
        };
      }
    } catch (e) {
      print("setUserApiData error: $e");
      return {
        "Result": "false",
        "ResponseMsg": "Unable to sign up. Please try again.",
      };
    }
  }

  firebaseNewuser() async {
    AuthService authService = AuthService();
    // final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.singUpAndStore(
        proPicPath: getData.read("UserLogin")["pro_pic"],
        email: name.text,
        uid: getData.read("UserLogin")["id"],
      );
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

      var response = await http.post(uri, body: jsonEncode(map));
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

      log(
        {
          "provider": provider,
          "has_email": email?.trim().isNotEmpty == true,
          "has_name": name?.trim().isNotEmpty == true,
          "mobile_length": nb.length,
        }.toString(),
        name: "Social register init request",
      );

      Uri uri = Uri.parse(Config.path + Config.socialRegisterInit);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
        headers: {'Content-Type': 'application/json'},
      );
      final result = jsonDecode(response.body);
      log(
        {
          "status": response.statusCode,
          "result": result["Result"],
          "response_code": result["ResponseCode"],
        }.toString(),
        name: "Social register init response",
      );
      if (result["Result"] == "true") {
        challengeId = result["challenge_id"]?.toString() ?? "";
        update();
      }
      return result;
    } catch (e) {
      print("socialRegisterInit error: ${e.toString()}");
      return {
        "Result": "false",
        "ResponseMsg": "Something went wrong. Please try again.",
      };
    }
  }

  Future<dynamic> finalizeSocialRegister({
    required String provider,
    required String token,
    required String mobile,
    required String ccode,
    required String challengeId,
    required String otp,
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
        "challenge_id": challengeId,
        "otp": otp,
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

      log(
        {
          "provider": provider,
          "has_email": email?.trim().isNotEmpty == true,
          "has_name": name.trim().isNotEmpty,
          "mobile_length": nb.length,
        }.toString(),
        name: "Social register request",
      );
      Uri uri = Uri.parse(Config.path + Config.socialRegister);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
        headers: {'Content-Type': 'application/json'},
      );

      final result = jsonDecode(response.body);
      log(
        {
          "status": response.statusCode,
          "result": result["Result"],
          "response_code": result["ResponseCode"],
        }.toString(),
        name: "Social register response",
      );

      if (response.statusCode == 200) {
        if (result["Result"] == "true") {
          await prefs.setBool('Firstuser', true);
          signUpMsg = result["ResponseMsg"] ?? "Sign Up Done Successfully!";
          save("UserLogin", result["UserLogin"]);
          final accessToken = result["access_token"]?.toString();
          if (accessToken != null && accessToken.isNotEmpty) {
            final expiresIn =
                int.tryParse(result["expires_in"]?.toString() ?? "") ?? 86400;
            save("accessToken", accessToken);
            save(
              "accessTokenExpiresAt",
              DateTime.now()
                  .add(Duration(seconds: expiresIn))
                  .millisecondsSinceEpoch,
            );
          }

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

      return result;
    } catch (e) {
      print("finalizeSocialRegister error: ${e.toString()}");
      return {
        "Result": "false",
        "ResponseMsg": "Something went wrong. Please try again.",
      };
    }
  }
}
