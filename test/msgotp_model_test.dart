import 'package:flutter_test/flutter_test.dart';
import 'package:opendoors/model/msgotp_model.dart';

void main() {
  group('MsgotpModel', () {
    test('parses the server-issued challenge without expecting an OTP', () {
      final model = msgotpModelFromJson('''
        {
          "ResponseCode": "200",
          "Result": "true",
          "ResponseMsg": "OTP sent successfully",
          "challenge_id": "0123456789abcdef0123456789abcdef"
        }
      ''');

      expect(model.responseCode, '200');
      expect(model.result, 'true');
      expect(model.challengeId, '0123456789abcdef0123456789abcdef');
      expect(model.toJson(), isNot(contains('otp')));
    });
  });
}
