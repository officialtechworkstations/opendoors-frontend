// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables, deprecated_member_use

import 'dart:convert';
import 'dart:ui';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/controller/homepage_controller.dart';
import 'package:opendoors/firebase/chat_bubble.dart';
import 'package:opendoors/firebase/chat_filter_service.dart';
import 'package:opendoors/firebase/chat_service.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  final String resiverUserId;
  final String resiverUseremail;
  final String proPic;

  const ChatPage({
    super.key,
    required this.resiverUserId,
    required this.resiverUseremail,
    required this.proPic,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  HomePageController homePageController = Get.find();

  TextEditingController controller = TextEditingController();

  ChatServices chatservices = ChatServices();

  final ScrollController _controller =
      ScrollController(initialScrollOffset: 50.0);

  bool _showNotice = true; // true → banner is visible
  String chatNotice = "";

  void sendMessage() async {
    if (controller.text.isNotEmpty) {
      // filter message with contact details======================
      FilterResult result = ContactInfoFilter.filterMessage(controller.text);

      if (result.blocked) {
        // log("BLOCKED: ${result.blocked.toString()}");
        // log(result.reason.toString());
        // log(result.suggestion.toString());
        showToastMessage("${result.reason}\n\n ${result.suggestion}");
        return;
      }
      // filter message with contact details======================
    }

    CollectionReference collectionReference =
        FirebaseFirestore.instance.collection('opendoors_users');

    print("AFA <F ${widget.resiverUserId}");
    if (controller.text.isNotEmpty) {
      collectionReference.doc(widget.resiverUserId).get().then((value) async {
        var fields;

        print("FIELDS ${value.data()}");
        fields = value.data();

        if (fields["isOnline"] == false) {
          sendPushMessage(
              controller.text, getData.read("UserLogin")["name"], fmctoken);
        } else {
          print("user online");
        }

        await chatservices.sendMessage(
            receiverId: widget.resiverUserId, messeage: controller.text);

        controller.clear();

        _controller.jumpTo(_controller.position.maxScrollExtent);
      });
    }
  }

  String fmctoken = "";
  Future<dynamic> isMeassageAvalable(String uid) async {
    CollectionReference collectionReference =
        FirebaseFirestore.instance.collection('opendoors_users');
    collectionReference.doc(uid).get().then((value) {
      var fields;
      fields = value.data();
      print("TOKEN HERE ${fields["token"]}");
      setState(() {
        fmctoken = fields["token"];
        print("TOKEN ID > <> <> <> <> ${fmctoken}");
      });
    });
  }

  @override
  void initState() {
    super.initState();

    setNotice();
    isMeassageAvalable(widget.resiverUserId);

    if (getData.read("UserLogin")["id"] == null) {
    } else {
      isUserOnlie(getData.read("UserLogin")["id"], true);
    }
  }

  void setNotice() async {
    await homePageController.getChatNoApi().then((onValue) {
      // log(homePageController.chatNotice.toString());
      chatNotice = homePageController.chatNotice.toString();
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    isUserOnlie(getData.read("UserLogin")["id"], false);
  }

  void _scrollDown() {
    _controller.animateTo(_controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  late ColorNotifire notifire;
  @override
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    return Scaffold(
      backgroundColor: notifire.getbgcolor,
      appBar: appbar(),
      body: Column(
        children: [
          if (_showNotice) _buildWarningPopup(),
          Expanded(child: _buildMessageList()),
          _buildMessageInpurt(),
        ],
      ),
    );
  }

  PreferredSizeWidget appbar() {
    return AppBar(
      backgroundColor: notifire.getbgcolor,
      elevation: 0,
      leading: BackButton(
        color: notifire.getwhiteblackcolor,
        onPressed: () {
          Get.back();
        },
      ),
      title: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("opendoors_users")
              .doc(widget.resiverUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text(
                widget.resiverUseremail,
                style: TextStyle(
                  fontFamily: FontFamily.gilroyBold,
                  fontSize: 18,
                  color: notifire.getwhiteblackcolor,
                ),
              );
            } else {
              Map data = snapshot.data!.data() as Map<dynamic, dynamic>;
              return Row(
                children: [
                  widget.proPic == "null"
                      ? const CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: 20,
                          backgroundImage: AssetImage(
                            "assets/images/profile-default.png",
                          ))
                      : CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.transparent,
                          backgroundImage: NetworkImage(
                              "${Config.imageUrl}${widget.proPic}")),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.resiverUseremail,
                        style: TextStyle(
                          fontFamily: FontFamily.gilroyBold,
                          fontSize: 18,
                          color: notifire.getwhiteblackcolor,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      data["isOnline"] == false
                          ? const SizedBox()
                          : Text(
                              "Online",
                              style: TextStyle(
                                fontSize: 10,
                                color: notifire.getwhiteblackcolor,
                                fontFamily: FontFamily.gilroyLight,
                              ),
                            ),
                    ],
                  ),
                ],
              );
            }
          }),
    );
  }

  Widget _buildWarningPopup() {
    return Padding(
      // push it down a little from the app-bar
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
      child: Stack(
        children: [
          // glass card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FE), // new card colour
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.campaign_outlined,
                        color: Color(0xFF1E2329), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        chatNotice.isNotEmpty
                            ? chatNotice
                            : 'Important: Keep all communication & bookings inside the app. '
                                'Sharing personal contact details is not allowed.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF1E2329),
                              fontSize: 13.5,
                              height: 1.3,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // floating close button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _showNotice = false),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFD0D9F0), // new close-button colour
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.close, size: 16, color: Color(0xFF1E2329)),
              ),
            ),
          )
        ],
      ),
    );
    // --------------------------------------
  }

  Widget _buildMessageList() {
    return StreamBuilder(
        stream: chatservices.getMessage(
            userId: widget.resiverUserId,
            otherUserId: getData.read("UserLogin")["id"]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error${snapshot.error}");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return ListView(
              controller: _controller,
              children: snapshot.data!.docs
                  .map((document) => _buildMessageiteam(document))
                  .toList(),
            );
          }
        });
  }

  Widget _buildMessageiteam(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollDown();
    });
    var alingmentt = (data["senderid"] == getData.read("UserLogin")["id"])
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      alignment: alingmentt,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment:
              (data["senderid"] == getData.read("UserLogin")["id"])
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            ChatBubble(
              chatColor: (data["senderid"] == getData.read("UserLogin")["id"])
                  ? blueColor
                  : Colors.grey.shade100,
              textColor: (data["senderid"] == getData.read("UserLogin")["id"])
                  ? WhiteColor
                  : Colors.black,
              message: data["message"],
              alingment: (data["senderid"] == getData.read("UserLogin")["id"])
                  ? false
                  : true,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
                DateFormat('hh:mm a')
                    .format(DateTime.fromMicrosecondsSinceEpoch(
                        data["timestamp"].microsecondsSinceEpoch))
                    .toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: notifire.getwhiteblackcolor,
                  fontFamily: FontFamily.gilroyLight,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInpurt() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontSize: 16,
                color: notifire.getwhiteblackcolor,
                fontFamily: FontFamily.gilroyMedium,
              ),
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  suffixIcon: IconButton(
                      onPressed: sendMessage,
                      icon: Icon(
                        Icons.send,
                        color: notifire.getwhiteblackcolor,
                      )),
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: notifire.getwhiteblackcolor,
                    fontFamily: FontFamily.gilroyMedium,
                  ),
                  hintText: "Say Something..",
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: notifire.getborderColor),
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: notifire.getborderColor),
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: notifire.getborderColor),
                      borderRadius: BorderRadius.circular(12)),
                  disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: notifire.getborderColor),
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  void sendPushMessage(String body, String title, String token) async {
    final dio = Dio();

    print("++++send meshj++++:--  ${Config.firebaseKey}");
    try {
      final response = await dio.post(
        'https://fcm.googleapis.com/v1/projects/${Config.projectID}/messages:send',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${Config.firebaseKey}',
          },
        ),
        data: jsonEncode({
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': getData.read("UserLogin")["id"],
              'name': getData.read("UserLogin")["name"],
              'propic': getData.read("UserLogin")["pro_pic"],
              'status': 'done'
            },
          }
        }),
      );

      if (response.statusCode == 200) {
        print('done');
      } else {
        print('Failed to send push notification: ${response.data}');
      }
    } catch (e) {
      print("Error push notificatioDDn: $e");
    }
  }
}

void requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  // log(messaging.toString());

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }
}

Future<dynamic> isUserOnlie(String uid, bool isonline) async {
  // CollectionReference collectionReference =
  //     FirebaseFirestore.instance.collection('opendoors_users');
  // collectionReference.doc(uid).update({"isOnline": isonline});
}
