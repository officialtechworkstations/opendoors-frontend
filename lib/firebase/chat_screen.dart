// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
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
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  final String resiverUserId;
  final String resiverUseremail;
  final String proPic;
  final String? propertyImage;
  final String? propertyTitle;
  final String? propertyAddress;
  final String? propertyMessage;

  const ChatPage({
    super.key,
    required this.resiverUserId,
    required this.resiverUseremail,
    required this.proPic,
    this.propertyImage,
    this.propertyTitle,
    this.propertyAddress,
    this.propertyMessage,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  HomePageController homePageController = Get.find();

  TextEditingController controller = TextEditingController();

  ChatServices chatservices = ChatServices();

  final ScrollController _controller = ScrollController();
  int _lastMessageCount = 0;

  static const Duration _noticeDisplayDuration = Duration(minutes: 5);

  bool _showNotice = false;
  String chatNotice = "";
  Timer? _noticeTimer;

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

        if (fields != null && fields["isOnline"] == false) {
          sendPushMessage(
              controller.text, getData.read("UserLogin")["name"], fmctoken);
        } else {
          print("user online");
        }

        await chatservices.sendMessage(
            receiverId: widget.resiverUserId, messeage: controller.text);

        controller.clear();
        _scrollToBottom(animated: true);
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
      print("TOKEN HERE ${fields?["token"]}");
      if (!mounted) {
        return;
      }
      setState(() {
        fmctoken = fields?["token"]?.toString() ?? "";
        print("TOKEN ID > <> <> <> <> ${fmctoken}");
      });
    });
  }

  void _sendInitialPropertyMessage() async {
    final String currentUserId = getData.read("UserLogin")["id"].toString();
    final ids = [currentUserId, widget.resiverUserId];
    ids.sort((a, b) => a.compareTo(b));
    final chatRoomId = ids.join("_");

    final title = widget.propertyTitle!;
    final image = widget.propertyImage!;
    final address = widget.propertyAddress ?? "";
    final info = (widget.propertyMessage != null &&
            widget.propertyMessage!.isNotEmpty)
        ? widget.propertyMessage!
        : "please provide me more details on this property. I am interested!"
            .tr;

    final messageJson = jsonEncode({
      "type": "property",
      "image": image,
      "title": title,
      "address": address,
      "message": info,
    });

    final snapshot = await FirebaseFirestore.instance
        .collection("opendoors_chats")
        .doc(chatRoomId)
        .collection("message")
        .orderBy("timestamp", descending: true)
        .limit(1)
        .get();

    bool alreadySent = false;
    if (snapshot.docs.isNotEmpty) {
      final lastMsg = snapshot.docs.first.data() as Map<String, dynamic>?;
      final msgText = lastMsg?['message']?.toString() ?? '';
      if (msgText.contains(title) && msgText.contains("property")) {
        alreadySent = false; // intentionally set to false for now
      }
    }

    if (!alreadySent) {
      FirebaseFirestore.instance
          .collection('opendoors_users')
          .doc(widget.resiverUserId)
          .get()
          .then((value) async {
        final fields = value.data();
        if (fields != null && fields["isOnline"] == false) {
          final token = fields["token"]?.toString() ?? "";
          if (token.isNotEmpty) {
            sendPushMessage("Property inquiry: $title",
                getData.read("UserLogin")["name"], token);
          }
        }
        await chatservices.sendMessage(
            receiverId: widget.resiverUserId, messeage: messageJson);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    setNotice();
    _setDailyNoticeVisibility();
    isMeassageAvalable(widget.resiverUserId);

    if (getData.read("UserLogin")["id"] == null) {
    } else {
      isUserOnlie(getData.read("UserLogin")["id"], true);
    }

    if (widget.propertyTitle != null && widget.propertyImage != null) {
      _sendInitialPropertyMessage();
    }
  }

  void setNotice() async {
    await homePageController.getChatNoApi().then((onValue) {
      // log(homePageController.chatNotice.toString());
      chatNotice = homePageController.chatNotice.toString();
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _setDailyNoticeVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = getData.read("UserLogin")["id"].toString();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key =
        "chat_notice_seen_${currentUserId}_${widget.resiverUserId}_$today";

    if (prefs.getBool(key) == true) {
      return;
    }

    await prefs.setBool(key, true);

    if (!mounted) {
      return;
    }

    setState(() {
      _showNotice = true;
    });
    _noticeTimer?.cancel();
    _noticeTimer = Timer(_noticeDisplayDuration, () {
      if (mounted) {
        setState(() {
          _showNotice = false;
        });
      }
    });
  }

  void _hideNotice() {
    _noticeTimer?.cancel();
    setState(() {
      _showNotice = false;
    });
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    isUserOnlie(getData.read("UserLogin")["id"], false);
    super.dispose();
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_controller.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients || !mounted) return;

      final maxScrollExtent = _controller.position.maxScrollExtent;
      if (maxScrollExtent <= 0) return;

      if (animated) {
        _controller.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _controller.jumpTo(0.0);
      }
    });
  }

  late ColorNotifire notifire;
  @override
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: notifire.getbgcolor,
      appBar: appbar(),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            if (_showNotice) _buildWarningPopup(),
            Expanded(child: _buildMessageList()),
            AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: _buildMessageInpurt(),
            ),
          ],
        ),
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
            if (snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData ||
                snapshot.data!.data() == null) {
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
              onTap: _hideNotice,
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
          }
          final docs = snapshot.data!.docs;
          if (docs.isNotEmpty &&
              (_lastMessageCount == 0 || docs.length != _lastMessageCount)) {
            _lastMessageCount = docs.length;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !_controller.hasClients) return;
              final position = _controller.position;
              final shouldFollow = position.pixels <= 24 || position.atEdge;
              if (shouldFollow) {
                _scrollToBottom(animated: _lastMessageCount > 1);
              }
            });
          }
          return RawScrollbar(
            controller: _controller,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 6,
            trackColor: Colors.transparent,
            thumbColor: Colors.transparent,
            radius: const Radius.circular(8),
            child: ListView.builder(
              controller: _controller,
              reverse: true,
              padding: const EdgeInsets.only(bottom: 12),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return _buildMessageiteam(docs[index]);
              },
            ),
          );
        });
  }

  /// Safely formats a Firestore [Timestamp] (or null) as "hh:mm a".
  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      final Timestamp stamp = ts as Timestamp;
      return DateFormat('hh:mm a').format(
        DateTime.fromMicrosecondsSinceEpoch(stamp.microsecondsSinceEpoch),
      );
    } catch (_) {
      return '';
    }
  }

  Widget _buildMessageiteam(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    final isCurrentUser = data["senderid"].toString() ==
        getData.read("UserLogin")["id"].toString();
    var alingmentt =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    final String timeStr = _formatTimestamp(data['timestamp']);

    return Container(
      alignment: alingmentt,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ChatBubble(
              chatColor: isCurrentUser ? blueColor : Colors.grey.shade100,
              textColor: isCurrentUser ? WhiteColor : Colors.black,
              message: data["message"],
              alingment: !isCurrentUser,
            ),
            const SizedBox(
              height: 5,
            ),
            if (timeStr.isNotEmpty)
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: notifire.getwhiteblackcolor,
                  fontFamily: FontFamily.gilroyLight,
                ),
              ),
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

// void requestPermission() async {
//   FirebaseMessaging messaging = FirebaseMessaging.instance;
//   // log(messaging.toString());

//   NotificationSettings settings = await messaging.requestPermission(
//     alert: true,
//     announcement: false,
//     badge: true,
//     carPlay: false,
//     criticalAlert: false,
//     provisional: false,
//     sound: true,
//   );

//   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//     print('User granted permission');
//   } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
//     print('User granted provisional permission');
//   } else {
//     print('User declined or has not accepted permission');
//   }
// }

Future<void> requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Skip if already granted
  NotificationSettings current = await messaging.getNotificationSettings();
  if (current.authorizationStatus == AuthorizationStatus.authorized) {
    print('Permission already granted');
    return;
  }

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
