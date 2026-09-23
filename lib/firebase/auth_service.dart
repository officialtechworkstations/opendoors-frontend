import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:opendoors/utils/app_logger.dart';

class AuthService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  singInAndStoreData(
      {required String email,
      required String uid,
      required String proPicPath}) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      await _firestore.collection("opendoors_users").doc(uid).set({
        "uid": uid,
        "name": email,
        "token": token ?? "",
        "isOnline": false,
        "pro_pic": proPicPath
      }, SetOptions(merge: true));
      AppLogger.debug('Auth', 'Firebase chat profile synchronized', data: {
        'user_id': uid,
        'has_push_token': token?.isNotEmpty == true,
      });
    } catch (error, stackTrace) {
      AppLogger.error('Auth', 'Firebase chat profile synchronization failed',
          error: error, stackTrace: stackTrace);
    }
  }

  singUpAndStore(
      {required String email, required String uid, required proPicPath}) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      await _firestore.collection("opendoors_users").doc(uid).set({
        "uid": uid,
        "name": email,
        "token": token ?? "",
        "isOnline": false,
        "pro_pic": proPicPath
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      AppLogger.error('Auth', 'Firebase chat account creation failed',
          error: error, stackTrace: stackTrace);
    }
  }
}
