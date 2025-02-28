// To parse this JSON data, do
//
//     final faqListInfo = faqListInfoFromJson(jsonString);

import 'dart:convert';

FaqListInfo faqListInfoFromJson(String str) => FaqListInfo.fromJson(json.decode(str));

String faqListInfoToJson(FaqListInfo data) => json.encode(data.toJson());

class FaqListInfo {
  List<FaqDatum>? faqData;
  String? responseCode;
  String? result;
  String? responseMsg;

  FaqListInfo({
    this.faqData,
    this.responseCode,
    this.result,
    this.responseMsg,
  });

  factory FaqListInfo.fromJson(Map<String, dynamic> json) => FaqListInfo(
    faqData: json["FaqData"] == null ? [] : List<FaqDatum>.from(json["FaqData"]!.map((x) => FaqDatum.fromJson(x))),
    responseCode: json["ResponseCode"],
    result: json["Result"],
    responseMsg: json["ResponseMsg"],
  );

  Map<String, dynamic> toJson() => {
    "FaqData": faqData == null ? [] : List<dynamic>.from(faqData!.map((x) => x.toJson())),
    "ResponseCode": responseCode,
    "Result": result,
    "ResponseMsg": responseMsg,
  };
}

class FaqDatum {
  String? id;
  String? question;
  String? answer;
  String? status;

  FaqDatum({
    this.id,
    this.question,
    this.answer,
    this.status,
  });

  factory FaqDatum.fromJson(Map<String, dynamic> json) => FaqDatum(
    id: json["id"],
    question: json["question"],
    answer: json["answer"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "question": question,
    "answer": answer,
    "status": status,
  };
}
