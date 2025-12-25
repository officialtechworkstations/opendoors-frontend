// Models
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
  final String name;
  final String description;
  final String uploadType; // 'single' or 'multiple'
  final List<String> acceptableFileTypes;

  DocumentRequirement({
    required this.name,
    required this.description,
    required this.uploadType,
    required this.acceptableFileTypes,
  });

  factory DocumentRequirement.fromJson(Map<String, dynamic> json) {
    return DocumentRequirement(
      name: json['name'],
      description: json['description'],
      uploadType: json['upload_type'],
      acceptableFileTypes: List<String>.from(json['accpetable_file_types']),
    );
  }

  bool get isMultiple => uploadType == 'multiple';
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
    return MyDocumentsResponse(
      documents: (json['documents'] as List)
          .map((doc) => UploadedDocument.fromJson(doc))
          .toList(),
      overallStatus: json['overall_status'],
      responseCode: json['ResponseCode'],
      result: json['Result'],
      responseMsg: json['ResponseMsg'],
    );
  }
}

class UploadedDocument {
  final String name;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final List<DocumentFile> files;

  UploadedDocument({
    required this.name,
    required this.status,
    this.rejectionReason,
    required this.files,
  });

  factory UploadedDocument.fromJson(Map<String, dynamic> json) {
    return UploadedDocument(
      name: json['name'],
      status: json['status'],
      rejectionReason: json['rejection_reason'],
      files: (json['files'] as List)
          .map((file) => DocumentFile.fromJson(file))
          .toList(),
    );
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
