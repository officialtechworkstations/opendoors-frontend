// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables, prefer_interpolation_to_compose_strings, non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/Api/reels_api_service.dart';
import 'package:opendoors/controller/listofproperti_controller.dart';
import 'package:opendoors/controller/homepage_controller.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:http/http.dart' as http;
import 'package:video_compress/video_compress.dart';
import 'package:opendoors/utils/app_logger.dart';

class AddPropertiesController extends GetxController implements GetxService {
  ListOfPropertiController listOfPropertiController = Get.find();

  TextEditingController pTitle = TextEditingController();
  TextEditingController pNumber = TextEditingController();
  TextEditingController pAddress = TextEditingController();
  TextEditingController pPrice = TextEditingController();
  TextEditingController pPartyCost = TextEditingController();
  TextEditingController pCaution = TextEditingController();
  TextEditingController propertyAddress = TextEditingController();
  TextEditingController totalBeds = TextEditingController();
  TextEditingController totalBathroom = TextEditingController();
  TextEditingController pSqft = TextEditingController();
  TextEditingController pRating = TextEditingController();
  TextEditingController pGest = TextEditingController();
  TextEditingController pCityAndCountry = TextEditingController();

  String? path;
  String? base64Image;
  final List<String> imagePaths = [];
  final List<String> base64Images = [];
  String? reelVideoPath;
  String? reelThumbnailPath;
  String? existingReelId;
  String? createdPropertyId;
  double reelUploadProgress = 0;
  String reelUploadStage = '';
  final ReelsApiService reelsApiService = ReelsApiService();

  String countryId = "1";

  String pType = "";
  String pbuySell = "1";
  String status = "";

  String pImage = "";
  bool _locationManuallySelected = false;
  String? _confirmedAddressKey;

  String get _addressKey =>
      '${pAddress.text.trim()}|${pCityAndCountry.text.trim()}';

  bool get _hasValidCoordinates {
    final latitude = double.tryParse(lat?.toString() ?? '');
    final longitude = double.tryParse(long?.toString() ?? '');
    return latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  Future<bool> _resolvePropertyCoordinates({bool editing = false}) async {
    if (_hasValidCoordinates &&
        (_locationManuallySelected && _confirmedAddressKey == _addressKey ||
            editing &&
                pAddress.text.trim() == eAddress.trim() &&
                pCityAndCountry.text.trim() == eCityAndCountry.trim())) {
      return true;
    }
    showToastMessage(
        'Pin the property on the map, or use Current Location if you are there.');
    return false;
  }

  final Rx<bool> isBusy = false.obs;
  // bool isBusy = false;

  var selectedIndexes = [];

  var lat;
  var long;

  String eTitle = "";
  String eNumber = "";
  String eAddress = "";
  String ePrice = "";
  String ePropertyAddress = "";
  String eTotalBeds = "";
  String eTotalBathroom = "";
  String eSqft = "";
  String eRating = "";
  String eCityAndCountry = "";
  String propId = "";
  String eImage = "";
  String eReelId = "";
  String eGest = "";
  String buyOrRent = "";
  String Id = "";
  String pShell = "0";
  String eparty_cost = "0";
  String ecaution_fee = "0";

  String fList = "";
  String pName = "";
  String countryName = "";
  bool party_allowed = false;
  bool caution_fee_setting = true;

  var elat;
  var elong;

  setBusy(bool state) {
    isBusy.value = state;
    update();
  }

  getEditDetails(
      {String? eTitle1,
      eNumber1,
      eAddress1,
      ePrice1,
      ePropertyAddress1,
      eTotalBeds1,
      eTotalBathroom1,
      eSqft1,
      eRating1,
      eCityAndCountry1,
      lat1,
      long1,
      propId1,
      eImage1,
      eGest1,
      ebuyorRent,
      isShell,
      id,
      facelity1,
      pID,
      proName1,
      countryId1,
      countryName1,
      party_allowed1,
      party_cost1,
      caution_fee1,
      reelId1}) {
    eTitle = eTitle1 ?? "";
    eNumber = eNumber1 ?? "";
    eAddress = eAddress1 ?? "";
    ePrice = ePrice1 ?? "";
    ePropertyAddress = ePropertyAddress1 ?? "";
    eTotalBeds = eTotalBeds1 ?? "";
    eTotalBathroom = eTotalBathroom1 ?? "";
    eSqft = eSqft1 ?? "";
    eRating = eRating1 ?? "";
    eCityAndCountry = eCityAndCountry1 ?? "";
    elat = lat1 ?? "";
    elong = long1 ?? "";
    propId = propId1 ?? "";
    eImage = eImage1 ?? "";
    eGest = eGest1 ?? "";
    buyOrRent = ebuyorRent;
    pShell = isShell;
    Id = id;
    fList = facelity1;
    pType = pID;
    pName = proName1;
    countryId = countryId1;
    countryName = countryName1;
    party_allowed = party_allowed1 == "1";
    eparty_cost = party_cost1 ?? "0";
    ecaution_fee = caution_fee1 ?? "0";
    eReelId = reelId1?.toString() ?? "";
    existingReelId = eReelId;
    update();
  }

  getCurrentLatAndLong(double latitude, double longitude) {
    lat = latitude;
    long = longitude;
    _locationManuallySelected = true;
    _confirmedAddressKey = _addressKey;
    update();
  }

  emptyAllDetails() {
    pTitle.text = "";
    pNumber.text = "";
    pAddress.text = "";
    pPrice.text = "";
    propertyAddress.text = "";
    totalBeds.text = "";
    totalBathroom.text = "";
    pSqft.text = "";
    pRating.text = "";
    pGest.text = "";
    pCityAndCountry.text = "";
    pPartyCost.text = "";
    pCaution.text = "";
    path = null;
    base64Image = "";
    imagePaths.clear();
    base64Images.clear();
    pbuySell = "1";
    status = "";
    lat = null;
    long = null;
    _locationManuallySelected = false;
    _confirmedAddressKey = null;
    pImage = "";
    reelVideoPath = null;
    reelThumbnailPath = null;
    existingReelId = null;
    createdPropertyId = null;
    reelUploadProgress = 0;
    reelUploadStage = '';
    // party_allowed = false;
    update();
  }

  addPropertyApi() async {
    if (!await _resolvePropertyCoordinates()) return;
    String str = selectedIndexes.toSet().toList().join(",");
    try {
      Map map = {
        "uid": getData.read("UserLogin")["id"],
        "status": status == "" ? "1" : status, // publish 1 /0
        "plimit": pGest.text,
        "country_id": countryId.isEmpty ? "1" : countryId,
        // "pbuysell": pbuySell == "" ? "2" : pbuySell, // buy hoy to 2 nkar 1
        "pbuysell": pbuySell == "" ? "1" : pbuySell, // buy hoy to 2 nkar 1
        "title": pTitle.text,
        "address": pAddress.text,
        "description": propertyAddress.text,
        "ccount": pAddress.text,
        "facility": str,
        "ptype": pType,
        "beds": totalBeds.text,
        "bathroom": totalBathroom.text,
        "sqft": pSqft.text,
        "rate": pRating.text.isEmpty ? "0" : pRating.text,
        "latitude": lat?.toString() ?? "",
        "longtitude": long?.toString() ?? "",
        "mobile": pNumber.text,
        "price": pPrice.text.replaceAll(',', ''),
        "img": base64Image,
        "party_allowed": party_allowed ? "1" : "0",
        "party_cost": pPartyCost.text.isNotEmpty ? pPartyCost.text : "0",
        "caution_fee":
            pCaution.text.isNotEmpty ? pCaution.text.replaceAll(',', '') : "0"
      };
      AppLogger.info('PropertyUpload', 'Creating property');
      setBusy(true);

      Uri uri = Uri.parse(Config.path + Config.addPropertyApi);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        AppLogger.info('PropertyUpload', 'Create response received', data: {
          'status': response.statusCode,
          'result': result['Result'],
          'response_code': result['ResponseCode'],
          'prop_id': result['prop_id'],
        });
        if (result["Result"] == "true") {
          final newPropertyId = result['prop_id']?.toString();
          if (newPropertyId == null || newPropertyId.isEmpty) {
            showToastMessage(
              'Property was created, but the server did not return its ID.',
            );
            return;
          }
          createdPropertyId = newPropertyId;
          await _uploadMediaAndFinish(propertyId: newPropertyId);
        } else {
          showToastMessage(result["ResponseMsg"]);
        }
      }
    } catch (error, stackTrace) {
      AppLogger.error('PropertyUpload', 'Property creation failed',
          error: error, stackTrace: stackTrace);
    } finally {
      setBusy(false);
    }
  }

  Future<void> submitPropertyWithReel() async {
    if (reelVideoPath == null) {
      showToastMessage('Please upload a property reel.');
      return;
    }
    if (reelThumbnailPath == null) {
      setBusy(true);
      try {
        await _prepareReelForUpload();
      } catch (error) {
        showToastMessage('Unable to prepare reel: $error');
        return;
      } finally {
        setBusy(false);
      }
    }
    if (createdPropertyId != null) {
      setBusy(true);
      try {
        await _uploadMediaAndFinish(propertyId: createdPropertyId!);
      } finally {
        setBusy(false);
      }
      return;
    }
    await addPropertyApi();
  }

  Future<void> _prepareReelForUpload() async {
    final originalPath = reelVideoPath;
    if (originalPath == null) {
      throw const ReelsApiException('Please select a reel.');
    }
    reelUploadStage = 'Compressing reel';
    reelUploadProgress = 0;
    update();
    final mediaInfo = await VideoCompress.compressVideo(
      originalPath,
      quality: VideoQuality.Res1280x720Quality,
      deleteOrigin: false,
      includeAudio: true,
      frameRate: 30,
    );
    final compressedFile = mediaInfo?.file;
    if (compressedFile == null || !await compressedFile.exists()) {
      throw const ReelsApiException('Video compression failed.');
    }
    final thumbnail = await VideoCompress.getFileThumbnail(
      compressedFile.path,
      quality: 80,
      position: 1000,
    );
    if (!await thumbnail.exists()) {
      throw const ReelsApiException('Thumbnail generation failed.');
    }
    final validationError = await validateReel(compressedFile.path);
    if (validationError != null) {
      throw ReelsApiException(validationError);
    }
    reelVideoPath = compressedFile.path;
    reelThumbnailPath = thumbnail.path;
    reelUploadStage = 'Ready to upload';
    update();
  }

  Future<void> _uploadMediaAndFinish({
    required String propertyId,
    bool isEdit = false,
  }) async {
    final videoPath = reelVideoPath;
    try {
      if (videoPath != null) {
        reelUploadStage = 'Uploading reel';
        reelUploadProgress = 0;
        update();
        void onProgress(int sent, int total) {
          reelUploadProgress = total == 0 ? 0 : sent / total;
          update();
        }

        if (isEdit && existingReelId?.isNotEmpty == true) {
          await reelsApiService.update(
            reelId: existingReelId!,
            videoPath: videoPath,
            thumbnailPath: reelThumbnailPath!,
            onProgress: onProgress,
          );
        } else {
          await reelsApiService.create(
            propertyId: propertyId,
            videoPath: videoPath,
            thumbnailPath: reelThumbnailPath,
            onProgress: onProgress,
          );
        }
      }
      await _uploadAdditionalImages(propertyId);
      await listOfPropertiController.getPropertiList();
      if (Get.isRegistered<HomePageController>()) {
        await Get.find<HomePageController>().getHomeDataApi();
      }
      final message = isEdit
          ? 'Property updated successfully.'
          : 'Property added successfully.';
      emptyAllDetails();
      showToastMessage(message);
      Get.back();
    } on ReelsApiException catch (error) {
      await listOfPropertiController.getPropertiList();
      if (Get.isRegistered<HomePageController>()) {
        await Get.find<HomePageController>().getHomeDataApi();
      }
      showToastMessage(
        isEdit
            ? 'Property updated, but the reel upload failed: ${error.message}.'
            : 'Property created, but the reel upload failed: ${error.message}. Tap submit to retry.',
      );
    } catch (error, stackTrace) {
      AppLogger.error('PropertyUpload', 'Additional photo upload failed',
          error: error,
          stackTrace: stackTrace,
          data: {'property_id': propertyId});
      await listOfPropertiController.getPropertiList();
      if (Get.isRegistered<HomePageController>()) {
        await Get.find<HomePageController>().getHomeDataApi();
      }
      showToastMessage(
          'Property saved, but one or more additional photos failed to upload.');
      Get.back();
    }
  }

  Future<void> _uploadAdditionalImages(String propertyId) async {
    for (final image in base64Images.skip(1)) {
      final response = await http.post(
        Uri.parse(Config.path + Config.addExtraImage),
        body: jsonEncode({
          'uid': getData.read('UserLogin')['id'],
          'prop_id': propertyId,
          'img': image,
          'status': '1',
          'is_panorama': '0',
        }),
      );
      final result = response.statusCode == 200
          ? jsonDecode(response.body) as Map<String, dynamic>
          : const <String, dynamic>{};
      if (result['Result']?.toString() != 'true') {
        throw Exception('One of the additional photos could not be uploaded.');
      }
    }
  }

  Future<String?> validateReel(String videoPath) async {
    const maxBytes = 300 * 1024 * 1024;
    final extension = videoPath.split('.').last.toLowerCase();
    const extensions = {'mp4', 'mov', 'avi', 'mkv', 'webm'};
    if (!extensions.contains(extension)) {
      return 'Choose an MP4, MOV, AVI, MKV, or WEBM video.';
    }
    if (await File(videoPath).length() > maxBytes) {
      return 'The reel must be 300 MB or smaller.';
    }
    return null;
  }

  testLoading() async {
    setBusy(true);
    await Future.delayed(const Duration(seconds: 3));
    setBusy(false);
  }

  editPropertyApi() async {
    if (!await _resolvePropertyCoordinates(editing: true)) return;
    if (reelVideoPath != null && reelThumbnailPath == null) {
      setBusy(true);
      try {
        await _prepareReelForUpload();
      } catch (error) {
        showToastMessage('Unable to prepare reel: $error');
        return;
      } finally {
        setBusy(false);
      }
    }
    try {
      AppLogger.debug('PropertyUpload', 'Updating property', data: {
        'property_id': propId,
        'facility_count': selectedIndexes.length,
      });
      String str = selectedIndexes.toSet().toList().join(",");
      Map map = {
        "uid": getData.read("UserLogin")["id"],
        "user_id": getData.read("UserLogin")["id"],
        // "listing_date": "",
        "status": status == "" ? "1" : status,
        "plimit": pGest.text,
        "country_id": countryId.isEmpty ? "1" : countryId,
        // "pbuysell": pbuySell == "" ? "2" : pbuySell,
        "pbuysell": pbuySell == "" ? "1" : pbuySell,
        "title": pTitle.text,
        "address": pAddress.text,
        "description": propertyAddress.text,
        "ccount": pAddress.text,
        "facility": str,
        "ptype": pType,
        "beds": totalBeds.text,
        "bathroom": totalBathroom.text,
        "sqft": pSqft.text,
        "rate": pRating.text.isEmpty ? "0" : pRating.text,
        "latitude": lat?.toString() ?? "",
        "longtitude": long?.toString() ?? "",
        "mobile": pNumber.text,
        "price": pPrice.text.replaceAll(',', ''),
        "img": path != null ? base64Image : "0",
        "prop_id": propId,
        "party_allowed": party_allowed ? "1" : "0",
        "party_cost": pPartyCost.text.isNotEmpty ? pPartyCost.text : "0",
        "caution_fee":
            pCaution.text.isNotEmpty ? pCaution.text.replaceAll(',', '') : "0"
      };
      setBusy(true);

      Uri uri = Uri.parse(Config.path + Config.editPropertyApi);
      var response = await http.post(
        uri,
        body: jsonEncode(map),
      );
      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        AppLogger.info('PropertyUpload', 'Update response received', data: {
          'status': response.statusCode,
          'result': result['Result'],
          'response_code': result['ResponseCode'],
          'property_id': propId,
        });
        if (result["Result"] == "true") {
          await _uploadMediaAndFinish(propertyId: propId, isEdit: true);
        } else {
          showToastMessage(result["ResponseMsg"]);
        }
      }
    } catch (error, stackTrace) {
      AppLogger.error('PropertyUpload', 'Property update failed',
          error: error, stackTrace: stackTrace, data: {'property_id': propId});
    } finally {
      setBusy(false);
    }
  }
}
