// Controller
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:opendoors/screen/kyc/widgets/model.dart';

class KYCController extends GetxController implements GetxService {
  final Color primaryColor = const Color(0xffFF4D00);

  var isLoadingRequirements = true.obs;
  var isLoadingMyDocuments = true.obs;
  var isUploading = false.obs;

  var requiredDocuments = <DocumentRequirement>[].obs;
  var uploadedDocuments = <UploadedDocument>[].obs;
  var overallStatus = 'incomplete'.obs;

  // Local file storage for pending uploads
  var localFiles = <String, Map<String, File?>>{}.obs;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchRequiredDocuments();
    fetchMyDocuments();
  }

  Future<void> fetchRequiredDocuments() async {
    try {
      isLoadingRequirements.value = true;

      // Mock API call - Replace with actual API
      await Future.delayed(const Duration(seconds: 1));

      var mockResponse = {
        "documents": [
          {
            "name": "CAC Document",
            "description":
                "A CAC document confirming that your business is registered in Nigeria",
            "upload_type": "multiple",
            "accpetable_file_types": ["pdf", "image"]
          },
          {
            "name": "Business logo",
            "description": "An image of your business logo",
            "upload_type": "single",
            "accpetable_file_types": ["image"]
          },
          {
            "name": "Tax Identification Number",
            "description": "Your valid TIN certificate",
            "upload_type": "single",
            "accpetable_file_types": ["pdf", "image"]
          }
        ],
        "ResponseCode": 200,
        "Result": "true",
        "ResponseMsg": "Required documents retrieved"
      };

      /* Actual API call would be:
      var response = await http.get(
        Uri.parse(Config.path + Config.getRequiredDocumentsUrl),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var docsResponse = RequiredDocumentsResponse.fromJson(data);
        requiredDocuments.value = docsResponse.documents;
      }
      */

      var docsResponse = RequiredDocumentsResponse.fromJson(mockResponse);
      requiredDocuments.value = docsResponse.documents;

      // Initialize local files map
      for (var doc in requiredDocuments) {
        if (doc.isMultiple) {
          localFiles[doc.name] = {'front': null, 'back': null};
        } else {
          localFiles[doc.name] = {'single': null};
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load required documents');
    } finally {
      isLoadingRequirements.value = false;
    }
  }

  Future<void> fetchMyDocuments() async {
    try {
      isLoadingMyDocuments.value = true;

      // Mock API call - Replace with actual API
      await Future.delayed(const Duration(seconds: 1));

      var mockResponse = {
        "documents": [
          {
            "name": "CAC Document",
            "status": "approved",
            "rejection_reason": null,
            "files": [
              {"url": "https://example.com/cac_front.jpg", "type": "front"},
              {"url": "https://example.com/cac_back.jpg", "type": "back"}
            ]
          },
          {
            "name": "Business logo",
            "status": "rejected",
            "rejection_reason":
                "Logo is not clear. Please upload a higher resolution image.",
            "files": [
              {"url": "https://example.com/logo.jpg", "type": "single"}
            ]
          }
        ],
        "overall_status": "pending",
        "ResponseCode": 200,
        "Result": "true",
        "ResponseMsg": "Documents retrieved"
      };

      /* Actual API call would be:
      var response = await http.get(
        Uri.parse(Config.path + Config.getMyDocumentsUrl + '?uid=${userId}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var myDocsResponse = MyDocumentsResponse.fromJson(data);
        uploadedDocuments.value = myDocsResponse.documents;
        overallStatus.value = myDocsResponse.overallStatus;
      }
      */

      var myDocsResponse = MyDocumentsResponse.fromJson(mockResponse);
      uploadedDocuments.value = myDocsResponse.documents;
      overallStatus.value = myDocsResponse.overallStatus;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load your documents');
    } finally {
      isLoadingMyDocuments.value = false;
    }
  }

  Future<void> pickDocument(String documentName, {String? type}) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        File file = File(image.path);

        if (type != null) {
          // Multiple upload (front/back)
          localFiles[documentName]![type] = file;
        } else {
          // Single upload
          localFiles[documentName]!['single'] = file;
        }

        update();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  Future<void> uploadDocument(String documentName, int userId) async {
    try {
      isUploading.value = true;

      var files = localFiles[documentName];
      if (files == null || files.values.every((file) => file == null)) {
        Get.snackbar('Error', 'Please select files to upload');
        return;
      }

      // Mock API call - Replace with actual multipart upload
      await Future.delayed(const Duration(seconds: 2));

      /* Actual API call would be:
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(Config.path + Config.uploadDocumentUrl),
      );
      
      request.fields['uid'] = userId.toString();
      
      for (var entry in files.entries) {
        if (entry.value != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'file',
              entry.value!.path,
            ),
          );
        }
      }
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        var data = jsonDecode(responseData);
        // Handle success
      }
      */

      Get.snackbar(
        'Success',
        'Document uploaded successfully',
        backgroundColor: primaryColor.withOpacity(0.9),
        colorText: Colors.white,
      );

      // Refresh documents
      await fetchMyDocuments();

      // Clear local files for this document
      if (files.keys.length > 1) {
        localFiles[documentName] = {'front': null, 'back': null};
      } else {
        localFiles[documentName] = {'single': null};
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload document');
    } finally {
      isUploading.value = false;
    }
  }

  bool hasLocalFile(String documentName, {String? type}) {
    var files = localFiles[documentName];
    if (files == null) return false;

    if (type != null) {
      return files[type] != null;
    } else {
      return files['single'] != null;
    }
  }

  bool hasUploadedFile(String documentName, {String? type}) {
    var doc = uploadedDocuments.firstWhereOrNull((d) => d.name == documentName);
    if (doc == null) return false;

    if (type != null) {
      return doc.files.any((f) => f.type == type);
    } else {
      return doc.files.isNotEmpty;
    }
  }

  String? getUploadedFileUrl(String documentName, {String? type}) {
    var doc = uploadedDocuments.firstWhereOrNull((d) => d.name == documentName);
    if (doc == null) return null;

    if (type != null) {
      return doc.files.firstWhereOrNull((f) => f.type == type)?.url;
    } else {
      return doc.files.isNotEmpty ? doc.files.first.url : null;
    }
  }

  String getDocumentStatus(String documentName) {
    var doc = uploadedDocuments.firstWhereOrNull((d) => d.name == documentName);
    return doc?.status ?? 'not_uploaded';
  }

  String? getRejectionReason(String documentName) {
    var doc = uploadedDocuments.firstWhereOrNull((d) => d.name == documentName);
    return doc?.rejectionReason;
  }

  bool canSubmitDocument(String documentName, bool isMultiple) {
    var files = localFiles[documentName];
    if (files == null) return false;

    if (isMultiple) {
      return files['front'] != null && files['back'] != null;
    } else {
      return files['single'] != null;
    }
  }
}
