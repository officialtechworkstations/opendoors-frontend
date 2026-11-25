import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:opendoors/utils/app_logger.dart';

class AuthService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> singInAndStoreData({
    required String email,
    required String uid,
    required String proPicPath,
  }) async {
    try {
      await _storeProfile(email: email, uid: uid, proPicPath: proPicPath);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Auth',
        'Firebase chat profile synchronization failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> singUpAndStore({
    required String email,
    required String uid,
    required String proPicPath,
  }) async {
    try {
      await _storeProfile(email: email, uid: uid, proPicPath: proPicPath);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Auth',
        'Firebase chat account creation failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _storeProfile({
    required String email,
    required String uid,
    required String proPicPath,
  }) async {
    final token = await _getPushToken();
    final profile = <String, dynamic>{
      "uid": uid,
      "name": email,
      "isOnline": false,
      "pro_pic": proPicPath,
    };
    if (token?.isNotEmpty == true) {
      profile["token"] = token;
    }
    await _firestore
        .collection("opendoors_users")
        .doc(uid)
        .set(profile, SetOptions(merge: true));
    AppLogger.debug(
      'Auth',
      'Firebase chat profile synchronized',
      data: {
        'user_id': uid,
        'has_push_token': token?.isNotEmpty == true,
      },
    );
  }

  Future<String?> _getPushToken() async {
    final messaging = FirebaseMessaging.instance;

    if (Platform.isIOS) {
      const attempts = 20;
      for (var attempt = 1; attempt <= attempts; attempt++) {
        final apnsToken = await messaging.getAPNSToken();
        if (apnsToken?.isNotEmpty == true) break;

        if (attempt == attempts) {
          AppLogger.warning(
            'Auth',
            'APNS token unavailable; chat profile will sync without a push token',
          );
          return null;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    return messaging.getToken();
  }
}
