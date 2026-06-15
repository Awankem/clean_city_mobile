import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:clean_city/core/theme/app_colors.dart';
import 'package:clean_city/core/services/mapbox_service.dart';
import 'package:go_router/go_router.dart';

class LocationPickerResult {
  final LatLng coordinates;
  final String address;

  LocationPickerResult(this.coordinates, this.address);
}

class LocationPickerPage extends StatefulWidget {
  final LatLng initialLocation;

  const LocationPickerPage({super.key, required this.initialLocation});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late MapController _mapController;
  late LatLng _currentCenter;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _currentAddress = "Loading address...";

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = widget.initialLocation;
    _updateAddress(_currentCenter);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateAddress(LatLng position) async {
    try {
      final address = await MapboxService.reverseGeocode(
          position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentAddress = address.isNotEmpty ? address : 'Unknown Location';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = 'Unknown Location';
        });
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final result = await MapboxService.forwardGeocode(query);
      if (mounted) {
        _mapController.move(result.location, 16.0);
        setState(() {
          _currentCenter = result.location;
          _currentAddress = result.placeName;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find "$query"')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() {
                    _currentCenter = position.center!;
                    _currentAddress = "Loading address...";
                  });
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _updateAddress(_currentCenter);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapboxService.getTileLayerUrl(),
                tileProvider: NetworkTileProvider(),
                userAgentPackageName: 'com.clean.city',
              ),
            ],
          ),

          // Center pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child:
                  Icon(Icons.location_on, color: AppColors.primary, size: 40),
            ),
          ),

          // Floating back button + search bar row
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Back button
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 2,
                    shadowColor: Colors.black12,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Search bar
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: _searchLocation,
                        decoration: InputDecoration(
                          hintText: 'Search address or landmark...',
                          hintStyle: const TextStyle(
                              color: AppColors.outline, fontSize: 14),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.primary, size: 20),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)))
                              : IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: AppColors.outline, size: 18),
                                  onPressed: () => _searchController.clear(),
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom action card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELECTED LOCATION',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.outline,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentAddress,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentCenter.latitude.toStringAsFixed(4)}° N, ${_currentCenter.longitude.toStringAsFixed(4)}° E',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.outline),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.pop(LocationPickerResult(
                            _currentCenter, _currentAddress));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Confirm Location',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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
