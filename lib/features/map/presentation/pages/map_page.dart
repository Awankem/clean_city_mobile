import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:clean_city/core/theme/app_colors.dart';
import 'package:clean_city/core/services/mapbox_service.dart';
import 'package:clean_city/core/utils/report_format_utils.dart';
import 'package:clean_city/core/utils/report_ownership.dart';
import 'package:clean_city/core/utils/report_status_utils.dart';
import 'package:clean_city/features/auth/data/auth_providers.dart';
import 'package:clean_city/features/reporting/data/report_providers.dart';
import 'package:clean_city/features/reporting/domain/report_model.dart';
import 'package:go_router/go_router.dart';

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
                  tileProvider: NetworkTileProvider(),
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

          // Draggable Reports Sheet (CustomScrollView avoids min-height overflow)
          reportsAsync.when(
            data: (reports) => DraggableScrollableSheet(
              initialChildSize: 0.14,
              minChildSize: 0.14,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'City Reports (${reports.length})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      if (reports.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No reports in the city feed yet.'),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                          sliver: SliverList.separated(
                            itemCount: reports.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final report = reports[index];
                              final currentUserId = ref.read(currentUserIdProvider);
                              return _ReportListItem(
                                report: report,
                                statusColor: _getStatusColor(report.status),
                                isOwn: isOwnReport(report, currentUserId),
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
      builder: (context) => _ReportDetailsSheet(
        report: report,
        statusColor: _getStatusColor(report.status),
      ),
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
    bool isHotspot = priority > 7;
    
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
  final bool isOwn;
  final VoidCallback onTap;

  const _ReportListItem({
    required this.report,
    required this.statusColor,
    this.isOwn = false,
    required this.onTap,
  });

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
                  Text(
                    ReportFormatUtils.reportId(report.id),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    report.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (isOwn)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Your report',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary.withOpacity(0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ReportStatusUtils.badgeBackground(report.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ReportStatusUtils.compactBadgeLabel(report.status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ReportStatusUtils.color(report.status),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportDetailsSheet extends ConsumerStatefulWidget {
  final ReportModel report;
  final Color statusColor;

  const _ReportDetailsSheet({required this.report, required this.statusColor});

  @override
  ConsumerState<_ReportDetailsSheet> createState() => _ReportDetailsSheetState();
}

class _ReportDetailsSheetState extends ConsumerState<_ReportDetailsSheet> {
  late bool _hasVoted;
  late int _upvotes;
  late int _priority;

  @override
  void initState() {
    super.initState();
    _hasVoted = widget.report.hasVoted;
    _upvotes = widget.report.upvotes;
    _priority = widget.report.priorityScore;
  }

  Future<void> _upvote() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (isOwnReport(widget.report, currentUserId) || _hasVoted) return;

    try {
      await ref.read(reportRepositoryProvider).upvote(widget.report.id);
      setState(() {
        _hasVoted = true;
        _upvotes++;
        _priority += 2;
      });
      ref.invalidate(cityReportsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You supported this report!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('403') || e.toString().contains('own')
                ? 'You cannot upvote your own report'
                : 'Could not upvote. Try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwn = isOwnReport(report, currentUserId);
    final canUpvote = !isOwn && !_hasVoted;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ReportFormatUtils.reportId(report.id),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        report.category,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PriorityBadge(score: _priority),
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
                    child: CachedNetworkImage(
                      imageUrl: report.images[index],
                      width: 250,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 250,
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 250,
                        color: Colors.grey[100],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              report.description.isNotEmpty ? report.description : 'No description provided.',
              style: const TextStyle(height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            if (isOwn)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'This is your report — community members can upvote it to increase priority.',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurface.withOpacity(0.7)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canUpvote ? _upvote : null,
                  icon: Icon(_hasVoted ? Icons.check_circle : Icons.thumb_up_alt_outlined),
                  label: Text(
                    _hasVoted ? 'SUPPORTED BY YOU' : 'SUPPORT THIS REPORT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    foregroundColor: AppColors.secondary,
                    disabledBackgroundColor: AppColors.surfaceContainerHigh,
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
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/report-detail/${report.id}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('View Full Details', style: TextStyle(fontWeight: FontWeight.bold)),
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
    Color color = score > 7 ? AppColors.tertiary : (score > 4 ? AppColors.secondary : AppColors.primary);
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



