import 'package:flutter_test/flutter_test.dart';
import 'package:opendoors/utils/otp_code_tracker.dart';

void main() {
  group('OtpCodeTracker', () {
    test('accepts the initially issued code', () {
      final tracker = OtpCodeTracker(123456);

      expect(tracker.accepts('123456'), isTrue);
    });

    test('keeps an earlier code valid after a resend', () {
      final tracker = OtpCodeTracker('123456')..add(654321);

      expect(tracker.accepts('123456'), isTrue);
      expect(tracker.accepts('654321'), isTrue);
    });

    test('normalizes surrounding whitespace and rejects unknown codes', () {
      final tracker = OtpCodeTracker(' 123456 ');

      expect(tracker.accepts('123456'), isTrue);
      expect(tracker.accepts('000000'), isFalse);
    });

    test('ignores missing codes', () {
      final tracker = OtpCodeTracker()..add(null);

      expect(tracker.accepts(''), isFalse);
    });
  });
}
