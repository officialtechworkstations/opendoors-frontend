// ignore_for_file: unused_local_variable, avoid_print, prefer_interpolation_to_compose_strings

import 'dart:convert';
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
import 'package:opendoors/utils/app_logger.dart';
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
    } catch (error, stackTrace) {
      AppLogger.error('Profile', 'Image selection failed',
          error: error, stackTrace: stackTrace);
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
    Uri uri = Uri.parse(Config.path + Config.loginApi);
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Auth', 'Password login request started', data: {
      'country_code': cuntryCode,
      'has_mobile': numb.isNotEmpty,
    });
    var response = await http.post(
      uri,
      body: jsonEncode(map),
    );

    if (response.statusCode == 200) {
      await prefs.setBool('Firstuser', true);
      var result = jsonDecode(response.body);
      AppLogger.info('Auth', 'Password login response received', data: {
        'status': response.statusCode,
        'duration_ms': stopwatch.elapsedMilliseconds,
        'result': result['Result'],
        'response_code': result['ResponseCode'],
      });
      userMessage = result["ResponseMsg"];
      resultCheck = result["Result"];
      showToastMessage(userMessage);

      if (resultCheck == "true") {
        save("homeCall", true);
        save("UserLogin", result["UserLogin"]);
        await _saveAccessToken(result);
        save("userType", result["type"]);
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
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      AppLogger.debug('Auth', 'Firebase session synchronization started');
      await authService.singInAndStoreData(
          proPicPath: getData.read("UserLogin")["pro_pic"].toString(),
          email: email,
          uid: getData.read("UserLogin")["id"]);
    } catch (error, stackTrace) {
      AppLogger.error('Auth', 'Firebase session synchronization failed',
          error: error, stackTrace: stackTrace);
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

      isSending = true;
      update();

      Uri uri = Uri.parse(Config.path + Config.forgetPassword);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
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
    } catch (error, stackTrace) {
      AppLogger.error('Auth', 'Password reset request failed',
          error: error, stackTrace: stackTrace);
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
    } catch (error, stackTrace) {
      AppLogger.error('Profile', 'Profile image update failed',
          error: error, stackTrace: stackTrace);
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

        hasNewsletter.value =
            result["data"]?["accept_newsletter"] == "1" ? true : false;
      }
      update();
    } catch (error, stackTrace) {
      AppLogger.error('Profile', 'Profile fetch failed',
          error: error, stackTrace: stackTrace);
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

        final res = result?["accept_newsletter"] == 1 ? true : false;

        final mssg = res
            ? 'You have successfully subscribed to our newsletter.'
            : 'You have successfully unsubscribed from our newsletter.';

        switchNewsletter(res);

        showToastMessage(mssg, ToastGravity.TOP);
      }
      update();
    } catch (error, stackTrace) {
      AppLogger.error('Profile', 'Newsletter preference update failed',
          error: error, stackTrace: stackTrace);
    }
  }

  Future<dynamic> isUserOnlie(String uid, String proPic) async {
    CollectionReference collectionReference =
        FirebaseFirestore.instance.collection('opendoors_users');
    await collectionReference.doc(uid).set(
      {"uid": uid, "pro_pic": proPic},
      SetOptions(merge: true),
    );
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

      AppLogger.debug('Auth', 'Google sign-in credentials received', data: {
        'has_access_token': googleAuth.accessToken != null,
        'has_id_token': googleAuth.idToken != null,
      });

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

      AppLogger.debug('Auth', 'Google authentication completed', data: {
        'has_access_token': accessToken != null,
        'has_id_token': idToken != null,
        'provider': 'google',
      });

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

      AppLogger.debug('Auth', 'Apple credentials received', data: {
        'has_email': credential.email?.isNotEmpty == true,
        'has_given_name': credential.givenName?.isNotEmpty == true,
        'has_family_name': credential.familyName?.isNotEmpty == true,
      });

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
          AppLogger.debug('Auth', 'Caching Apple relay email');
          await prefs.setString("apple_email_$userId", cachedEmail);
        } else {
          cachedEmail = prefs.getString("apple_email_$userId");
          AppLogger.debug('Auth', 'Reading cached Apple relay email', data: {
            'email_found': cachedEmail?.isNotEmpty == true,
          });
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

    Uri uri = Uri.parse(Config.path + Config.socialLogin);
    AppLogger.info('Auth', 'Social login request started', data: {
      'url': uri.toString(),
      'provider': provider,
      'has_email': email?.isNotEmpty == true,
      'has_name': name?.isNotEmpty == true,
    });
    final stopwatch = Stopwatch()..start();
    var response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(map),
    );
    AppLogger.info('Auth', 'Social login response received', data: {
      'provider': provider,
      'status': response.statusCode,
      'duration_ms': stopwatch.elapsedMilliseconds,
    });

    if (response.statusCode == 200) {
      var result = jsonDecode(response.body);
      AppLogger.debug('Auth', 'Social login response parsed', data: {
        'provider': provider,
        'result': result['Result'],
        'response_code': result['ResponseCode'],
        'type': result['type'],
      });

      if (result["Result"] == "true") {
        await prefs.setBool('Firstuser', true);
        userMessage = result["ResponseMsg"] ?? "Login successfully!";
        resultCheck = result["Result"];

        save("homeCall", true);
        save("UserLogin", result["UserLogin"]);
        await _saveAccessToken(result);
        save("userType", result["type"]);

        OneSignal.User.addTags({"user_id": result["UserLogin"]["id"]});
        if (context.mounted) {
          setfirebaselogin(
            email: result["UserLogin"]["name"],
            context: context,
          );
        }
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

  Future<void> _saveAccessToken(Map<String, dynamic> result) async {
    final userLogin = result['UserLogin'];
    final nestedLogin = userLogin is Map ? userLogin : const {};
    final rawToken = result['access_token'] ??
        result['accessToken'] ??
        result['token'] ??
        result['jwt'] ??
        nestedLogin['access_token'] ??
        nestedLogin['accessToken'] ??
        nestedLogin['token'] ??
        nestedLogin['jwt'];
    final token = rawToken?.toString().trim();
    if (token == null || token.isEmpty || token == 'null') {
      AppLogger.warning(
        'Auth',
        'Login succeeded without an API access token',
        data: {
          'response_code': result['ResponseCode'],
          'available_fields': result.keys.toList(),
        },
      );
      await getData.remove('accessToken');
      await getData.remove('accessTokenExpiresAt');
      return;
    }

    final parsedExpiresIn = int.tryParse(
      (result['expires_in'] ??
                  result['expiresIn'] ??
                  nestedLogin['expires_in'] ??
                  nestedLogin['expiresIn'])
              ?.toString() ??
          '',
    );
    final expiresIn = parsedExpiresIn != null && parsedExpiresIn > 0
        ? parsedExpiresIn
        : 86400;
    final normalizedToken = token.toLowerCase().startsWith('bearer ')
        ? token.substring(7).trim()
        : token;
    await getData.write('accessToken', normalizedToken);
    await getData.write(
      'accessTokenExpiresAt',
      DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch,
    );
    AppLogger.info('Auth', 'API access token stored', data: {
      'expires_in_seconds': expiresIn,
      'token': normalizedToken,
    });
  }
}
