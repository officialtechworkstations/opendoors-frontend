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
  // final GetStorage _storage = GetStorage();

  SearchPropertyController searchController = Get.find();

  // Observables
  var selectedBudget = Rxn<int>();
  var customMinPrice = RxnString();
  var customMaxPrice = RxnString();
  var selectedAmenities = <String>[].obs;
  var isUsingBudgetFilter = true.obs;

  List<AmenityOption> amenityOptions = [];
  List<String> selectedAmenitiesIds = [];

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

      var response = await http.get(
        uri,
      );
      print("response amenity::::::::::::::::: {${response.body}}");

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);

        final List<dynamic> validItems = result['facilitylist'];

        final List<AmenityOption> activeOptions =
            validItems.map((json) => AmenityOption.fromMap(json)).toList();

        amenityOptions = activeOptions;
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
    save('custom_min_price', customMinPrice.value);
    save('custom_max_price', customMaxPrice.value);
    save('is_using_budget_filter', isUsingBudgetFilter.value);
    save('selected_budget', selectedBudget.value);
    save('selected_amenities', selectedAmenities.toList());
    save('selected_amenities_ids', selectedAmenitiesIds);

    Get.back();
    // Get.snackbar(
    //   'Filters Applied',
    //   'Your search filters have been saved successfully',
    //   snackPosition: SnackPosition.BOTTOM,
    //   backgroundColor: Colors.green,
    //   colorText: Colors.white,
    //   duration: const Duration(seconds: 2),
    // );

    final price = selectedBudget.value;
    final finalPrice = price?.toInt();

    // log(selectedBudget.value.toString());
    // log(selectedAmenities.toList().toString());
    // log(selectedAmenitiesIds.toString());

    searchController.getSearchData(
        countryId: getData.read("countryId"),
        price: finalPrice,
        facility: selectedAmenitiesIds);
  }

  void clearAllFilters() {
    selectedBudget.value = null;
    customMinPrice.value = null;
    customMaxPrice.value = null;
    selectedAmenities.clear();
    selectedAmenitiesIds.clear();
    isUsingBudgetFilter.value = true;

    getData.remove('selected_budget');
    getData.remove('custom_min_price');
    getData.remove('custom_max_price');
    getData.remove('is_using_budget_filter');
    getData.remove('selected_amenities');

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
    if (selectedAmenities.contains(amenity)) {
      selectedAmenities.remove(amenity);
      selectedAmenitiesIds.remove(amenityId);
    } else {
      selectedAmenities.add(amenity);
      selectedAmenitiesIds.add(amenityId);
    }
    update();
  }

  bool get hasActiveFilters =>
      selectedBudget.value != null ||
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
