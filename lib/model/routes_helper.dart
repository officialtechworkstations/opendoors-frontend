// ignore_for_file: prefer_const_constructors

import 'package:get/route_manager.dart';
import 'package:opendoors/screen/add%20proparty/addextraimage_screen.dart';
import 'package:opendoors/screen/add%20proparty/addgallerycategory_screen.dart';
import 'package:opendoors/screen/add%20proparty/addgalleryimage_screen.dart';
import 'package:opendoors/screen/add%20proparty/addproperty_screen.dart';
import 'package:opendoors/screen/add%20proparty/booking_screen.dart';
import 'package:opendoors/screen/add%20proparty/e-receiptpro_screen.dart';
import 'package:opendoors/screen/add%20proparty/enquiry_screen.dart';
import 'package:opendoors/screen/add%20proparty/extraimage_screen.dart';
import 'package:opendoors/screen/add%20proparty/gallerycategory_screen.dart';
import 'package:opendoors/screen/add%20proparty/galleryimage_screen.dart';
import 'package:opendoors/screen/add%20proparty/listofproperty_screen.dart';
import 'package:opendoors/screen/add%20proparty/membarship_screen.dart';
import 'package:opendoors/screen/add%20proparty/membarshipdetails_screen.dart';
import 'package:opendoors/screen/add%20proparty/myearnings_screen.dart';
import 'package:opendoors/screen/add%20proparty/mypayout_screen.dart';
import 'package:opendoors/screen/add%20proparty/reviewlistscreen.dart';
import 'package:opendoors/screen/add%20proparty/subscribe_screen.dart';
import 'package:opendoors/screen/addwallet/addwallet_screen.dart';
import 'package:opendoors/screen/addwallet/referfriend_screen.dart';
import 'package:opendoors/screen/addwallet/wallet_screen.dart';
import 'package:opendoors/screen/bookinformation_screen.dart';
import 'package:opendoors/screen/bookrealestate_screen.dart';
import 'package:opendoors/screen/bottombar_screen.dart';
import 'package:opendoors/screen/coupons_screen.dart';
import 'package:opendoors/screen/e-receipt_screen.dart';
import 'package:opendoors/screen/faq_screen.dart';
import 'package:opendoors/screen/featured_screen.dart';
import 'package:opendoors/screen/gallery_screen.dart';
import 'package:opendoors/screen/homesearch_screen.dart';
import 'package:opendoors/screen/image360Viewer/image_viewer.dart';
import 'package:opendoors/screen/language_screen.dart';
import 'package:opendoors/screen/login_screen.dart';
import 'package:opendoors/screen/loream_screen.dart';
import 'package:opendoors/screen/message_screen.dart';
import 'package:opendoors/screen/mybooking_screen.dart';
import 'package:opendoors/screen/notification_screen.dart';
import 'package:opendoors/screen/onbording_screen.dart';
import 'package:opendoors/screen/otp_screen.dart';
import 'package:opendoors/screen/our_recommendation_screen.dart';
import 'package:opendoors/screen/profile_screen.dart';
import 'package:opendoors/screen/resetpassword_screen.dart';
import 'package:opendoors/screen/review_screen.dart';
import 'package:opendoors/screen/review_summary.dart';
import 'package:opendoors/screen/select_country.dart';
import 'package:opendoors/screen/signup_screen.dart';
import 'package:opendoors/screen/splesh_screen.dart';
import 'package:opendoors/screen/viewdata_screen.dart';
import 'package:opendoors/screen/viewprofile_screen.dart';

class Routes {
  static String initial = "/";
  static String onBordingScreen = '/OnBordingScreen';
  static String login = "/Login";
  static String bottoBarScreen = "/BottoBarScreen";
  static String signUpScreen = "/signUpScreen";
  static String otpScreen = '/otpScreen';
  static String resetPassword = "/resetPassword";
  static String viewDataScreen = "/viewDataScreen";
  static String massageScreen = "/massageScren";
  static String profileScreen = "/profileScreen";
  static String galleryScreen = "/galleyScreen";
  static String reviewScreen = "/reviewScreen";
  static String ourRecommendationScreen = "/ourRecommendationScreen";
  static String notificationScreen = "/notificationScreen";
  static String homeSearchScreen = "/homeSearchScreen";
  static String mybookingScreen = "/mybookingScreen";
  static String languageScreen = "/languageScreen";
  static String viewProfileScreen = "/viewProfileScreen";
  static String bookRealEstate = "/bookRealEstate";
  static String bookInformetionScreen = "/bookInformetionScreen";
  static String reviewSummaryScreen = "/reviewSummaryScreen";
  static String couponsScreen = "/couponsScreen";
  static String eReceiptScreen = "/eReceiptScreen";
  static String loreamScreen = "/loreamScreen";
  static String faqScreen = "/faqScreen";
  static String walletScreen = "/walletScreen";
  static String addWalletScreen = "/addWalletScreen";
  static String referFriendScreen = "/referFriendScreen";
  static String featuredScreen = "/featuredScreen";
  static String membershipScreen = "/membershipScreen";
  static String selectCountryScreen = "/selectCountryScreen";
  static String listOfPropertyScreen = "/listOfPropertyScreen";
  static String addPropertyScreen = "/addPropertyScreen";
  static String extraImageScreen = "/extraImageScreen";
  static String addExtraImageScreen = "/addExtraImageScreen";
  static String galleryCategoryScreen = "/galleryCategoryScreen";
  static String addGalleryCategoryScreen = "/addGalleryCategoryScrren";
  static String galleryImageScreen = "/galleryImageScreen";
  static String addGalleryImageScreen = "/addGalleryImageScreen";
  static String subscribeScreen = "/subscribeScreen";
  static String bookingScreen = "/bookingScreen";
  static String memberShipDetails = "/memberShipDetails";
  static String myEarningsScreen = "/myEarningsScreen";
  static String eReceiptProScreen = "/eReceiptProScreen";
  static String myPayoutScreen = "/myPayoutScreen";
  static String enquiryScreen = "/enquiryScreen";
  static String reviewlistScreen = "/reviewlistScreen";
  static String imageViewerSreen = "/ImageViewerSreen";
}

final getPages = [
  GetPage(
    name: Routes.initial,
    page: () => SpleshScreen(),
  ),
  GetPage(
    name: Routes.onBordingScreen,
    page: () => OnBordingScreen(),
  ),
  GetPage(
    name: Routes.login,
    page: () => LoginScreen(),
  ),
  GetPage(
    name: Routes.bottoBarScreen,
    page: () => BottoBarScreen(),
  ),
  GetPage(
    name: Routes.signUpScreen,
    page: () => SignUpScreen(),
  ),
  GetPage(
    name: Routes.otpScreen,
    page: () => OtpScreen(),
  ),
  GetPage(
    name: Routes.resetPassword,
    page: () => ResetPasswordScreen(),
  ),
  GetPage(
    name: Routes.viewDataScreen,
    page: () => ViewDataScreen(),
  ),
  GetPage(
    name: Routes.massageScreen,
    page: () => MassageScreen(),
  ),
  GetPage(
    name: Routes.profileScreen,
    page: () => ProfileScreen(),
  ),
  GetPage(
    name: Routes.galleryScreen,
    page: () => GalleryScreen(),
  ),
  GetPage(
    name: Routes.reviewScreen,
    page: () => ReviewScreen(),
  ),
  GetPage(
    name: Routes.ourRecommendationScreen,
    page: () => OurRecommendationScreen(),
  ),
  GetPage(
    name: Routes.notificationScreen,
    page: () => NotificationScreen(),
  ),
  GetPage(
    name: Routes.homeSearchScreen,
    page: () => HomeSearchScreen(),
  ),
  GetPage(
    name: Routes.mybookingScreen,
    page: () => MyBookingScreen(),
  ),
  GetPage(
    name: Routes.languageScreen,
    page: () => LanguageScreen(),
  ),
  GetPage(
    name: Routes.viewProfileScreen,
    page: () => ViewProfileScreen(),
  ),
  GetPage(
    name: Routes.bookRealEstate,
    page: () => BookRealEstate(),
  ),
  GetPage(
    name: Routes.bookInformetionScreen,
    page: () => BookInformetionScreen(),
  ),
  GetPage(
    name: Routes.reviewSummaryScreen,
    page: () => ReviewSummaryScreen(),
  ),
  GetPage(
    name: Routes.couponsScreen,
    page: () => CouponsScreen(),
  ),
  GetPage(
    name: Routes.eReceiptScreen,
    page: () => EReceiptScreen(),
  ),
  GetPage(
    name: Routes.loreamScreen,
    page: () => Loream(),
  ),
  GetPage(
    name: Routes.faqScreen,
    page: () => FaqScreen(),
  ),
  GetPage(
    name: Routes.walletScreen,
    page: () => WalletScreen(),
  ),
  GetPage(
    name: Routes.addWalletScreen,
    page: () => AddWalletScreen(),
  ),
  GetPage(
    name: Routes.referFriendScreen,
    page: () => ReferFriendScreen(),
  ),
  GetPage(
    name: Routes.featuredScreen,
    page: () => FeaturedScreen(),
  ),
  GetPage(
    name: Routes.membershipScreen,
    page: () => MembershipScreen(),
  ),
  GetPage(
    name: Routes.selectCountryScreen,
    page: () => SelectCountryScreen(),
  ),
  GetPage(
    name: Routes.listOfPropertyScreen,
    page: () => ListOfPropertyScreen(),
  ),
  GetPage(
    name: Routes.addPropertyScreen,
    page: () => AddPropertyScreen(),
  ),
  GetPage(
    name: Routes.extraImageScreen,
    page: () => ExtraImageScreen(),
  ),
  GetPage(
    name: Routes.addExtraImageScreen,
    page: () => AddExtraImageScreen(),
  ),
  GetPage(
    name: Routes.galleryCategoryScreen,
    page: () => GalleryCategoryScreen(),
  ),
  GetPage(
    name: Routes.addGalleryCategoryScreen,
    page: () => AddGalleryCategoryScreen(),
  ),
  GetPage(
    name: Routes.galleryImageScreen,
    page: () => GallertImageScreen(),
  ),
  GetPage(
    name: Routes.addGalleryImageScreen,
    page: () => AddGalleryImageScreen(),
  ),
  GetPage(
    name: Routes.subscribeScreen,
    page: () => SubscribeScreen(),
  ),
  GetPage(
    name: Routes.bookingScreen,
    page: () => BookingScreen(),
  ),
  GetPage(
    name: Routes.memberShipDetails,
    page: () => MemberShipDetails(),
  ),
  GetPage(
    name: Routes.myEarningsScreen,
    page: () => MyEarningsScreen(),
  ),
  GetPage(
    name: Routes.eReceiptProScreen,
    page: () => EReceiptProScreen(),
  ),
  GetPage(
    name: Routes.myPayoutScreen,
    page: () => MyPayoutScreen(),
  ),
  GetPage(
    name: Routes.enquiryScreen,
    page: () => EnquiryScreen(),
  ),
  GetPage(
    name: Routes.reviewlistScreen,
    page: () => ReviewlistScreen(),),
  GetPage(
    name: Routes.imageViewerSreen,
    page: () => ImageViewerSreen(),
  ),
];
