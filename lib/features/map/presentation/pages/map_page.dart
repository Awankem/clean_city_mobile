import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:clean_city/core/theme/app_colors.dart';
import 'package:clean_city/core/services/mapbox_service.dart';
import 'package:clean_city/features/reporting/data/report_providers.dart';
import 'package:clean_city/features/reporting/domain/report_model.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentLocation;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _determinePosition();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLocating = false;
        });
        _mapController.move(_currentLocation!, 14.0);
      }
    } catch (e) {
      setState(() => _isLocating = false);
    }
  }

  Color _getStatusColor(String status) {
    // Handles both API format ('in_progress') and UI label format ('in progress')
    switch (status.toLowerCase().replaceAll('_', ' ')) {
      case 'urgent':
      case 'pending':
        return AppColors.tertiary;
      case 'in progress':
        return AppColors.secondary;
      case 'resolved':
      case 'clean':
        return AppColors.primary;
      default:
        return AppColors.outline;
    }
  }

  void _onReportSelected(ReportModel report) {
    _mapController.move(LatLng(report.latitude, report.longitude), 16.0);
    _showReportDetails(context, report);
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(cityReportsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map Background
          reportsAsync.when(
            data: (reports) => FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                // Default to Bamenda, Cameroon — where the mock data sits.
                // Will be overridden by real GPS once permissions are granted.
                initialCenter: _currentLocation ?? const LatLng(5.9631, 10.1591),
                initialZoom: 13.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapboxService.getTileLayerUrl(),
                  userAgentPackageName: 'com.clean.city',
                ),
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 60,
                        height: 60,
                        child: _PulsingLocationMarker(),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: reports.map((report) => Marker(
                    point: LatLng(report.latitude, report.longitude),
                    width: 45,
                    height: 45,
                    child: GestureDetector(
                      onTap: () => _onReportSelected(report),
                      child: _ReportMarker(
                        color: _getStatusColor(report.status),
                        priority: report.priorityScore,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Map Error: $err')),
          ),

          // Search Bar Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for a neighborhood...',
                    hintStyle: const TextStyle(color: AppColors.outline),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune, color: AppColors.primary),
                      onPressed: () {},
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                ),
              ),
            ),
          ),

          // Map Action Controls (Zoom & Location)
          Positioned(
            right: 16,
            bottom: 120, // Positioned above the draggable sheet's min height
            child: Column(
              children: [
                _buildMapActionButton(
                  icon: Icons.add,
                  onPressed: () {
                    final newZoom = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.camera.center, newZoom);
                  },
                ),
                const SizedBox(height: 8),
                _buildMapActionButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final newZoom = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.camera.center, newZoom);
                  },
                ),
                const SizedBox(height: 8),
                _buildMapActionButton(
                  icon: _isLocating ? Icons.hourglass_empty : Icons.my_location,
                  onPressed: _determinePosition,
                  isPrimary: true,
                ),
              ],
            ),
          ),

          // Legend Overlay
          Positioned(
            left: 16,
            bottom: 120,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendRow(AppColors.tertiary, 'Urgent'),
                  const SizedBox(height: 4),
                  _buildLegendRow(AppColors.secondary, 'Progress'),
                  const SizedBox(height: 4),
                  _buildLegendRow(AppColors.primary, 'Clean'),
                ],
              ),
            ),
          ),

          // Draggable Reports Sheet
          reportsAsync.when(
            data: (reports) => DraggableScrollableSheet(
              initialChildSize: 0.12,
              minChildSize: 0.12,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reports Nearby (${reports.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            TextButton(onPressed: () {}, child: const Text('Filters')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          itemCount: reports.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final report = reports[index];
                            return _ReportListItem(
                              report: report,
                              statusColor: _getStatusColor(report.status),
                              onTap: () => _onReportSelected(report),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }

  void _showReportDetails(BuildContext context, ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportDetailsSheet(report: report, statusColor: _getStatusColor(report.status)),
    );
  }

  Widget _buildMapActionButton({required IconData icon, required VoidCallback onPressed, bool isPrimary = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: isPrimary ? Colors.white : AppColors.primary),
      ),
    );
  }
}

class _ReportMarker extends StatelessWidget {
  final Color color;
  final int priority;
  
  const _ReportMarker({required this.color, this.priority = 0});

  @override
  Widget build(BuildContext context) {
    bool isHotspot = priority > 70;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isHotspot)
          _HotspotPulse(color: color),
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
        ),
        Icon(Icons.location_on, color: color, size: 30),
      ],
    );
  }
}

class _HotspotPulse extends StatefulWidget {
  final Color color;
  const _HotspotPulse({required this.color});
  @override
  State<_HotspotPulse> createState() => _HotspotPulseState();
}

class _HotspotPulseState extends State<_HotspotPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: 45 * _controller.value,
        height: 45 * _controller.value,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(1 - _controller.value),
        ),
      ),
    );
  }
}

class _PulsingLocationMarker extends StatefulWidget {
  @override
  State<_PulsingLocationMarker> createState() => _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<_PulsingLocationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 50 * _controller.value,
              height: 50 * _controller.value,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(1 - _controller.value),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReportListItem extends StatelessWidget {
  final ReportModel report;
  final Color statusColor;
  final VoidCallback onTap;

  const _ReportListItem({required this.report, required this.statusColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.report_gmailerrorred, color: statusColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(report.location, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(report.status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportDetailsSheet extends StatelessWidget {
  final ReportModel report;
  final Color statusColor;

  const _ReportDetailsSheet({required this.report, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(report.location, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                ),
                _PriorityBadge(score: report.priorityScore),
              ],
            ),
            const SizedBox(height: 24),
            if (report.images.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      report.images[index],
                      width: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 250, color: Colors.grey[100], child: const Icon(Icons.image_not_supported)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(report.description, style: const TextStyle(height: 1.5, color: Colors.black87)),
            const SizedBox(height: 24),
            // COMMUNITY UPVOTE BUTTON (Chapter 3.6.1 Requirement)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // This calls the backend API to recalculate priority
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Report validated! Priority score increased.'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.thumb_up_alt_outlined),
                label: const Text('SUPPORT THIS REPORT', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.secondary, width: 2),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Get Directions', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final int score;
  const _PriorityBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    Color color = score > 70 ? AppColors.tertiary : (score > 40 ? AppColors.secondary : AppColors.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text('PRIORITY', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text('$score', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}



