// ignore_for_file: must_be_immutable, deprecated_member_use, avoid_print

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/controller/homepage_controller.dart';
import 'package:opendoors/model/app_settings.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/screen/add%20proparty/membarship_screen.dart';
import 'package:opendoors/screen/bottombar_screen.dart';
import 'package:opendoors/screen/login_screen.dart';
import 'package:opendoors/screen/onbording_screen.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key, required this.isForceUpdate});

  final bool isForceUpdate;

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen>
    with SingleTickerProviderStateMixin {
  late ColorNotifire notifire;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String latestVersion = '';
  HomePageController homePageController = Get.find();
  AppSetting appSetting = AppSetting.initial();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    appSetting = homePageController.appSetting;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    getPlatformNewVersion();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  getdarkmodepreviousstate() async {
    final prefs = await SharedPreferences.getInstance();
    bool? previusstate = prefs.getBool("setIsDark");
    if (previusstate == null) {
      notifire.setIsDark = false;
    } else {
      notifire.setIsDark = previusstate;
    }
  }

  getPlatformNewVersion() {
    if (Platform.isIOS) {
      final v = appSetting.providerCurrentVersionIosApp ?? '';
      final build = appSetting.providerCurrentBuildNumberIosApp ?? '';
      latestVersion = '$v.+$build';
    } else if (Platform.isAndroid) {
      final va = appSetting.providerCurrentVersionAndroidApp ?? '';
      final build = appSetting.providerCurrentBuildNumberAndroidApp ?? '';
      latestVersion = '$va.+$build';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    final isDark = notifire.getIsDark;

    return Scaffold(
      backgroundColor: notifire.getbgcolor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Animated Icon with Glow Effect
                    _buildAnimatedIcon(isDark),

                    const SizedBox(height: 40),

                    // Title
                    Text(
                      widget.isForceUpdate
                          ? 'Update Required'.tr
                          : 'New Version Available'.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28.0,
                        fontFamily: FontFamily.gilroyBold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Version badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: blueColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: blueColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Version $latestVersion'.tr,
                        style: TextStyle(
                          color: blueColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          fontFamily: FontFamily.gilroyMedium,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    Text(
                      widget.isForceUpdate
                          ? 'This version is no longer supported. Please update to continue enjoying our services with improved security and performance.'
                              .tr
                          : 'We\'ve added exciting new features and improvements to enhance your experience!'
                              .tr,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                        fontSize: 15.0,
                        height: 1.5,
                        fontFamily: FontFamily.gilroyMedium,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // What's New Section
                    if (!widget.isForceUpdate) _buildWhatsNewSection(isDark),

                    const SizedBox(height: 40),

                    // Update Button
                    _buildUpdateButton(),

                    const SizedBox(height: 16),

                    // Not Now Button
                    if (widget.isForceUpdate == false) _buildNotNowButton(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  blueColor.withOpacity(0.2),
                  blueColor.withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: blueColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blueColor,
                  boxShadow: [
                    BoxShadow(
                      color: blueColor.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWhatsNewSection(bool isDark) {
    final features = [
      {
        'icon': Icons.speed_rounded,
        'title': 'Performance Boost'.tr,
        'description': 'Faster loading times'.tr,
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Enhanced Security'.tr,
        'description': 'Better data protection'.tr,
      },
      {
        'icon': Icons.bug_report_rounded,
        'title': 'Bug Fixes'.tr,
        'description': 'Smoother experience'.tr,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s New'.tr,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: FontFamily.gilroyBold,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: blueColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: blueColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'] as String,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: FontFamily.gilroyMedium,
                            ),
                          ),
                          Text(
                            feature['description'] as String,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.6),
                              fontSize: 12,
                              fontFamily: FontFamily.gilroyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return InkWell(
      onTap: () {
        final String appstoreURL = appSetting.customerAppAppStoreURL ?? "";
        final String playstoreURL = appSetting.customerAppPlayStoreURL ?? "";

        if (Platform.isIOS) {
          launchUrl(Uri.parse(appstoreURL),
              mode: LaunchMode.externalApplication);
        } else if (Platform.isAndroid) {
          launchUrl(
            Uri.parse(playstoreURL),
            mode: LaunchMode.externalApplication,
          );
        }
      },
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [blueColor, blueColor.withOpacity(0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: blueColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Update Now".tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: FontFamily.gilroyBold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotNowButton() {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              // log('message');
              setScreenInit();
            },
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: blueColor,
                  ),
                ),
              )
            : Center(
                child: Text(
                  "Maybe Later".tr,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: FontFamily.gilroyMedium,
                  ),
                ),
              ),
      ),
    );
  }

  _setLoading(bool val) {
    setState(() {
      isLoading = val;
    });
  }

  setScreenInit() {
    _setLoading(true);
    homePageController
        .getCatWiseData(
      cId: "0",
      countryId: getData.read("countryId"),
    )
        .then(
      (value) async {
        await setScreen();
        _setLoading(false);
      },
    );
  }

  setScreen() async {
    final prefs = await SharedPreferences.getInstance();
    print("OPERN DOOORS ###");
    Timer(
        const Duration(seconds: 3),
        () => prefs.getBool('Firstuser') != true
            ? Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const OnBordingScreen()))
            : prefs.getBool('Remember') != true
                ? Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()))
                : getData.read("userType") == "admin"
                    ? Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MembershipScreen()))
                    : Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const BottoBarScreen())));
  }
}
