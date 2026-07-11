import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/firebase/message.dart';

class ChatServices extends ChangeNotifier {
  final FirebaseFirestore _firebaseStorage = FirebaseFirestore.instance;

  String _normalizeId(dynamic id) => id?.toString() ?? "";

  String _chatRoomId(String userId, String otherUserId) {
    final ids = [_normalizeId(userId), _normalizeId(otherUserId)];
    ids.sort((a, b) => a.compareTo(b));
    return ids.join("_");
  }

  Future<void> sendMessage(
      {required String receiverId, required String messeage}) async {
    final String currentUserId = _normalizeId(getData.read("UserLogin")["id"]);
    final String currentUserName =
        getData.read("UserLogin")["name"]?.toString() ?? "";
    final String normalizedReceiverId = _normalizeId(receiverId);
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
        senderId: currentUserId,
        senderName: currentUserName,
        reciverId: normalizedReceiverId,
        message: messeage,
        timestamp: timestamp);

    String chatRoomId = _chatRoomId(currentUserId, normalizedReceiverId);

    // Write room-level metadata so that opendoors_chats can be queried by
    // participants. IMPORTANT: your Firestore security rules must allow writes
    // to opendoors_chats/{roomId} (not only to the message sub-collection).
    // If this write fails, the chat list will not show this conversation.
    try {
      await _firebaseStorage.collection("opendoors_chats").doc(chatRoomId).set({
        "participants": [currentUserId, normalizedReceiverId],
        "lastMessage": messeage,
        "lastMessageSenderId": currentUserId,
        "lastTimestamp": timestamp,
      }, SetOptions(merge: true));
    } catch (e) {
      log("ChatServices.sendMessage: room metadata write failed → $e\n"
          "Check Firestore rules: opendoors_chats/{roomId} must be writable.");
    }

    await _firebaseStorage
        .collection("opendoors_chats")
        .doc(chatRoomId)
        .collection("message")
        .add(newMessage.toMap());
  }

  Stream<QuerySnapshot> getMessage(
      {required String userId, required String otherUserId}) {
    String chatRoomId = _chatRoomId(userId, otherUserId);

    // log("chatRoomID $chatRoomId");
    return _firebaseStorage
        .collection("opendoors_chats")
        .doc(chatRoomId)
        .collection("message")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }
}
