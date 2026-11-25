import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:opendoors/controller/property_filter_controller.dart';
import 'package:opendoors/controller/search_controller.dart';

void main() {
  late SearchFilterController filters;

  setUp(() {
    Get.reset();
    Get.put(SearchPropertyController());
    filters = SearchFilterController();
  });

  tearDown(Get.reset);

  test('does not apply an upper price cap at the slider maximum', () {
    filters.priceRange.value = const RangeValues(
      0,
      SearchFilterController.maximumPrice,
    );

    expect(filters.effectiveMinPrice, 0);
    expect(filters.effectiveMaxPrice, 0);
    expect(filters.hasActiveFilters, isFalse);
  });

  test('bedroom and bounded price selections activate filtering', () {
    filters.selectedRooms.value = 2;
    filters.priceRange.value = const RangeValues(50000, 250000);

    expect(filters.effectiveMinPrice, 50000);
    expect(filters.effectiveMaxPrice, 250000);
    expect(filters.hasActiveFilters, isTrue);
  });
}
