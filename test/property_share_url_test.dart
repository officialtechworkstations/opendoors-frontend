import 'package:flutter_test/flutter_test.dart';
import 'package:opendoors/model/propetydetails_Info.dart';

void main() {
  test('reads a public share URL from property details', () {
    final result = PropetydetailsInfo.fromJson({
      'propetydetails': {
        'id': '42',
        'title': 'Oneil James',
        'image': <Object>[],
        'share_url': 'https://example.com/properties/42',
      },
    });
    expect(result.propetydetails?.shareUrl,
        'https://example.com/properties/42');
  });

  test('uses a top-level share URL when the property has none', () {
    final result = PropetydetailsInfo.fromJson({
      'propetydetails': {'id': '42', 'image': <Object>[]},
      'share_url': 'https://example.com/properties/42',
    });
    expect(result.propetydetails?.shareUrl,
        'https://example.com/properties/42');
  });

  test('ignores invalid share URLs', () {
    final result = PropetydetailsInfo.fromJson({
      'propetydetails': {
        'id': '42',
        'image': <Object>[],
        'share_url': 'not-a-public-link',
      },
    });
    expect(result.propetydetails?.shareUrl, isNull);
  });
}
