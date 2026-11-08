import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:opendoors/Api/config.dart';
import 'package:opendoors/Api/data_store.dart';
import 'package:opendoors/Api/nearby_properties_api.dart';
import 'package:opendoors/controller/homepage_controller.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/model/homedata_info.dart';
import 'package:opendoors/model/routes_helper.dart';
import 'package:opendoors/screen/home_screen.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:opendoors/utils/formaters.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.active = true});

  final bool active;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double _radiusMetres = 1500;
  int _nearbyRequestVersion = 0;
  final HomePageController _homeController = Get.find();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  GoogleMapController? _mapController;
  ScrollController? _listController;
  Position? _userPosition;
  List<Property> _properties = [];
  String? _locationError;
  String? _propertiesError;
  String? _selectedPropertyId;
  bool _loadingProperties = false;

  String get _radiusLabel =>
      '${(_radiusMetres / 1000).toStringAsFixed(_radiusMetres % 1000 == 0 ? 0 : 1)} km';

  double get _mapZoom =>
      (12 - math.log(_radiusMetres / 1500) / math.ln2).clamp(8, 16).toDouble();

  void _showRadiusPicker(ColorNotifire notifire) {
    var selectedKm = _radiusMetres / 1000;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: notifire.getblackwhitecolor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search distance',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: FontFamily.gilroyBold,
                    color: notifire.getwhiteblackcolor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Show properties within ${selectedKm.toStringAsFixed(selectedKm % 1 == 0 ? 0 : 1)} km of your location',
                  style: TextStyle(color: notifire.getgreycolor),
                ),
                Slider(
                  min: 0.5,
                  max: 20,
                  divisions: 39,
                  value: selectedKm,
                  activeColor: Darkblue,
                  label:
                      '${selectedKm.toStringAsFixed(selectedKm % 1 == 0 ? 0 : 1)} km',
                  onChanged: (value) => updateSheet(() => selectedKm = value),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0.5 km',
                          style: TextStyle(color: notifire.getgreycolor)),
                      Text('20 km',
                          style: TextStyle(color: notifire.getgreycolor)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      if (!mounted || selectedKm * 1000 == _radiusMetres) {
                        return;
                      }
                      setState(() {
                        _radiusMetres = selectedKm * 1000;
                        _selectedPropertyId = null;
                      });
                      final position = _userPosition;
                      if (position != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(position.latitude, position.longitude),
                            _mapZoom,
                          ),
                        );
                        _fetchNearbyProperties(position);
                      }
                    },
                    child: const Text('Show properties'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Property> get _nearbyProperties {
    final position = _userPosition;
    if (position == null) return [];
    final byId = <String, Property>{};
    for (final property in _properties) {
      final id = property.id;
      final latitude = double.tryParse(property.latitude ?? '');
      final longitude = double.tryParse(property.longtitude ?? '');
      if (id == null ||
          id.isEmpty ||
          latitude == null ||
          longitude == null ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180 ||
          (latitude == 0 && longitude == 0)) {
        continue;
      }
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        latitude,
        longitude,
      );
      if (distance <= _radiusMetres) byId.putIfAbsent(id, () => property);
    }
    final nearby = byId.values.toList();
    nearby.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    if (_selectedPropertyId == null) return nearby;
    final selected = nearby.where((p) => p.id == _selectedPropertyId).toList();
    return [
      ...selected,
      ...nearby.where((p) => p.id != _selectedPropertyId),
    ];
  }

  double _distanceTo(Property property) {
    final position = _userPosition!;
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      double.parse(property.latitude!),
      double.parse(property.longtitude!),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.active) _centerOnUser();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _centerOnUser();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _centerOnUser() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        setState(() => _locationError =
            'Turn on location services to see nearby properties.');
      }
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      if (mounted) {
        setState(() =>
            _locationError = 'Allow location access to see nearby properties.');
      }
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _userPosition = position;
        _locationError = null;
        _selectedPropertyId = null;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        _mapZoom,
      ));
      await _fetchNearbyProperties(position);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _locationError = 'Could not get your location. Please try again.');
      }
    }
  }

  Future<void> _fetchNearbyProperties(Position position) async {
    final requestVersion = ++_nearbyRequestVersion;
    setState(() {
      _loadingProperties = true;
      _propertiesError = null;
      _properties = [];
    });
    try {
      final properties = await NearbyPropertiesApi().fetch(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: _radiusMetres / 1000,
        countryId: getData.read('countryId')?.toString(),
      );
      if (mounted && requestVersion == _nearbyRequestVersion) {
        setState(() => _properties = properties);
      }
    } catch (error) {
      debugPrint('Nearby properties failed: $error');
      if (mounted && requestVersion == _nearbyRequestVersion) {
        setState(() => _propertiesError =
            'Could not load nearby properties. Please try again.');
      }
    } finally {
      if (mounted && requestVersion == _nearbyRequestVersion) {
        setState(() => _loadingProperties = false);
      }
    }
  }

  void _selectMarker(Property property) {
    setState(() => _selectedPropertyId = property.id);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(
          double.parse(property.latitude!), double.parse(property.longtitude!)),
      15,
    ));
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        .55,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
    if (_listController?.hasClients == true) {
      _listController!.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _openProperty(Property property, int index) {
    _homeController.rate = property.rate ?? '';
    _homeController.chnageObjectIndex(index);
    Get.toNamed(Routes.viewDataScreen, arguments: {'id': property.id});
  }

  String _imageUrl(String? image) {
    final path = image?.trim() ?? '';
    if (path.isEmpty || path == 'null') return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return Uri.parse(Config.imageUrl).resolve(path).toString();
  }

  Widget _propertyCard(Property property, int index, ColorNotifire notifire) {
    final distanceKm = (_distanceTo(property) / 1000).toStringAsFixed(1);
    final imageUrl = _imageUrl(property.image);
    final selected = property.id == _selectedPropertyId;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: notifire.getblackwhitecolor,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openProperty(property, index),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? Darkblue : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 136,
                    width: double.infinity,
                    child: imageUrl.isEmpty
                        ? const Center(
                            child: Icon(Icons.home_work_outlined, size: 42),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.home_work_outlined, size: 42),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property.title ?? 'Property',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: FontFamily.gilroyBold,
                          color: notifire.getwhiteblackcolor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$distanceKm km away',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: FontFamily.gilroyMedium,
                        color: Darkblue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  property.city ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: FontFamily.gilroyMedium,
                    color: notifire.getgreycolor,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (property.beds?.isNotEmpty == true)
                      _detail(Icons.bed_outlined, '${property.beds} beds',
                          notifire),
                    if (property.bathroom?.isNotEmpty == true)
                      _detail(Icons.bathtub_outlined,
                          '${property.bathroom} baths', notifire),
                    if (property.sqrft?.isNotEmpty == true)
                      _detail(Icons.square_foot_rounded,
                          '${property.sqrft} sqm', notifire),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  '${currency?.toString() ?? 'NGN'} ${AppFormater.formatAmount(double.tryParse(property.price ?? '0') ?? 0)}${property.buyorrent == '1' ? '/night' : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: FontFamily.gilroyBold,
                    color: Darkblue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String text, ColorNotifire notifire) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: notifire.getgreycolor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontFamily: FontFamily.gilroyMedium,
              color: notifire.getgreycolor,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final notifire = Provider.of<ColorNotifire>(context);
    final position = _userPosition;
    if (position == null) {
      return Scaffold(
        backgroundColor: notifire.getblackwhitecolor,
        body: Center(
          child: _locationError == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _locationError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: notifire.getwhiteblackcolor),
                    ),
                    TextButton(
                      onPressed: _centerOnUser,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
        ),
      );
    }

    final nearby = _nearbyProperties;
    final markers = <Marker>{
      for (final property in nearby)
        Marker(
          markerId: MarkerId(property.id!),
          position: LatLng(
            double.parse(property.latitude!),
            double.parse(property.longtitude!),
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: property.title,
            snippet: property.city,
          ),
          onTap: () => _selectMarker(property),
        ),
    };

    return Scaffold(
      backgroundColor: notifire.getblackwhitecolor,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: _mapZoom,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: markers,
              circles: {
                Circle(
                  circleId: const CircleId('nearby_radius'),
                  center: LatLng(position.latitude, position.longitude),
                  radius: _radiusMetres,
                  strokeColor: Darkblue.withValues(alpha: .55),
                  strokeWidth: 2,
                  fillColor: Darkblue.withValues(alpha: .06),
                ),
              },
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              compassEnabled: true,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 16,
            right: 16,
            child: Material(
              color: notifire.getblackwhitecolor,
              borderRadius: BorderRadius.circular(28),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => Get.toNamed(Routes.homeSearchScreen),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: notifire.getwhiteblackcolor),
                      const SizedBox(width: 10),
                      Text(
                        'Search properties',
                        style: TextStyle(color: notifire.getgreycolor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 70,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: notifire.getblackwhitecolor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 17, color: Color(0xffFF4D00)),
                  const SizedBox(width: 3),
                  Text('Properties',
                      style: TextStyle(color: notifire.getwhiteblackcolor)),
                  const SizedBox(width: 12),
                  const Icon(Icons.circle, size: 11, color: Colors.blue),
                  const SizedBox(width: 5),
                  Text('You',
                      style: TextStyle(color: notifire.getwhiteblackcolor)),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 70,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'nearby_recenter',
              backgroundColor: notifire.getblackwhitecolor,
              onPressed: _centerOnUser,
              child: Icon(Icons.my_location_rounded, color: Darkblue),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 122,
            left: 16,
            child: Material(
              color: notifire.getblackwhitecolor,
              borderRadius: BorderRadius.circular(22),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _showRadiusPicker(notifire),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.radar_rounded, size: 18, color: Darkblue),
                      const SizedBox(width: 6),
                      Text(
                        'Within $_radiusLabel',
                        style: TextStyle(color: notifire.getwhiteblackcolor),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: notifire.getgreycolor),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: MediaQuery.paddingOf(context).top,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: .50,
                minChildSize: .18,
                maxChildSize: 1,
                snap: true,
                snapSizes: const [.50],
                expand: false,
                builder: (context, scrollController) {
                  _listController = scrollController;
                  return Container(
                    decoration: BoxDecoration(
                      color: notifire.getblackwhitecolor,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 16),
                      ],
                    ),
                    child: ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom + 105,
                      ),
                      itemCount: nearby.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            children: [
                              const SizedBox(height: 10),
                              Container(
                                height: 5,
                                width: 42,
                                decoration: BoxDecoration(
                                  color: notifire.getgreycolor
                                      .withValues(alpha: .45),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 16, 18, 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nearby properties',
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontFamily: FontFamily.gilroyBold,
                                              color:
                                                  notifire.getwhiteblackcolor,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Within $_radiusLabel of your location',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: notifire.getgreycolor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${nearby.length} found',
                                      style: TextStyle(
                                        fontFamily: FontFamily.gilroyMedium,
                                        color: Darkblue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_loadingProperties ||
                                  _propertiesError != null ||
                                  nearby.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      if (_loadingProperties)
                                        const CircularProgressIndicator(),
                                      const SizedBox(height: 12),
                                      Text(
                                        _loadingProperties
                                            ? 'Loading properties...'
                                            : _propertiesError ??
                                                'No properties found within $_radiusLabel.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: notifire.getgreycolor,
                                        ),
                                      ),
                                      if (_propertiesError != null)
                                        TextButton(
                                          onPressed: () =>
                                              _fetchNearbyProperties(position),
                                          child: const Text('Retry'),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        }
                        return _propertyCard(
                            nearby[index - 1], index - 1, notifire);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
