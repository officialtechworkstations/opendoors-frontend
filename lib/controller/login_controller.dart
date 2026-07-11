// ignore_for_file: unused_local_variable, avoid_print, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/controller/selectcountry_controller.dart';
import 'package:opendoors/firebase/auth_service.dart';
import 'package:opendoors/model/routes_helper.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../screen/home_screen.dart';

class SocialAuthResult {
  SocialAuthResult({
    required this.provider,
    required this.token,
    this.email,
    this.name,
  });

  final String provider;
  final String token;
  final String? email;
  final String? name;
}

class LoginController extends GetxController implements GetxService {
  TextEditingController number = TextEditingController();
  TextEditingController password = TextEditingController();

  TextEditingController newPassword = TextEditingController();
  TextEditingController newConformPassword = TextEditingController();

  ImagePicker picker = ImagePicker();
  File? pickedImage;

  bool showPassword = true;
  bool newShowPassword = true;
  bool conformPassword = true;
  bool isChecked = false;

  String userMessage = "";
  String resultCheck = "";

  String forgetPasswprdResult = "";
  String forgetMsg = "";

  bool isSending = false;

// observable variables
  Rx<bool> hasNewsletter = false.obs;

  SelectCountryController selectCountryController =
      Get.put(SelectCountryController());

  switchNewsletter(bool value) {
    hasNewsletter.value = value;
    update();
  }

  showOfPassword() {
    showPassword = !showPassword;
    update();
  }

  newShowOfPassword() {
    newShowPassword = !newShowPassword;
    update();
  }

  newConformShowOfPassword() {
    conformPassword = !conformPassword;
    update();
  }

  changeRememberMe(bool? value) {
    isChecked = value ?? false;
    update();
  }

  pickImage(ImageSource imageType) async {
    try {
      final photo = await ImagePicker().pickImage(source: imageType);
      if (photo == null) return;
      final tempImage = File(photo.path);
      pickedImage = tempImage;
      update();
      Get.back();
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  ensureNoZeroInitial(String number) {
    String localNumber = number.trim();
    if (localNumber.startsWith('0')) {
      localNumber = localNumber.substring(1);
    }
    return localNumber;
  }

  Future getLoginApiData(String cuntryCode, context) async {
    final prefs = await SharedPreferences.getInstance();
    final numb = ensureNoZeroInitial(number.text);
    Map map = {
      "mobile": numb,
      "ccode": cuntryCode,
      "password": password.text,
    };
    log(map.toString());
    Uri uri = Uri.parse(Config.path + Config.loginApi);
    var response = await http.post(
      uri,
      body: jsonEncode(map),
    );

    if (response.statusCode == 200) {
      await prefs.setBool('Firstuser', true);
      log(response.body.toString());
      var result = jsonDecode(response.body);
      print(result.toString());
      userMessage = result["ResponseMsg"];
      resultCheck = result["Result"];
      showToastMessage(userMessage);

      if (resultCheck == "true") {
        save("homeCall", true);
        save("UserLogin", result["UserLogin"]);
        save("userType", result["type"]);
        print("LOGIMN DARTAT $result");
        OneSignal.User.addTags({"user_id": getData.read("UserLogin")["id"]});
        setfirebaselogin(email: result["UserLogin"]["name"], context: context);
        save("currency", result["currency"]);
        currency = result["currency"];
        isChecked = false;
        update();
        return result;
      }
      update();
      showToastMessage(result["ResponseMsg"]);
      return result;
    }
    return jsonDecode(response.body);
  }

  void setfirebaselogin({context, required String email}) async {
    print("SingupWith email firbase");
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      print("ERROR DATATA $email");
      await authService.singInAndStoreData(
          proPicPath: getData.read("UserLogin")["pro_pic"].toString(),
          email: email,
          uid: getData.read("UserLogin")["id"]);
    } catch (e) {
      print("ERROR DATATA $e");
    }
  }

  setForgetPasswordApi({
    String? mobile,
    String? ccode,
    // String? email,
  }) async {
    final numb = ensureNoZeroInitial(mobile ?? '');
    try {
      Map map = {
        "mobile": numb,
        "ccode": ccode,
        "password": newPassword.text,
        // "email": email,
      };
      // log(map.toString());

      isSending = true;
      update();

      Uri uri = Uri.parse(Config.path + Config.forgetPassword);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      // log(response.body.toString());
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        forgetPasswprdResult = result["Result"];
        forgetMsg = result["ResponseMsg"];
        if (forgetPasswprdResult == "true") {
          save('isLoginBack', false);
          Get.toNamed(Routes.login);
          showToastMessage(forgetMsg, ToastGravity.TOP);
        } else {
          showToastMessage(forgetMsg, ToastGravity.TOP);
        }

        isSending = false;
        update();
      }
    } catch (e) {
      print(e.toString());
      isSending = false;
      update();
    }
  }

  updateProfileImage(String? base64image) async {
    try {
      Map map = {
        "uid": getData.read("UserLogin")["id"].toString(),
        "img": base64image,
      };
      Uri uri = Uri.parse(Config.path + Config.updateProfilePic);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        save("UserLogin", result["UserLogin"]);
        isUserOnlie(getData.read("UserLogin")["id"],
            getData.read("UserLogin")["pro_pic"]);
      }
      update();
    } catch (e) {
      print(e.toString());
    }
  }

  fetchProfileData() async {
    try {
      Map map = {
        "uid": getData.read("UserLogin")["id"].toString(),
      };
      Uri uri = Uri.parse(Config.path + Config.fetchUserData);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);

        // log("FETCH PROFILE DATA ${result.toString()}");
        // log("${result["data"]?["accept_newsletter"].runtimeType.toString()}");

        hasNewsletter.value =
            result["data"]?["accept_newsletter"] == "1" ? true : false;
      }
      update();
    } catch (e) {
      print(e.toString());
    }
  }

  toggleProfileData() async {
    try {
      Map map = {
        "uid": getData.read("UserLogin")["id"].toString(),
      };
      Uri uri = Uri.parse(Config.path + Config.toggleNewsletter);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);

        // log("FETCH PROFILE newsletter toggle ${result.toString()}");
        // log("${result?["accept_newsletter"].runtimeType.toString()}");

        final res = result?["accept_newsletter"] == 1 ? true : false;

        final mssg = res
            ? 'You have successfully subscribed to our newsletter.'
            : 'You have successfully unsubscribed from our newsletter.';

        // log("newsletter toggle ${res.toString()}");
        switchNewsletter(res);

        showToastMessage(mssg, ToastGravity.TOP);
      }
      update();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<dynamic> isUserOnlie(String uid, String proPic) async {
    CollectionReference collectionReference =
        FirebaseFirestore.instance.collection('opendoors_users');
    collectionReference.doc(uid).update({"pro_pic": proPic});
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Pass Web Client ID so the idToken is verifiable by your backend
    serverClientId:
        '26275977783-9ngelo1c172lk6egli2dcm96j0nnspd2.apps.googleusercontent.com',
  );

  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;

      log(googleAuth.toString());

      final json = {
        'accessToken': googleAuth.accessToken,
        'idToken': googleAuth.idToken,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'id': googleUser.id,
      };

      // This is what you send to your backend
      final idToken = googleAuth.idToken;

      return idToken;
    } catch (e) {
      rethrow;
    }
  }

  Future<SocialAuthResult?> signUpWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      // await Future.delayed(const Duration(milliseconds: 100)); // Small delay
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      log('=== GOOGLE AUTH DEBUG ===');
      log('accessToken is null: ${accessToken == null}');
      log('idToken is null: ${idToken == null}');
      if (idToken != null) {
        log('idToken (first 80): ${idToken.substring(0, idToken.length > 80 ? 80 : idToken.length)}...');
        log('FULL ID TOKEN (copy this for verification):');
        print(idToken);
      } else {
        log('WARNING: idToken is NULL — serverClientId may not be registered in Google Cloud Console');
      }
      log('=== GOOGLE AUTH DEBUG END ===');

      if (idToken == null || idToken.isEmpty) {
        showToastMessage(
            "Unable to authenticate with Google. Please try again.");
        return null;
      }

      return SocialAuthResult(
        provider: "google",
        token: idToken,
        email: googleUser.email,
        name: googleUser.displayName,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Save immediately — only available on first sign in
      final email = credential.email;
      final givenName = credential.givenName;
      final familyName = credential.familyName;

      // Send this to your backend
      final identityToken = credential.identityToken;

      return identityToken;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  Future<SocialAuthResult?> signUpWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        showToastMessage("Unable to authenticate with Apple");
        return null;
      }

      log('=== APPLE AUTH DEBUG ===');
      log(credential.toString());
      log(credential.email.toString());
      log(credential.givenName.toString());
      log(credential.familyName.toString());

      final appleName = [
        credential.givenName,
        credential.familyName,
      ].where((name) => name != null && name.trim().isNotEmpty).join(" ");

      final prefs = await SharedPreferences.getInstance();
      String? cachedEmail = credential.email;
      String? cachedName = appleName.isEmpty ? null : appleName;

      final userId = credential.userIdentifier;
      if (userId != null) {
        if (cachedEmail != null && cachedEmail.isNotEmpty) {
          log('=== APPLE AUTH DEBUG ===');
          log('Caching email for user $userId: $cachedEmail');
          await prefs.setString("apple_email_$userId", cachedEmail);
        } else {
          cachedEmail = prefs.getString("apple_email_$userId");
          log('=== APPLE AUTH DEBUG ===');
          log('Retrieved cached email for user $userId: $cachedEmail');
        }

        if (cachedName != null && cachedName.isNotEmpty) {
          await prefs.setString("apple_name_$userId", cachedName);
        } else {
          cachedName = prefs.getString("apple_name_$userId");
        }
      }

      return SocialAuthResult(
        provider: "apple",
        token: identityToken,
        email: cachedEmail,
        name: cachedName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  Future<dynamic> loginWithSocial(
      String provider, String token, BuildContext context,
      {String? email, String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    Map map = {
      "provider": provider,
      "token": token,
    };
    if (email != null && email.isNotEmpty && provider == "apple") {
      map["email"] = email;
    }
    if (name != null && name.isNotEmpty && provider == "apple") {
      map["name"] = name;
    }

    log(map.toString());

    Uri uri = Uri.parse(Config.path + Config.socialLogin);
    log('=== SOCIAL LOGIN REQUEST ===');
    log('URL: $uri');
    log('provider: $provider');
    log('token length: ${token.length}');
    log('token (first 80): ${token.substring(0, token.length > 80 ? 80 : token.length)}...');
    log('FULL TOKEN SUBMITTED:');
    print(token);
    log('=== SOCIAL LOGIN REQUEST END ===');
    var response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(map),
    );
    log('=== SOCIAL LOGIN RAW RESPONSE ===');
    log('HTTP status: ${response.statusCode}');
    log('Body: ${response.body}');
    log('=== SOCIAL LOGIN RAW RESPONSE END ===');

    if (response.statusCode == 200) {
      var result = jsonDecode(response.body);
      print("SOCIAL LOGIN RESPONSE: $result");

      if (result["Result"] == "true") {
        await prefs.setBool('Firstuser', true);
        userMessage = result["ResponseMsg"] ?? "Login successfully!";
        resultCheck = result["Result"];

        save("homeCall", true);
        save("UserLogin", result["UserLogin"]);
        save("userType", result["type"]);

        OneSignal.User.addTags({"user_id": result["UserLogin"]["id"]});
        setfirebaselogin(email: result["UserLogin"]["name"], context: context);
        save("currency", result["currency"]);
        currency = result["currency"];
        isChecked = false;
        update();
      }
      return result;
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      return {
        "Result": "false",
        "ResponseCode": response.statusCode.toString(),
        "ResponseMsg": "Server error. Please try again."
      };
    }
  }
}
