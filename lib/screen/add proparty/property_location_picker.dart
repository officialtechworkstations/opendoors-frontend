import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:opendoors/utils/Colors.dart';

class PropertyLocationPicker extends StatefulWidget {
  const PropertyLocationPicker({
    super.key,
    required this.initialQuery,
    this.initialPosition,
  });

  final String initialQuery;
  final LatLng? initialPosition;

  @override
  State<PropertyLocationPicker> createState() => _PropertyLocationPickerState();
}

class _PropertyLocationPickerState extends State<PropertyLocationPicker> {
  static const _fallbackPosition = LatLng(6.5244, 3.3792);
  late final TextEditingController _searchController;
  GoogleMapController? _mapController;
  LatLng? _pin;
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _pin = widget.initialPosition;
    if (_pin == null && widget.initialQuery.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchAddress());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _searching) return;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final matches =
          await locationFromAddress(query).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (matches.isEmpty) {
        setState(() => _searchError =
            'Address not found. Move the map and tap the property instead.');
        return;
      }
      final match = matches.first;
      final position = LatLng(match.latitude, match.longitude);
      setState(() => _pin = position);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 17),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _searchError =
            'Could not search this address. You can still tap the map to place the pin.');
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _setPin(LatLng position) {
    setState(() {
      _pin = position;
      _searchError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pin property location')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchAddress(),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search street, estate or area',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _searching ? null : _searchAddress,
                  icon: _searching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  tooltip: 'Search address',
                ),
              ],
            ),
          ),
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _searchError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initialPosition ?? _fallbackPosition,
                zoom: widget.initialPosition == null ? 12 : 17,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: _setPin,
              markers: {
                if (_pin != null)
                  Marker(
                    markerId: const MarkerId('property'),
                    position: _pin!,
                    draggable: true,
                    onDragEnd: _setPin,
                  ),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tap the map or drag the pin to the exact property entrance.',
                    textAlign: TextAlign.center,
                  ),
                  if (_pin != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${_pin!.latitude.toStringAsFixed(6)}, ${_pin!.longitude.toStringAsFixed(6)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _pin == null
                        ? null
                        : () => Navigator.of(context).pop(_pin),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Confirm property pin'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Darkblue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
