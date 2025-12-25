// ignore_for_file: avoid_print

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  singInAndStoreData(
      {required String email,
      required String uid,
      required String proPicPath}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseMessaging.instance.getToken().then((token) {
        print("TOKEN  NO $token");
        log("TOKEN  NO $token");
        _firestore.collection("opendoors_users").doc(uid).set({
          "uid": uid,
          "name": email,
          "token": "$token",
          "isOnline": false,
          "pro_pic": proPicPath
        });
      });
    } catch (e) {
      print("+++++++ FirebaseAuthException +++++ $e");
    }
  }

  singUpAndStore(
      {required String email, required String uid, required proPicPath}) async {
    try {
      await FirebaseMessaging.instance.getToken().then((token) {
        _firestore.collection("opendoors_users").doc(uid).set({
          "uid": uid,
          "name": email,
          "token": "$token",
          "isOnline": false,
          "pro_pic": proPicPath
        }, SetOptions(merge: true));
      });
    } catch (e) {
      print("+++++++ FirebaseAuthException +++++ $e");
    }
  }
}
