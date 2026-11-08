import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/model/homedata_info.dart';

class NearbyPropertiesApi {
  static const int _pageSize = 10;

  Future<List<Property>> fetch({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
    String? countryId,
  }) async {
    final properties = <Property>[];
    final seenIds = <String>{};
    for (var offset = 0;; offset += _pageSize) {
      final response = await http
          .post(
            Uri.parse(Config.path + Config.nearbyProperties),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'radius_km': radiusKm,
              'limit': _pageSize,
              'offset': offset,
              if (countryId != null && countryId.trim().isNotEmpty)
                'country_id': countryId.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException('Invalid response');
      final rows = propertyRows(decoded);
      if (rows == null) {
        final message = decoded['ResponseMsg']?.toString() ?? '';
        final result = decoded['Result']?.toString().toLowerCase();
        if (result == 'true' && message.toLowerCase().contains('success') ||
            result == 'false' &&
                (message.toLowerCase().contains('no propert') ||
                    message.toLowerCase().contains('not found'))) {
          break;
        }
        throw FormatException(message.isNotEmpty
            ? message
            : 'Unexpected nearby response: ${decoded.keys.join(', ')}');
      }
      var added = 0;
      for (final row in rows.whereType<Map>()) {
        final values = Map<String, dynamic>.from(row);
        final property = Property.fromJson({
          for (final entry in values.entries)
            entry.key: entry.key == 'IS_FAVOURITE'
                ? int.tryParse(entry.value?.toString() ?? '') ?? 0
                : entry.value?.toString(),
          'id': values['id']?.toString() ?? values['prop_id']?.toString(),
          'latitude':
              values['latitude']?.toString() ?? values['lat']?.toString(),
          'longtitude': values['longtitude']?.toString() ??
              values['longitude']?.toString() ??
              values['lng']?.toString(),
        });
        final id = property.id;
        if (id != null && seenIds.add(id)) {
          properties.add(property);
          added++;
        }
      }
      if (rows.length < _pageSize || added == 0) break;
    }
    return properties;
  }

  static List<dynamic>? propertyRows(Map response) {
    for (final key in [
      'nearby_properties',
      'NearbyProperties',
      'Nearby_Properties',
      'Nearby_Property',
      'NearbyProperty',
      'nearbyProperties',
      'nearby_property',
      'nearby_propety',
      'properties',
      'Properties',
      'property_list',
      'PropertyList',
      'data',
      'Data',
    ]) {
      final value = response[key];
      if (value is List) return value;
      if (value is Map) {
        final nested = propertyRows(value);
        if (nested != null) return nested;
      }
    }
    for (final value in response.values) {
      if (value is Map) {
        final nested = propertyRows(value);
        if (nested != null) return nested;
      } else if (value is List &&
          (value.isEmpty ||
              value.first is Map &&
                  ((value.first as Map).containsKey('id') ||
                      (value.first as Map).containsKey('latitude')))) {
        return value;
      }
    }
    return null;
  }
}
