// Main Search Screen with Filter Integration
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opendoors/controller/property_filter_controller.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Custom_widget.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:provider/provider.dart';

class PropertySearchScreen extends StatelessWidget {
  final TextEditingController searchController = TextEditingController();
  final SearchFilterController filterController =
      Get.put(SearchFilterController());

  PropertySearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Find Your Perfect Stay',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Search Bar with Filter Button
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by location, property type...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Button with Badge
                Obx(() => Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: filterController.hasActiveFilters
                                ? Colors.blue
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: filterController.hasActiveFilters
                                    ? Colors.blue
                                    : Colors.grey[300]!),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.tune,
                              color: filterController.hasActiveFilters
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                            onPressed: () => _showFilterBottomSheet(context),
                          ),
                        ),
                        if (filterController.hasActiveFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    )),
              ],
            ),
          ),

          // Active Filters Display
          Obx(() => filterController.hasActiveFilters
              ? Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue[50],
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (filterController.selectedBudget.value != null)
                        _buildFilterChip(
                            '₦${_formatNumber(filterController.selectedBudget.value!)} per night'),
                      if (filterController.customMinPrice.value != null ||
                          filterController.customMaxPrice.value != null)
                        _buildFilterChip(
                            '₦${filterController.customMinPrice.value ?? '0'} - ₦${filterController.customMaxPrice.value ?? '∞'}'),
                      ...filterController.selectedAmenities
                          .map((amenity) => _buildFilterChip(amenity)),
                    ],
                  ),
                )
              : const SizedBox.shrink()),

          // Property Results
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 10, // Placeholder
              itemBuilder: (context, index) => _buildPropertyCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.blue[800]),
      ),
      backgroundColor: Colors.blue[100],
      deleteIcon: Icon(Icons.close, size: 16, color: Colors.blue[800]),
      onDeleted: () {
        // Handle individual filter removal
      },
    );
  }

  Widget _buildPropertyCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: Icon(Icons.home, size: 80, color: Colors.grey[400]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modern 2-Bedroom Apartment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Victoria Island, Lagos',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '₦75,000/night',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(number % 1000000 == 0 ? 0 : 1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}K';
    }
    return number.toString();
  }
}

// Filter Bottom Sheet
class FilterBottomSheet extends StatelessWidget {
  final SearchFilterController controller = Get.find<SearchFilterController>();

  FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final notifire = Provider.of<ColorNotifire>(context, listen: true);
    final isDark = notifire.isDark;
    final sheetBgColor = isDark ? const Color(0xFF18181a) : Colors.white;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: sheetBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: isDark ? Colors.grey[900]! : Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: controller.clearAllFilters,
                  icon: const Icon(Icons.delete_forever,
                      size: 14, color: Colors.red),
                  label:
                      const Text('Clear', style: TextStyle(color: Colors.red)),
                ),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    color: notifire.getwhiteblackcolor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.cancel_outlined,
                      color: notifire.getwhiteblackcolor,
                    )),
              ],
            ),
          ),

          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceSection(context),
                  const SizedBox(height: 10),
                  const Divider(
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 14),
                  _buildAmenitiesSection(context),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: GestButton(
              Width: Get.size.width,
              height: 50,
              buttoncolor: Darkblue,
              margin: const EdgeInsets.only(top: 10, right: 10, bottom: 10),
              buttontext: "Apply",
              onclick: () {
                controller.saveFilters();
              },
              style: TextStyle(
                fontFamily: FontFamily.gilroyBold,
                color: WhiteColor,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(
            height: 30,
          )
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    final notifire = Provider.of<ColorNotifire>(context, listen: true);
    final isDark = notifire.isDark;
    final sheetBgColor =
        isDark ? const Color.fromARGB(255, 41, 41, 43) : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price / Night',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: notifire.getwhiteblackcolor),
        ),
        const SizedBox(
          height: 6,
        ),
        const Text(
          'select the price range for your budget',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        // const SizedBox(height: 16),

        // Toggle between Budget and Custom Range
        // Obx(() => Row(
        //       children: [
        //         Expanded(
        //           child: GestureDetector(
        //             onTap: () => controller.toggleBudgetFilter(true),
        //             child: Container(
        //               padding: const EdgeInsets.symmetric(vertical: 10),
        //               decoration: BoxDecoration(
        //                 color: controller.isUsingBudgetFilter.value
        //                     ? blueColor.withAlpha(200) // Colors.green
        //                     : Colors.grey[100],
        //                 borderRadius: BorderRadius.circular(8),
        //               ),
        //               child: Text(
        //                 'Budget',
        //                 textAlign: TextAlign.center,
        //                 style: TextStyle(
        //                   color: controller.isUsingBudgetFilter.value
        //                       ? Colors.white
        //                       : Colors.grey[600],
        //                   fontWeight: FontWeight.w500,
        //                 ),
        //               ),
        //             ),
        //           ),
        //         ),
        //         const SizedBox(width: 8),
        //         Expanded(
        //           child: GestureDetector(
        //             onTap: () => controller.toggleBudgetFilter(false),
        //             child: Container(
        //               padding: const EdgeInsets.symmetric(vertical: 10),
        //               decoration: BoxDecoration(
        //                 color: !controller.isUsingBudgetFilter.value
        //                     ? blueColor.withAlpha(200) // Colors.blue
        //                     : Colors.grey[100],
        //                 borderRadius: BorderRadius.circular(8),
        //               ),
        //               child: Text(
        //                 'Custom Range',
        //                 textAlign: TextAlign.center,
        //                 style: TextStyle(
        //                   color: !controller.isUsingBudgetFilter.value
        //                       ? Colors.white
        //                       : Colors.grey[600],
        //                   fontWeight: FontWeight.w500,
        //                 ),
        //               ),
        //             ),
        //           ),
        //         ),
        //       ],
        //     )),

        const SizedBox(height: 16),

        // Budget Options or Custom Range
        Obx(() => controller.isUsingBudgetFilter.value
            ? _buildBudgetOptions(context)
            : _buildCustomRangeInputs()),
      ],
    );
  }

  Widget _buildBudgetOptions(context) {
    final notifire = Provider.of<ColorNotifire>(context, listen: true);
    final isDark = notifire.isDark;
    final sheetBgColor =
        isDark ? const Color.fromARGB(255, 183, 183, 186) : Colors.white;
    // Split budget options into two rows for horizontal scrolling
    List<List<int>> budgetRows = [
      controller.budgetOptions.sublist(0, controller.budgetOptions.length ~/ 2),
      controller.budgetOptions.sublist(controller.budgetOptions.length ~/ 2),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: budgetRows
          .map((rowBudgets) => Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: rowBudgets.length,
                  itemBuilder: (context, index) {
                    int budget = rowBudgets[index];
                    return Obx(() => Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: controller.selectedBudget.value == budget,
                            label: Text(
                              '₦${_formatNumber(budget)}',
                              style: const TextStyle(color: Colors.black),
                            ),
                            onSelected: (selected) {
                              controller.selectedBudget.value =
                                  selected ? budget : null;
                            },
                            selectedColor: Colors.blue[100],
                            checkmarkColor: Colors.blue,
                            backgroundColor:
                                isDark ? sheetBgColor : Colors.grey.shade300,
                          ),
                        ));
                  },
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCustomRangeInputs() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Min Price',
              prefixText: '₦',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => controller.customMinPrice.value = value,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Max Price',
              prefixText: '₦',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => controller.customMaxPrice.value = value,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection(BuildContext context) {
    final notifire = Provider.of<ColorNotifire>(context, listen: true);
    final isDark = notifire.isDark;
    final sheetBgColor =
        isDark ? const Color.fromARGB(255, 183, 183, 186) : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: notifire.getwhiteblackcolor),
        ),
        const SizedBox(
          height: 6,
        ),
        const Text(
          'select the amenities you want in your search property  ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.amenityOptions
              .map((amenity) => Obx(() => FilterChip(
                    selected:
                        controller.selectedAmenities.contains(amenity.name),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          amenity.icon,
                          size: 16,
                          color: controller.selectedAmenities
                                  .contains(amenity.name)
                              ? Colors.white
                              : amenity.color,
                        ),
                        const SizedBox(width: 6),
                        Text(amenity.name),
                      ],
                    ),
                    onSelected: (selected) =>
                        controller.toggleAmenity(amenity.name, amenity.id),
                    selectedColor: amenity.color,
                    checkmarkColor: Colors.white,
                    backgroundColor:
                        isDark ? const Color(0xFFeef4ff) : Colors.grey.shade300,
                  )))
              .toList(),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(number % 1000000 == 0 ? 0 : 1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}K';
    }
    return number.toString();
  }
}
