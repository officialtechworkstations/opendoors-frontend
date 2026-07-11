import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/firebase/chat_screen.dart';
import 'package:opendoors/firebase/chat_service.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  late ColorNotifire notifire;
  final TextEditingController searchController = TextEditingController();

  // ── Search state ─────────────────────────────────────────────────────────────
  // Keyed by uid → physically impossible to get duplicates.
  final Map<String, Map<String, dynamic>> _chatItemsMap = {};
  List<Map<String, dynamic>> _searchResults = [];

  final ChatServices _chatServices = ChatServices();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    return Scaffold(
      backgroundColor: notifire.getbgcolor,
      appBar: AppBar(
        backgroundColor: notifire.getbgcolor,
        centerTitle: true,
        elevation: 0,
        leading: BackButton(
          color: notifire.getwhiteblackcolor,
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Chats',
          style: TextStyle(
            fontFamily: FontFamily.gilroyBold,
            fontSize: 18,
            color: notifire.getwhiteblackcolor,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              style: TextStyle(
                color: notifire.getwhiteblackcolor,
                fontFamily: FontFamily.gilroyMedium,
                fontSize: 16,
              ),
              controller: searchController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(15),
                isDense: true,
                hintStyle: TextStyle(color: notifire.getgreycolor),
                hintText: 'Search..',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: notifire.getborderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: notifire.getborderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: notifire.getborderColor),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: notifire.getborderColor),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: notifire.getborderColor),
                ),
              ),
              onChanged: (s) {
                setState(() {
                  if (s.isEmpty) {
                    _searchResults = [];
                  } else {
                    _searchResults = _chatItemsMap.values
                        .where((item) => item['name']
                            .toString()
                            .toLowerCase()
                            .contains(s.toLowerCase()))
                        .toList();
                  }
                });
              },
            ),
          ),

          // ── List area ──────────────────────────────────────────────────────
          if (searchController.text.isEmpty)
            Expanded(child: _buildUserList())
          else if (_searchResults.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'User Not Found',
                  style: TextStyle(
                    fontFamily: FontFamily.gilroyMedium,
                    color: notifire.getwhiteblackcolor,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return _buildChatTile(
                    uid: item['uid'] as String,
                    name: item['name'] as String,
                    proPic: item['image'] as String,
                    lastMessage: item['message'] as String,
                    lastTimestamp: item['timestamp'] as Timestamp?,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Outer stream: all registered users ───────────────────────────────────────

  Widget _buildBackgroundStreamer(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('opendoors_users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map<Widget>((doc) {
            final Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
            final String uid = (data['uid'] ?? doc.id).toString();
            if (uid.isEmpty || uid == currentUserId) return const SizedBox.shrink();

            return StreamBuilder<QuerySnapshot>(
              stream: _chatServices.getMessage(userId: uid, otherUserId: currentUserId),
              builder: (context, msgSnapshot) {
                if (!msgSnapshot.hasData || msgSnapshot.data!.docs.isEmpty) {
                  if (_chatItemsMap.containsKey(uid)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _chatItemsMap.remove(uid);
                      });
                    });
                  }
                  return const SizedBox.shrink();
                }

                final lastMsgDoc = msgSnapshot.data!.docs.last;
                final lastMsgData = lastMsgDoc.data() as Map<String, dynamic>;
                final Timestamp? ts = lastMsgData['timestamp'] as Timestamp?;
                final String message = lastMsgData['message']?.toString() ?? '';
                final String name = data['name']?.toString() ?? 'Unknown';
                final String proPic = data['pro_pic']?.toString() ?? 'null';

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final existing = _chatItemsMap[uid];
                  if (existing == null ||
                      existing['message'] != message ||
                      existing['timestamp'] != ts ||
                      existing['name'] != name ||
                      existing['image'] != proPic) {
                    setState(() {
                      _chatItemsMap[uid] = {
                        'name': name,
                        'image': proPic,
                        'uid': uid,
                        'message': message,
                        'timestamp': ts,
                      };
                    });
                  }
                });

                return const SizedBox.shrink();
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUserList() {
    // Guard: if the user session hasn't loaded yet, show a spinner.
    final rawId = getData.read('UserLogin')?['id'];
    if (rawId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final String currentUserId = rawId.toString();

    final activeChats = _chatItemsMap.values.toList();
    activeChats.sort((a, b) {
      final t1 = a['timestamp'] as Timestamp?;
      final t2 = b['timestamp'] as Timestamp?;
      if (t1 == null && t2 == null) return 0;
      if (t1 == null) return 1;
      if (t2 == null) return -1;
      return t2.compareTo(t1);
    });

    return Stack(
      children: [
        Offstage(
          offstage: true,
          child: SingleChildScrollView(
            child: _buildBackgroundStreamer(currentUserId),
          ),
        ),
        activeChats.isEmpty
            ? Center(
                child: Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: notifire.getwhiteblackcolor,
                    fontFamily: FontFamily.gilroyBold,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: activeChats.length,
                itemBuilder: (context, index) {
                  final item = activeChats[index];
                  return _buildChatTile(
                    uid: item['uid'] as String,
                    name: item['name'] as String,
                    proPic: item['image'] as String,
                    lastMessage: item['message'] as String,
                    lastTimestamp: item['timestamp'] as Timestamp?,
                  );
                },
              ),
      ],
    );
  }

  String _getDisplayMessage(String message) {
    if (message.startsWith('{') && message.endsWith('}')) {
      try {
        final parsed = jsonDecode(message);
        if (parsed is Map<String, dynamic> && parsed['type'] == 'property') {
          final title = parsed['title'] ?? '';
          return 'Inquiry: $title';
        }
      } catch (_) {}
    }
    return message;
  }

  Widget _buildChatTile({
    required String uid,
    required String name,
    required String proPic,
    required String lastMessage,
    required Timestamp? lastTimestamp,
  }) {
    final String timeStr = _formatTimestamp(lastTimestamp);
    return ListTile(
      onTap: () {
        Get.to(ChatPage(
          proPic: proPic,
          resiverUserId: uid,
          resiverUseremail: name,
        ));
      },
      leading: proPic == 'null'
          ? const CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 25,
              backgroundImage: AssetImage('assets/images/profile-default.png'))
          : CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 25,
              backgroundImage: NetworkImage('${Config.imageUrl}$proPic')),
      title: Text(
        name,
        style: TextStyle(
          color: notifire.getwhiteblackcolor,
          fontFamily: FontFamily.gilroyMedium,
        ),
      ),
      subtitle: Text(
        _getDisplayMessage(lastMessage),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: notifire.getwhiteblackcolor,
          fontFamily: FontFamily.gilroyLight,
        ),
      ),
      trailing: timeStr.isNotEmpty
          ? Text(
              timeStr,
              style: TextStyle(
                fontSize: 10,
                color: notifire.getwhiteblackcolor,
                fontFamily: FontFamily.gilroyLight,
              ),
            )
          : null,
    );
  }
}
