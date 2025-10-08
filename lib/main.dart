import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:opendoors/firebase/auth_service.dart';
import 'package:opendoors/firebase/chat_screen.dart';
import 'package:opendoors/model/routes_helper.dart';
import 'package:opendoors/screen/home_screen.dart';
import 'package:opendoors/screen/splesh_screen.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:opendoors/utils/localstring.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'helpar/get_di.dart' as di;

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  requestPermission();
  handleFCMNavigation();
  await Permission.phone.request();
  await requestStoragePermission();
  // await Permission.notification.request();
  await getLocation();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  listenFCM();
  loadFCM();
  initializeNotifications();

  await GetStorage.init();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ColorNotifire()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            dividerColor: Colors.transparent,
            primaryColor: Darkblue,
            useMaterial3: false,
            fontFamily: "Gilroy"),
        initialRoute: Routes.initial,
        translations: LocaleString(),
        locale: const Locale('en_US', 'en_US'),
        getPages: getPages,
      ),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

Future requestStoragePermission() async {
  if (Platform.isAndroid) {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    print(">>>>>>>>>>>>>>>>${androidInfo.version.sdkInt}");
    int androidVersion = androidInfo.version.sdkInt;
    if (androidVersion > 32) {
      await Permission.photos.request();
    } else if (androidVersion <= 32) {
      await Permission.storage.request();
    }
  } else if (Platform.isIOS) {
    await Permission.photos.request();
  }
}
