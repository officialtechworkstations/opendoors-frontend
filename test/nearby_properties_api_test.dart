import 'package:flutter_test/flutter_test.dart';
import 'package:opendoors/Api/nearby_properties_api.dart';

void main() {
  test('reads a nearby property list from the backend response', () {
    final rows = NearbyPropertiesApi.propertyRows({
      'ResponseMsg': 'Nearby Properties Get Successfully!',
      'Nearby_Property': [
        {'id': '8', 'latitude': '6.45', 'longtitude': '3.4'},
      ],
    });

    expect(rows, hasLength(1));
    expect((rows!.first as Map)['id'], '8');
  });

  test('treats an empty nearby property list as an empty result', () {
    expect(
      NearbyPropertiesApi.propertyRows({'Nearby_Properties': []}),
      isEmpty,
    );
  });
}
