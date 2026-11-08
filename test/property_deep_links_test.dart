import 'package:flutter_test/flutter_test.dart';
import 'package:opendoors/utils/property_deep_links.dart';

void main() {
  test('extracts an ID from a verified property URL', () {
    expect(
      PropertyDeepLinks.propertyIdFromUri(
        Uri.parse('https://links.opendoorsapp.com/properties/42'),
      ),
      '42',
    );
  });

  test('ignores other hosts, paths, and schemes', () {
    for (final link in [
      'https://admin.opendoorsapp.com/properties/42',
      'http://links.opendoorsapp.com/properties/42',
      'https://links.opendoorsapp.com/reels/42',
      'https://links.opendoorsapp.com/properties/42/extra',
    ]) {
      expect(PropertyDeepLinks.propertyIdFromUri(Uri.parse(link)), isNull);
    }
  });
}
