// Models
import 'dart:developer';

class RequiredDocumentsResponse {
  final List<DocumentRequirement> documents;
  final int responseCode;
  final String result;
  final String responseMsg;

  RequiredDocumentsResponse({
    required this.documents,
    required this.responseCode,
    required this.result,
    required this.responseMsg,
  });

  factory RequiredDocumentsResponse.fromJson(Map<String, dynamic> json) {
    return RequiredDocumentsResponse(
      documents: (json['documents'] as List)
          .map((doc) => DocumentRequirement.fromJson(doc))
          .toList(),
      responseCode: json['ResponseCode'],
      result: json['Result'],
      responseMsg: json['ResponseMsg'],
    );
  }
}

class DocumentRequirement {
  final String id;
  final String name;
  final String description;
  final String uploadType; // 'single' or 'multiple'
  final List<String> acceptableFileTypes;

  DocumentRequirement({
    required this.id,
    required this.name,
    required this.description,
    required this.uploadType,
    required this.acceptableFileTypes,
  });

  factory DocumentRequirement.fromJson(Map<String, dynamic> json) {
    return DocumentRequirement(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      uploadType: json['upload_type'],
      acceptableFileTypes: List<String>.from(json['accpetable_file_types']),
    );
  }

  bool get isMultiple => uploadType == 'multiple';
  bool get acceptsPdf => acceptableFileTypes.contains('pdf');
  bool get acceptsImage => acceptableFileTypes.contains('image');
}

class MyDocumentsResponse {
  final List<UploadedDocument> documents;
  final String overallStatus; // 'pending', 'approved', 'rejected', 'incomplete'
  final int responseCode;
  final String result;
  final String responseMsg;

  MyDocumentsResponse({
    required this.documents,
    required this.overallStatus,
    required this.responseCode,
    required this.result,
    required this.responseMsg,
  });

  factory MyDocumentsResponse.fromJson(Map<String, dynamic> json) {
    try {
      return MyDocumentsResponse(
        documents: (json['documents'] as List)
            .map((doc) => UploadedDocument.fromJson(doc))
            .toList(),
        overallStatus: getOveralStatus(json['documents']) ?? 'incomplete',
        responseCode: json['ResponseCode'],
        result: json['Result'],
        responseMsg: json['ResponseMsg'],
      );
    } catch (e, s) {
      // This will show you *which* line blows up
      log('>>>  MyDocumentsResponse.fromJson  <<< $e');
      log(s.toString());
      rethrow;
    }
  }
}

getOveralStatus(List<dynamic> documents) {
  if (documents.any((doc) => doc['status'] == 'rejected')) {
    return 'rejected';
  } else if (documents.every((doc) => doc['status'] == 'approved')) {
    return 'approved';
  } else if (documents.any((doc) => doc['status'] == 'pending')) {
    return 'pending';
  } else {
    return 'incomplete';
  }
}

class UploadedDocument {
  final String name;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final String uploadType; // 'single' or 'multiple'
  final List<DocumentFile> files;

  UploadedDocument({
    required this.name,
    required this.status,
    this.rejectionReason,
    required this.uploadType,
    required this.files,
  });

  factory UploadedDocument.fromJson(Map<String, dynamic> json) {
    return UploadedDocument(
      name: json['name'],
      status: json['status'],
      rejectionReason: json['reason'],
      uploadType: json['upload_type'],
      files: makeFilesListAndHandleListWithTwoLenghthForBackAndFront(
          List<String>.from(json['files']), json['upload_type']),
      //  (json['files'] as List)
      //     .map((file) => DocumentFile.fromJson(file))
      //     .toList(),
    );
  }
// "files":["http:\/\/admin.opendoorsapp.com\/uploads\/7_35_694a9f0c80b9a.jpg"]
  static List<DocumentFile>
      makeFilesListAndHandleListWithTwoLenghthForBackAndFront(
          List<String> files, String uploadType) {
    List<DocumentFile> documentFiles = [];
    if (files.length == 1 && uploadType == 'single') {
      documentFiles.add(DocumentFile(url: files[0], type: 'single'));
    } else if (uploadType == 'multiple') {
      for (var i = 0; i < files.length; i++) {
        String type = (i == 0)
            ? 'front'
            : (i == 1)
                ? 'back'
                : 'other';
        documentFiles.add(DocumentFile(url: files[i], type: type));
      }
    } else {
      // documentFiles.add(DocumentFile(url: files[0], type: 'front'));
      // documentFiles.add(DocumentFile(url: files[1], type: 'back'));
    }
    return documentFiles;
  }
}

class DocumentFile {
  final String url;
  final String type; // 'front', 'back', or 'single'

  DocumentFile({
    required this.url,
    required this.type,
  });

  factory DocumentFile.fromJson(Map<String, dynamic> json) {
    return DocumentFile(
      url: json['url'],
      type: json['type'],
    );
  }
}
