// ignore_for_file: unused_field, avoid_print, library_private_types_in_public_api, prefer_const_literals_to_create_immutables, prefer_const_constructors, sort_child_properties_last

import 'package:accordion/accordion.dart';
import 'package:accordion/controllers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:goproperti/controller/faq_controller.dart';
import 'package:goproperti/model/fontfamily_model.dart';
import 'package:goproperti/model/model.dart';
import 'package:goproperti/utils/Colors.dart';
import 'package:goproperti/utils/Dark_lightmode.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});
  @override
  _FaqScreenState createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> with TickerProviderStateMixin {
  FaqController faqController = Get.find();

  late ColorNotifire notifire;
  TabController? _tabController;
  getdarkmodepreviousstate() async {
    final prefs = await SharedPreferences.getInstance();
    bool? previusstate = prefs.getBool("setIsDark");
    if (previusstate == null) {
      notifire.setIsDark = false;
    } else {
      notifire.setIsDark = previusstate;
    }
  }

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    getdarkmodepreviousstate();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController?.dispose();
  }

  final _contentStyle = const TextStyle(
      color: Color(0xff999999), fontSize: 14, fontWeight: FontWeight.normal);
  @override
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    return Scaffold(
      backgroundColor: notifire.getfevAndSearch,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: notifire.getbgcolor,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(
            Icons.arrow_back,
            color: notifire.getwhiteblackcolor,
          ),
        ),
        title: Text(
          "Helps & FAQs".tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'Gilroy Medium',
            color: notifire.getwhiteblackcolor,
          ),
        ),
      ),
      body: GetBuilder<FaqController>(builder: (context) {
        return faqController.isLoading
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    Accordion(
                      disableScrolling: true,
                      flipRightIconIfOpen: true,
                      contentVerticalPadding: 0,
                      scrollIntoViewOfItems: ScrollIntoViewOfItems.fast,
                      contentBorderColor: Colors.transparent,
                      maxOpenSections: 1,
                      headerBackgroundColorOpened: notifire.getcardcolor,
                      headerPadding: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 15),
                      children: [
                        for (var j = 0;
                            j < faqController.faqListInfo!.faqData!.length;
                            j++)
                          AccordionSection(
                            rightIcon: Image.asset(
                              "assets/images/Arrow - Down.png",
                              height: 20,
                              width: 20,
                              color: blueColor,
                            ),
                            headerPadding: const EdgeInsets.all(15),
                            headerBackgroundColor: notifire.getcardcolor,
                            contentBackgroundColor: notifire.getcardcolor,
                            header: Text(
                                faqController
                                        .faqListInfo?.faqData![j].question ??
                                    "",
                                style: TextStyle(
                                    color: notifire.getwhiteblackcolor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                            content: Text(
                                faqController.faqListInfo?.faqData![j].answer ??
                                    "",
                                style: _contentStyle),
                            contentHorizontalPadding: 20,
                            contentBorderWidth: 1,
                          ),
                      ],
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  SizedBox(height: 250),
                  Center(child: CircularProgressIndicator()),
                ],
              );
      }),
    );
  }

  Widget faqWidget() {
    return GetBuilder<FaqController>(builder: (context) {
      return faqController.isLoading
          ? SingleChildScrollView(
              child: Column(
                children: [
                  Accordion(
                    disableScrolling: true,
                    flipRightIconIfOpen: true,
                    contentVerticalPadding: 0,
                    scrollIntoViewOfItems: ScrollIntoViewOfItems.fast,
                    contentBorderColor: Colors.transparent,
                    maxOpenSections: 1,
                    headerBackgroundColorOpened: notifire.getcardcolor,
                    headerPadding:
                        const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
                    children: [
                      for (var j = 0;
                          j < faqController.faqListInfo!.faqData!.length;
                          j++)
                        AccordionSection(
                            rightIcon: Image.asset(
                              "assets/images/Arrow - Down.png",
                              height: 20,
                              width: 20,
                              color: blueColor,
                            ),
                            headerPadding: const EdgeInsets.all(15),
                            headerBackgroundColor: notifire.getcardcolor,
                            contentBackgroundColor: notifire.getcardcolor,
                            header: Text(
                                faqController
                                        .faqListInfo?.faqData![j].question ??
                                    "",
                                style: TextStyle(
                                    color: notifire.getwhiteblackcolor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                            content: Text(
                                faqController.faqListInfo?.faqData![j].answer ??
                                    "",
                                style: _contentStyle),
                            contentHorizontalPadding: 20,
                            contentBorderWidth: 1),
                    ],
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                SizedBox(height: 250),
                Center(child: CircularProgressIndicator()),
              ],
            );
    });
  }

  Widget contactUsWidget() {
    return Expanded(
      child: ListView.builder(
        itemCount: model().contactUs.length,
        itemBuilder: (context, index) {
          return Container(
            height: 60,
            width: Get.size.width,
            margin: EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 15,
                ),
                Image.asset(
                  "assets/images/wifi.png",
                  height: 25,
                  width: 25,
                ),
                SizedBox(
                  width: 15,
                ),
                Text(
                  model().contactUs[index],
                  style: TextStyle(
                    color: notifire.getwhiteblackcolor,
                    fontSize: 17,
                    fontFamily: FontFamily.gilroyBold,
                  ),
                ),
              ],
            ),
            decoration: BoxDecoration(
              color: notifire.getblackwhitecolor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade100),
            ),
          );
        },
      ),
    );
  }
}
