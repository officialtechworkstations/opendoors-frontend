import 'dart:convert';

MsgotpModel msgotpModelFromJson(String str) =>
    MsgotpModel.fromJson(json.decode(str));

String msgotpModelToJson(MsgotpModel data) => json.encode(data.toJson());

class MsgotpModel {
  String? responseCode;
  String? result;
  String? responseMsg;
  String? challengeId;

  MsgotpModel({
    this.responseCode,
    this.result,
    this.responseMsg,
    this.challengeId,
  });

  factory MsgotpModel.fromJson(Map<String, dynamic> json) => MsgotpModel(
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
        challengeId: json["challenge_id"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
        "challenge_id": challengeId,
      };
}
