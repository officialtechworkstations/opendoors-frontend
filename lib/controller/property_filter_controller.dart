// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/controller/search_controller.dart';

class SearchFilterController extends GetxController implements GetxService {
  static const double maximumPrice = 3000000;
  static const Map<String, String> _amenityLabels = {
    'swimming pool': 'Swimming Pool',
    'ps5': 'PS5',
    'gym': 'Gym',
    'gym access': 'Gym',
    'wi-fi': 'Wi-Fi',
    'wi-fi available': 'Wi-Fi',
    '24/7 electricity': '24/7 electricity',
    'backup power': '24/7 electricity',
    'balcony': 'Balcony',
    'pool table': 'Pool Table',
    'washing machine': 'Washing Machine',
    'laundry room': 'Washing Machine',
    'kid friendly': 'Kid Friendly',
    'pet friendly': 'Pet Friendly',
    'non-smoke free': 'Non-Smoke Free',
    'event/parties': 'Event/Parties',
    'event/parties allowed': 'Event/Parties',
    'chef available': 'Chef available',
  };
  // final GetStorage _storage = GetStorage();

  SearchPropertyController searchController = Get.find();

  // Observables
  var selectedBudget = Rxn<int>();
  var customMinPrice = RxnString();
  var customMaxPrice = RxnString();
  final priceRange = const RangeValues(0, 3000000).obs;
  final selectedRooms = Rxn<int>();
  var selectedAmenities = <String>[].obs;
  var isUsingBudgetFilter = true.obs;

  List<AmenityOption> amenityOptions = [];
  List<String> selectedAmenitiesIds = [];
  final Map<String, List<String>> _amenityIdsByName = {};

  // Budget options (in Naira)
  final List<int> budgetOptions = [
    1000,
    2000,
    3000,
    5000,
    10000,
    15000,
    20000,
    25000,
    30000,
    35000,
    40000,
    45000,
    50000,
    60000,
    75000,
    100000,
    150000,
    200000,
    250000,
    300000,
    400000,
    500000,
    750000,
    1000000,
    1500000,
    2000000,
    3000000
  ];

  // Amenities with beautiful icons
  // final List<AmenityOption> amenityOptions = [
  //   AmenityOption('Wi-Fi Available', Icons.wifi, Colors.cyan),
  //   AmenityOption('Swimming Pool', Icons.pool, Colors.cyan),
  //   AmenityOption('Generator Included', Icons.power, Colors.orange),
  //   AmenityOption('Pet Friendly', Icons.pets, Colors.green),
  //   AmenityOption('Parking Space', Icons.local_parking, Colors.cyan),
  //   AmenityOption('Air Conditioning', Icons.ac_unit, Colors.lightBlue),
  //   AmenityOption('Kitchen Available', Icons.kitchen, Colors.cyan),
  //   AmenityOption('Furnished', Icons.chair, Colors.cyan),
  //   AmenityOption('Balcony', Icons.balcony, Colors.teal),
  //   AmenityOption('Security', Icons.security, Colors.red),
  //   AmenityOption('Elevator', Icons.elevator, Colors.cyan),
  //   AmenityOption('Gym Access', Icons.fitness_center, Colors.deepOrange),
  //   AmenityOption('Laundry Service', Icons.local_laundry_service, Colors.cyan),
  //   AmenityOption('24/7 Water', Icons.water_drop, Colors.cyan),
  //   AmenityOption('DSTV/Cable', Icons.tv, Colors.cyan),
  //   AmenityOption('Backup Power', Icons.battery_charging_full, Colors.cyan),
  // ];

  @override
  void onInit() {
    super.onInit();
    _loadSavedFilters();
  }

  Future getAmenity({String? countryId}) async {
    try {
      Uri uri = Uri.parse(Config.path + Config.getFacility);
      log("uri {$uri}");

      var response = await http.post(
        uri,
      );
      print("response amenity::::::::::::::::: {${response.body}}");

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);

        final List<dynamic> validItems = result['facilitylist'];

        final List<AmenityOption> activeOptions = validItems
            .map((json) =>
                AmenityOption.fromMap(Map<String, dynamic>.from(json)))
            .map((option) => option.copyWith(
                  name: _amenityLabels[option.name.trim().toLowerCase()],
                ))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        final uniqueOptions = <String, AmenityOption>{};
        _amenityIdsByName.clear();
        for (final option in activeOptions) {
          final key = option.name.trim().toLowerCase();
          uniqueOptions.putIfAbsent(key, () => option);
          _amenityIdsByName.putIfAbsent(key, () => []).add(option.id);
        }
        amenityOptions = uniqueOptions.values.toList();
        if (selectedAmenities.isNotEmpty) {
          final selectedKeys = selectedAmenities
              .map((name) => name.trim().toLowerCase())
              .toSet();
          selectedAmenities.assignAll(amenityOptions
              .where((option) =>
                  selectedKeys.contains(option.name.trim().toLowerCase()))
              .map((option) => option.name));
          selectedAmenitiesIds = selectedAmenities
              .expand<String>((name) =>
                  _amenityIdsByName[name.trim().toLowerCase()] ??
                  const <String>[])
              .toSet()
              .toList();
        }
      }
      update();
    } catch (e) {
      print("RRRRRRR");
      print(e.toString());
    }
  }

  void _loadSavedFilters() {
    selectedBudget.value = getData.read('selected_budget');
    customMinPrice.value = getData.read('custom_min_price');
    customMaxPrice.value = getData.read('custom_max_price');
    selectedRooms.value = getData.read<int>('selected_rooms');
    final savedMin = double.tryParse(customMinPrice.value ?? '');
    final savedMax = double.tryParse(customMaxPrice.value ?? '');
    if (savedMin != null || savedMax != null) {
      priceRange.value = RangeValues(
        (savedMin ?? 0).clamp(0, 3000000).toDouble(),
        (savedMax ?? 3000000).clamp(0, 3000000).toDouble(),
      );
    }
    isUsingBudgetFilter.value = getData.read('is_using_budget_filter') ?? true;

    List<dynamic>? savedAmenities = getData.read('selected_amenities');
    List<dynamic>? savedAmenitiesIds = getData.read('selected_amenities_ids');
    if (savedAmenities != null && savedAmenitiesIds != null) {
      selectedAmenities.assignAll(savedAmenities.cast<String>());
      selectedAmenitiesIds.assignAll(savedAmenitiesIds.cast<String>());
    }
    update();
  }

  void saveFilters() {
    customMinPrice.value = priceRange.value.start.round().toString();
    customMaxPrice.value = priceRange.value.end.round().toString();
    save('custom_min_price', customMinPrice.value);
    save('custom_max_price', customMaxPrice.value);
    save('is_using_budget_filter', isUsingBudgetFilter.value);
    save('selected_budget', selectedBudget.value);
    save('selected_amenities', selectedAmenities.toList());
    save('selected_amenities_ids', selectedAmenitiesIds);
    save('selected_rooms', selectedRooms.value);

    Get.back();
    // Get.snackbar(
    //   'Filters Applied',
    //   'Your search filters have been saved successfully',
    //   snackPosition: SnackPosition.BOTTOM,
    //   backgroundColor: Colors.green,
    //   colorText: Colors.white,
    //   duration: const Duration(seconds: 2),
    // );

    // log(selectedBudget.value.toString());
    // log(selectedAmenities.toList().toString());
    // log(selectedAmenitiesIds.toString());

    searchController.getSearchData(
      countryId: getData.read("countryId"),
      rooms: selectedRooms.value,
      minPrice: effectiveMinPrice,
      maxPrice: effectiveMaxPrice,
      facility: selectedAmenitiesIds,
    );
  }

  void clearAllFilters() {
    selectedBudget.value = null;
    customMinPrice.value = null;
    customMaxPrice.value = null;
    priceRange.value = const RangeValues(0, 3000000);
    selectedAmenities.clear();
    selectedAmenitiesIds.clear();
    selectedRooms.value = null;
    isUsingBudgetFilter.value = true;

    getData.remove('selected_budget');
    getData.remove('custom_min_price');
    getData.remove('custom_max_price');
    getData.remove('is_using_budget_filter');
    getData.remove('selected_amenities');
    getData.remove('selected_amenities_ids');
    getData.remove('selected_rooms');

    update();
  }

  void toggleBudgetFilter(bool value) {
    isUsingBudgetFilter.value = value;
    if (value) {
      customMinPrice.value = null;
      customMaxPrice.value = null;
    } else {
      selectedBudget.value = null;
    }
    update();
  }

  void toggleAmenity(String amenity, String amenityId) {
    final ids = _amenityIdsByName[amenity.trim().toLowerCase()] ?? [amenityId];
    if (selectedAmenities.contains(amenity)) {
      selectedAmenities.remove(amenity);
      selectedAmenitiesIds.removeWhere(ids.contains);
    } else {
      selectedAmenities.add(amenity);
      selectedAmenitiesIds.addAll(
        ids.where((id) => !selectedAmenitiesIds.contains(id)),
      );
    }
    update();
  }

  int get effectiveMinPrice =>
      priceRange.value.start <= 0 ? 0 : priceRange.value.start.round();

  int get effectiveMaxPrice =>
      priceRange.value.end >= maximumPrice ? 0 : priceRange.value.end.round();

  bool get hasActiveFilters =>
      selectedBudget.value != null ||
      selectedRooms.value != null ||
      priceRange.value.start > 0 ||
      priceRange.value.end < 3000000 ||
      (customMinPrice.value != null && customMinPrice.value!.isNotEmpty) ||
      (customMaxPrice.value != null && customMaxPrice.value!.isNotEmpty) ||
      selectedAmenities.isNotEmpty;
}

// Amenity model
class AmenityOption {
  final String name;
  final IconData icon;
  final Color color;
  final String id;
  final String img;

  AmenityOption(this.name, this.icon, this.color, this.id, this.img);

  AmenityOption copyWith({String? name}) =>
      AmenityOption(name ?? this.name, icon, color, id, img);

  factory AmenityOption.fromMap(Map<String, dynamic> map) {
    return AmenityOption(
      map['title'] as String,
      _getIcon(map['title']),
      _getColor(map['title']),
      map['id'] as String,
      map['img'] as String,
    );
  }

  static IconData _getIcon(String title) {
    switch (title) {
      case 'Elevator':
        return Icons.elevator;
      case 'Wi-Fi Available':
        return Icons.wifi;
      case 'Swimming Pool':
        return Icons.pool;
      case 'Generator Included':
        return Icons.power;
      case 'Pet Friendly':
        return Icons.pets;
      case 'Parking Space':
        return Icons.local_parking;
      case 'Air Conditioning':
        return Icons.ac_unit;
      case 'Kitchen Available':
        return Icons.kitchen;
      case 'Furnished':
        return Icons.chair;
      case 'Balcony':
        return Icons.balcony;
      case 'Security':
        return Icons.security;
      case 'Gym Access':
        return Icons.fitness_center;
      case 'Laundry Service':
      case 'Laundry room':
        return Icons.local_laundry_service;
      case '24/7 Water':
        return Icons.water_drop;
      case 'DSTV/Cable':
        return Icons.tv;
      case 'Backup Power':
        return Icons.battery_charging_full;
      case 'Rooftop':
        return Icons.roofing;
      default:
        return Icons.holiday_village;
    }
  }
  //   AmenityOption('Wi-Fi Available', Icons.wifi, Colors.cyan),
  //   AmenityOption('Swimming Pool', Icons.pool, Colors.cyan),
  //   AmenityOption('Generator Included', Icons.power, Colors.orange),
  //   AmenityOption('Pet Friendly', Icons.pets, Colors.green),
  //   AmenityOption('Parking Space', Icons.local_parking, Colors.cyan),
  //   AmenityOption('Air Conditioning', Icons.ac_unit, Colors.lightBlue),
  //   AmenityOption('Kitchen Available', Icons.kitchen, Colors.cyan),
  //   AmenityOption('Furnished', Icons.chair, Colors.cyan),
  //   AmenityOption('Balcony', Icons.balcony, Colors.teal),
  //   AmenityOption('Security', Icons.security, Colors.red),
  //   AmenityOption('Elevator', Icons.elevator, Colors.cyan),
  //   AmenityOption('Gym Access', Icons.fitness_center, Colors.deepOrange),
  //   AmenityOption('Laundry Service', Icons.local_laundry_service, Colors.cyan),
  //   AmenityOption('24/7 Water', Icons.water_drop, Colors.cyan),
  //   AmenityOption('DSTV/Cable', Icons.tv, Colors.cyan),
  //   AmenityOption('Backup Power', Icons.battery_charging_full, Colors.cyan),

  static Color _getColor(String title) {
    switch (title) {
      case 'Elevator':
        return Colors.cyan;
      case 'Wi-Fi Available':
        return Colors.cyan;
      case 'Swimming Pool':
        return Colors.cyan;
      case 'Generator Included':
        return Colors.orange;
      case 'Pet Friendly':
        return Colors.green;
      case 'Parking Space':
        return Colors.cyan;
      case 'Air Conditioning':
        return Colors.lightBlue;
      case 'Kitchen Available':
        return Colors.cyan;
      case 'Furnished':
        return Colors.cyan;
      case 'Balcony':
        return Colors.teal;
      case 'Security':
        return Colors.red;
      case 'Gym Access':
        return Colors.deepOrange;
      case 'Laundry Service':
      case 'Laundry room':
        return Colors.cyan;
      case '24/7 Water':
        return Colors.cyan;
      case 'DSTV/Cable':
        return Colors.cyan;
      case 'Backup Power':
        return Colors.cyan;
      case 'Rooftop':
        return Colors.grey;
      default:
        return Colors.cyan;
    }
  }
}
