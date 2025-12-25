// Controller
import 'dart:math';
import 'dart:developer' as log;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/screen/kyc/widget2/kyc_model.dart';

class KYC2Controller extends GetxController {
  final Color primaryColor = const Color(0xffFF4D00);

  var isLoadingRequirements = true.obs;
  var isLoadingMyDocuments = true.obs;
  var isUploading = false.obs;

  var requiredDocuments = <DocumentRequirement>[].obs;
  var uploadedDocuments = <UploadedDocument>[].obs;
  var overallStatus = 'incomplete'.obs;

  // Local file storage for pending uploads
  var localFiles = <String, Map<String, File?>>{}.obs;

  final ImagePicker _imagePicker = ImagePicker();

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
      // await Future.delayed(const Duration(seconds: 1));

      // var mockResponse = {
      //   "documents": [
      //     {
      //       "id": "8",
      //       "name": "CAC Document",
      //       "description": "A CAC document confirming that your business is registered in Nigeria",
      //       "upload_type": "multiple",
      //       "accpetable_file_types": ["pdf", "image"]
      //     },
      //     {
      //       "id": "7",
      //       "name": "Business logo",
      //       "description": "An image of your business logo",
      //       "upload_type": "single",
      //       "accpetable_file_types": ["image"]
      //     },
      //     {
      //       "id": "9",
      //       "name": "Tax Identification Number",
      //       "description": "Your valid TIN certificate",
      //       "upload_type": "single",
      //       "accpetable_file_types": ["pdf", "image"]
      //     }
      //   ],
      //   "ResponseCode": 200,
      //   "Result": "true",
      //   "ResponseMsg": "Required documents retrieved"
      // };

      // var docsResponse = RequiredDocumentsResponse.fromJson(mockResponse);
      // requiredDocuments.value = docsResponse.documents;
      // Actual API call:
      final userId = getData.read("UserLogin")["id"].toString();
      const userType = 'host';
      var map = {
        "uid": userId,
        "user_type": userType,
      };

      log.log(map.toString());

      var response = await http.post(
        Uri.parse(Config.path + Config.getRequiredDocumentsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(map),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        log.log(data.toString());
        var docsResponse = RequiredDocumentsResponse.fromJson(data);
        requiredDocuments.value = docsResponse.documents;
      }

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
      // await Future.delayed(const Duration(seconds: 1));

      // var mockResponse = {
      //   "documents": [
      //     {
      //       "name": "CAC Document",
      //       "status": "approved",
      //       "rejection_reason": null,
      //       "files": [
      //         {
      //           "url":
      //               "https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=CAC+Front",
      //           "type": "front"
      //         },
      //         {
      //           "url":
      //               "https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=CAC+Back",
      //           "type": "back"
      //         }
      //       ]
      //     },
      //     {
      //       "name": "Business logo",
      //       "status": "rejected",
      //       "rejection_reason":
      //           "Logo is not clear. Please upload a higher resolution image.",
      //       "files": [
      //         {
      //           "url":
      //               "https://via.placeholder.com/400x300/F44336/FFFFFF?text=Logo",
      //           "type": "single"
      //         }
      //       ]
      //     }
      //   ],
      //   "overall_status": "pending",
      //   "ResponseCode": 200,
      //   "Result": "true",
      //   "ResponseMsg": "Documents retrieved"
      // };
      // var myDocsResponse = MyDocumentsResponse.fromJson(mockResponse);
      // uploadedDocuments.value = myDocsResponse.documents;
      // overallStatus.value = myDocsResponse.overallStatus;

      // Actual API call:
      final userId = getData.read("UserLogin")["id"].toString();
      const userType = 'host';

      var response = await http.get(
        Uri.parse(
            '${Config.path}${Config.getMyDocumentsUrl}?uid=$userId&user_type=$userType'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // log.log('Response Status: ${response.statusCode}');
      // log.log('Response Body: ${response.body}');
      // log.log('Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var myDocsResponse = MyDocumentsResponse.fromJson(data);
        // log.log(myDocsResponse.toString());
        // log.log(myDocsResponse.documents.toString());
        // log.log(myDocsResponse.overallStatus.toString());

        uploadedDocuments.value = myDocsResponse.documents;
        overallStatus.value = myDocsResponse.overallStatus;

        uploadedDocuments.refresh();
        overallStatus.refresh();
        localFiles.refresh();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load your documents');
    } finally {
      isLoadingMyDocuments.value = false;
      // refresh();
      update();
      uploadedDocuments.refresh();
      overallStatus.refresh();
      localFiles.refresh();
    }
  }

  Future<void> pickDocument(String documentName, DocumentRequirement docReq,
      {String? type}) async {
    try {
      // Show options if both PDF and image are accepted
      if (docReq.acceptsPdf && docReq.acceptsImage) {
        await _showFileTypeDialog(documentName, docReq, type: type);
      } else if (docReq.acceptsImage) {
        await _pickImage(documentName, type: type);
      } else if (docReq.acceptsPdf) {
        await _pickPdf(documentName, type: type);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick file');
    }
  }

  Future<void> _showFileTypeDialog(
      String documentName, DocumentRequirement docReq,
      {String? type}) async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Choose File Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (docReq.acceptsImage)
              ListTile(
                leading: Icon(Icons.image, color: primaryColor),
                title: const Text('Image'),
                subtitle: const Text('JPG, PNG'),
                onTap: () {
                  Get.back();
                  _pickImage(documentName, type: type);
                },
              ),
            if (docReq.acceptsPdf)
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: primaryColor),
                title: const Text('PDF Document'),
                subtitle: const Text('PDF files'),
                onTap: () {
                  Get.back();
                  _pickPdf(documentName, type: type);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(String documentName, {String? type}) async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File file = File(image.path);

      if (type != null) {
        localFiles[documentName]![type] = file;
      } else {
        localFiles[documentName]!['single'] = file;
      }

      localFiles.refresh(); // Force GetX to detect nested change
    }
  }

  Future<void> _pickPdf(String documentName, {String? type}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);

      if (type != null) {
        localFiles[documentName]![type] = file;
      } else {
        localFiles[documentName]!['single'] = file;
      }
      localFiles.refresh();

      update();
    }
  }

  Future<void> submitAllDocuments(int userId) async {
    try {
      isUploading.value = true;

      // Track results for each document
      List<Map<String, dynamic>> uploadResults = [];
      int successCount = 0;
      int failCount = 0;

      // Get all documents that have local files
      List<DocumentRequirement> docsToUpload = [];
      for (var doc in requiredDocuments) {
        var files = localFiles[doc.name];
        if (files != null && files.values.any((file) => file != null)) {
          docsToUpload.add(doc);
        }
      }

      if (docsToUpload.isEmpty) {
        Get.snackbar('Error', 'Please select at least one document to upload');
        return;
      }

      // Upload each document separately
      for (var doc in docsToUpload) {
        try {
          var files = localFiles[doc.name]!;

          // Mock API call - Replace with actual multipart upload
          // await Future.delayed(const Duration(seconds: 1));

          // Actual API call:
          var request = http.MultipartRequest(
            'POST',
            Uri.parse(Config.path + Config.uploadDocumentUrl),
          );

          request.fields['uid'] = userId.toString();
          request.fields['document_id'] = doc.id;

          for (var entry in files.entries) {
            log.log(files.length.toString());
            log.log(entry.value.toString());
            if (entry.value != null) {
              File file = entry.value!;
              final mimeType = _getMimeType(file.path);

              request.files.add(
                await http.MultipartFile.fromPath(
                  'file[]',
                  file.path,
                  contentType: MediaType.parse(mimeType),
                ),
              );
            }
          }

          var response = await request.send();
          var responseData = await response.stream.bytesToString();

          log.log('Upload Response Status: ${response.statusCode}');
          log.log('Upload Response Body: $responseData');
          log.log('Upload Response Headers: ${response.headers}');

          if (response.statusCode == 200) {
            var data = jsonDecode(responseData);
            // Check if upload was successful
            if (data['ResponseCode'] == 200) {
              successCount++;
              uploadResults.add({
                'name': doc.name,
                'success': true,
              });
            } else {
              failCount++;
              uploadResults.add({
                'name': doc.name,
                'success': false,
                'error': data['ResponseMsg'] ?? 'Upload failed',
              });
            }
          } else {
            failCount++;
            uploadResults.add({
              'name': doc.name,
              'success': false,
              'error': 'Server error',
            });
          }

          // Mock success for demonstration
          // successCount++;
          // uploadResults.add({
          //   'name': doc.name,
          //   'success': true,
          // });
        } catch (e) {
          failCount++;
          uploadResults.add({
            'name': doc.name,
            'success': false,
            'error': e.toString(),
          });
        }
      }

      // Show comprehensive result
      if (failCount == 0) {
        // All successful
        Get.snackbar(
          'Success',
          'All documents uploaded successfully!',
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      } else if (successCount > 0) {
        // Partial success
        String failedDocs = uploadResults
            .where((r) => r['success'] == false)
            .map((r) => r['name'])
            .join(', ');

        Get.snackbar(
          'Partial Success',
          '$successCount uploaded successfully. Failed: $failedDocs',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          icon: const Icon(Icons.warning, color: Colors.white),
        );
      } else {
        // All failed
        Get.snackbar(
          'Upload Failed',
          'Failed to upload documents. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }

      // Refresh documents to get updated status
      await fetchMyDocuments();

      // Clear local files only for successfully uploaded documents
      for (var result in uploadResults) {
        if (result['success'] == true) {
          String docName = result['name'];
          var doc = requiredDocuments.firstWhere((d) => d.name == docName);
          if (doc.isMultiple) {
            localFiles[docName] = {'front': null, 'back': null};
          } else {
            localFiles[docName] = {'single': null};
          }
        }
      }

      localFiles.refresh();
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
    // log.log(uploadedDocuments.first.name);
    // log.log(documentName);
    var doc = uploadedDocuments.firstWhereOrNull((d) => d.name == documentName);
    // log.log(doc?.files.first.type.toString() ?? 'No files');
    if (doc == null) return false;

    if (type != null) {
      // log.log(type);
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

  bool canSubmit() {
    // Check if at least one document has new local files
    for (var entry in localFiles.entries) {
      if (entry.value.values.any((file) => file != null)) {
        return true;
      }
    }
    return false;
  }

  bool isPdf(File file) {
    return file.path.toLowerCase().endsWith('.pdf');
  }

  String _getMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;

    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
}


// v1
// class KYC2Controller extends GetxController implements GetxService {
//   final Color primaryColor = const Color(0xffFF4D00);

//   var isLoadingRequirements = true.obs;
//   var isLoadingMyDocuments = true.obs;
//   var isUploading = false.obs;

//   var requiredDocuments = <DocumentRequirement>[].obs;
//   var uploadedDocuments = <UploadedDocument>[].obs;
//   var overallStatus = 'incomplete'.obs;

//   // Local file storage for pending uploads
//   var localFiles = <String, Map<String, File?>>{}.obs;

//   final ImagePicker _imagePicker = ImagePicker();

//   @override
//   void onInit() {
//     super.onInit();
//     fetchRequiredDocuments();
//     fetchMyDocuments();
//   }

//   Future<void> fetchRequiredDocuments() async {
//     try {
//       isLoadingRequirements.value = true;

//       // Mock API call - Replace with actual API
//       await Future.delayed(const Duration(seconds: 1));

//       var mockResponse = {
//         "documents": [
//           {
//             "name": "CAC Document",
//             "description":
//                 "A CAC document confirming that your business is registered in Nigeria",
//             "upload_type": "multiple",
//             "accpetable_file_types": ["pdf", "image"]
//           },
//           {
//             "name": "Business logo",
//             "description": "An image of your business logo",
//             "upload_type": "single",
//             "accpetable_file_types": ["image"]
//           },
//           {
//             "name": "Tax Identification Number",
//             "description": "Your valid TIN certificate",
//             "upload_type": "single",
//             "accpetable_file_types": ["pdf", "image"]
//           }
//         ],
//         "ResponseCode": 200,
//         "Result": "true",
//         "ResponseMsg": "Required documents retrieved"
//       };

//       /* Actual API call:
//       Map map = {
//         // "uid": userId,
//         "user_type": userType,
//       };
//       var response = await http.post(
//         Uri.parse(Config.path + Config.getRequiredDocumentsUrl),
//         body: jsonEncode(map),
//         headers: {'Content-Type': 'application/json'},
//       );
      
//       if (response.statusCode == 200) {
//         var data = jsonDecode(response.body);
//         var docsResponse = RequiredDocumentsResponse.fromJson(data);
//         requiredDocuments.value = docsResponse.documents;
//       }
//       */

//       var docsResponse = RequiredDocumentsResponse.fromJson(mockResponse);
//       requiredDocuments.value = docsResponse.documents;

//       // Initialize local files map
//       for (var doc in requiredDocuments) {
//         if (doc.isMultiple) {
//           localFiles[doc.name] = {'front': null, 'back': null};
//         } else {
//           localFiles[doc.name] = {'single': null};
//         }
//       }
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to load required documents');
//     } finally {
//       isLoadingRequirements.value = false;
//     }
//   }

//   Future<void> fetchMyDocuments() async {
//     try {
//       isLoadingMyDocuments.value = true;

//       // Mock API call - Replace with actual API
//       await Future.delayed(const Duration(seconds: 1));

//       var mockResponse = {
//         "documents": [
//           {
//             "name": "CAC Document",
//             "status": "approved",
//             "rejection_reason": null,
//             "files": [
//               {
//                 "url":
//                     "https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=CAC+Front",
//                 "type": "front"
//               },
//               {
//                 "url":
//                     "https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=CAC+Back",
//                 "type": "back"
//               }
//             ]
//           },
//           {
//             "name": "Business logo",
//             "status": "rejected",
//             "rejection_reason":
//                 "Logo is not clear. Please upload a higher resolution image.",
//             "files": [
//               {
//                 "url":
//                     "https://via.placeholder.com/400x300/F44336/FFFFFF?text=Logo",
//                 "type": "single"
//               }
//             ]
//           }
//         ],
//         "overall_status": "pending",
//         "ResponseCode": 200,
//         "Result": "true",
//         "ResponseMsg": "Documents retrieved"
//       };

//       /* Actual API call: uid={user_id}&user_type={host|user}
//           final userId = getData.read("UserLogin")["id"].toString();
//           final userType = 'host';

//       var response = await http.get(
//         Uri.parse(Config.path + Config.getMyDocumentsUrl + '?uid=${userId}&user_type=${userType}'),
//         headers: {'Content-Type': 'application/json'},
//       );
      
//       if (response.statusCode == 200) {
//         var data = jsonDecode(response.body);
//         var myDocsResponse = MyDocumentsResponse.fromJson(data);
//         uploadedDocuments.value = myDocsResponse.documents;
//         overallStatus.value = myDocsResponse.overallStatus;
//       }

//        */

//       var myDocsResponse = MyDocumentsResponse.fromJson(mockResponse);
//       uploadedDocuments.value = myDocsResponse.documents;
//       overallStatus.value = myDocsResponse.overallStatus;
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to load your documents');
//     } finally {
//       isLoadingMyDocuments.value = false;
//     }
//   }

//   Future<void> pickDocument(String documentName, DocumentRequirement docReq,
//       {String? type}) async {
//     try {
//       // Show options if both PDF and image are accepted
//       if (docReq.acceptsPdf && docReq.acceptsImage) {
//         await _showFileTypeDialog(documentName, docReq, type: type);
//       } else if (docReq.acceptsImage) {
//         await _pickImage(documentName, type: type);
//       } else if (docReq.acceptsPdf) {
//         await _pickPdf(documentName, type: type);
//       }
//       update();
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to pick file');
//     }
//   }

//   Future<void> _showFileTypeDialog(
//       String documentName, DocumentRequirement docReq,
//       {String? type}) async {
//     await Get.dialog(
//       AlertDialog(
//         title: const Text('Choose File Type'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (docReq.acceptsImage)
//               ListTile(
//                 leading: Icon(Icons.image, color: primaryColor),
//                 title: const Text('Image'),
//                 subtitle: const Text('JPG, PNG'),
//                 onTap: () {
//                   Get.back();
//                   _pickImage(documentName, type: type);
//                 },
//               ),
//             if (docReq.acceptsPdf)
//               ListTile(
//                 leading: Icon(Icons.picture_as_pdf, color: primaryColor),
//                 title: const Text('PDF Document'),
//                 subtitle: const Text('PDF files'),
//                 onTap: () {
//                   Get.back();
//                   _pickPdf(documentName, type: type);
//                 },
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _pickImage(String documentName, {String? type}) async {
//     final XFile? image =
//         await _imagePicker.pickImage(source: ImageSource.gallery);

//     if (image != null) {
//       File file = File(image.path);

//       if (type != null) {
//         localFiles[documentName]![type] = file;
//       } else {
//         localFiles[documentName]!['single'] = file;
//       }

//       update();
//       localFiles.refresh();
//     }
//   }

//   Future<void> _pickPdf(String documentName, {String? type}) async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf'],
//     );

//     if (result != null && result.files.single.path != null) {
//       File file = File(result.files.single.path!);

//       if (type != null) {
//         localFiles[documentName]![type] = file;
//       } else {
//         localFiles[documentName]!['single'] = file;
//       }

//       update();
//       localFiles.refresh();
//     }
//   }

//   Future<void> submitAllDocuments(int userId) async {
//     try {
//       isUploading.value = true;

//       // Collect all files to upload
//       List<File> allFiles = [];
//       for (var entry in localFiles.entries) {
//         for (var file in entry.value.values) {
//           if (file != null) {
//             allFiles.add(file);
//           }
//         }
//       }

//       if (allFiles.isEmpty) {
//         Get.snackbar('Error', 'Please select at least one document to upload');
//         return;
//       }

//       // Mock API call - Replace with actual multipart upload
//       await Future.delayed(const Duration(seconds: 3));

//       /* Actual API call:
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse(Config.path + Config.uploadDocumentUrl),
//       );
      
//       request.fields['uid'] = userId.toString();
      
//       for (var file in allFiles) {
//         request.files.add(
//           await http.MultipartFile.fromPath('file', file.path),
//         );
//       }
      
//       var response = await request.send();
//       var responseData = await response.stream.bytesToString();
      
//       if (response.statusCode == 200) {
//         var data = jsonDecode(responseData);
//         // Handle success
//       }
//       */

//       Get.snackbar(
//         'Success',
//         'All documents uploaded successfully',
//         backgroundColor: primaryColor.withOpacity(0.9),
//         colorText: Colors.white,
//         duration: const Duration(seconds: 3),
//       );

//       // // Refresh documents
//       // await fetchMyDocuments();

//       // Clear all local files
//       for (var docName in localFiles.keys) {
//         var doc = requiredDocuments.firstWhere((d) => d.name == docName);
//         if (doc.isMultiple) {
//           localFiles[docName] = {'front': null, 'back': null};
//         } else {
//           localFiles[docName] = {'single': null};
//         }
//       }
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to upload documents');
//     } finally {
//       isUploading.value = false;
//       // print('Upload process completed');
//       // Get.back();
//     }
//   }

//   bool hasLocalFile(String documentName, {String? type}) {
//     var files = localFiles[documentName];
//     if (files == null) return false;

//     if (type != null) {
//       return files[type] != null;
//     } else {
//       return files['single'] != null;
//     }
//   }

//   bool hasUploadedFile(String documentName, {String? type}) {
//     var doc = uploadedDocuments.firstWhereOrNull((d) => d.name == documentName);
//     if (doc == null) return false;

//     if (type != null) {
//       return doc.files.any((f) => f.type == type);
//     } else {
//       return doc.files.isNotEmpty;
//     }
//   }

//   String? getUploadedFileUrl(String documentName, {String? type}) {
//     var doc = uploadedDocuments.firstWhereOrNull((d) => d.name == documentName);
//     if (doc == null) return null;

//     if (type != null) {
//       return doc.files.firstWhereOrNull((f) => f.type == type)?.url;
//     } else {
//       return doc.files.isNotEmpty ? doc.files.first.url : null;
//     }
//   }

//   String getDocumentStatus(String documentName) {
//     var doc = uploadedDocuments.firstWhereOrNull((d) => d.name == documentName);
//     return doc?.status ?? 'not_uploaded';
//   }

//   String? getRejectionReason(String documentName) {
//     var doc = uploadedDocuments.firstWhereOrNull((d) => d.name == documentName);
//     return doc?.rejectionReason;
//   }

//   bool canSubmit() {
//     // Check if at least one document has new local files
//     for (var entry in localFiles.entries) {
//       if (entry.value.values.any((file) => file != null)) {
//         return true;
//       }
//     }
//     return false;
//   }

//   bool isPdf(File file) {
//     return file.path.toLowerCase().endsWith('.pdf');
//   }
// }
