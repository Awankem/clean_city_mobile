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
  MapStyle _currentMapStyle = MapStyle.dark;

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
          // Map background
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
                  urlTemplate: MapboxService.getTileLayerUrl(style: _currentMapStyle),
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

          // Search bar overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search neighbourhood...',
                    hintStyle: const TextStyle(color: AppColors.outline, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.outline, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                      onPressed: () {},
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  ),
                ),
              ),
            ),
          ),

          // Map action controls (right side)
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
                _buildMapActionButton(
                  icon: Icons.add_rounded,
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMapActionButton(
                  icon: Icons.remove_rounded,
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMapActionButton(
                  icon: _isLocating ? Icons.hourglass_empty_rounded : Icons.my_location_rounded,
                  onPressed: _determinePosition,
                  isPrimary: true,
                ),
                const SizedBox(height: 8),
                _buildMapActionButton(
                  icon: Icons.layers_rounded,
                  onPressed: () => setState(() => _currentMapStyle =
                      _currentMapStyle == MapStyle.dark ? MapStyle.streets : MapStyle.dark),
                ),
              ],
            ),
          ),

          // Legend (bottom left)
          Positioned(
            left: 16,
            bottom: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendRow(AppColors.tertiary, 'Urgent'),
                  const SizedBox(height: 5),
                  _buildLegendRow(AppColors.secondary, 'Progress'),
                  const SizedBox(height: 5),
                  _buildLegendRow(AppColors.primary, 'Resolved'),
                ],
              ),
            ),
          ),

          // Draggable reports bottom sheet
          reportsAsync.when(
            data: (reports) => DraggableScrollableSheet(
              initialChildSize: 0.14,
              minChildSize: 0.14,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            // Drag handle
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'City Reports',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${reports.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
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
                              child: Text(
                                'No reports in the city feed yet.',
                                style: TextStyle(color: AppColors.outline),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          sliver: SliverList.separated(
                            itemCount: reports.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
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
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
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

  Widget _buildMapActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.primary,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Map Marker Widgets ────────────────────────────────────────────────────────

class _ReportMarker extends StatelessWidget {
  final Color color;
  final int priority;

  const _ReportMarker({required this.color, this.priority = 0});

  @override
  Widget build(BuildContext context) {
    final bool isHotspot = priority > 7;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isHotspot) _HotspotPulse(color: color),
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
          color: widget.color.withValues(alpha: 1 - _controller.value),
        ),
      ),
    );
  }
}

class _PulsingLocationMarker extends StatefulWidget {
  @override
  State<_PulsingLocationMarker> createState() => _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<_PulsingLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
                color: Colors.blue.withValues(alpha: 1 - _controller.value),
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

// ─── Report List Item ──────────────────────────────────────────────────────────

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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.report_gmailerrorred_outlined, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ReportFormatUtils.reportId(report.id),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'YOURS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.outline, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ReportStatusUtils.badgeBackground(report.status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ReportStatusUtils.compactBadgeLabel(report.status),
                style: TextStyle(
                  color: ReportStatusUtils.color(report.status),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Report Details Sheet ──────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header row
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
                      const SizedBox(height: 4),
                      Text(
                        report.category,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: AppColors.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.outline),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.outline, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _PriorityBadge(score: _priority),
              ],
            ),

            const SizedBox(height: 20),

            // Image gallery
            if (report.images.isNotEmpty) ...[
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: report.images[index],
                      width: 240,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 240,
                        color: AppColors.surfaceContainerLow,
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 240,
                        color: AppColors.surfaceContainerLow,
                        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.outline),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              report.description.isNotEmpty
                  ? report.description
                  : 'No description provided.',
              style: const TextStyle(
                height: 1.6,
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Action: own report notice or upvote button
            if (isOwn)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'This is your report — community members can upvote it to increase priority.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.outline,
                    height: 1.5,
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: canUpvote ? _upvote : null,
                  icon: Icon(
                    _hasVoted ? Icons.check_circle_outline_rounded : Icons.thumb_up_alt_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _hasVoted
                        ? 'Supported  ·  $_upvotes'
                        : 'Support this report  ·  $_upvotes',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.6), width: 1.5),
                    disabledForegroundColor: AppColors.outline,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            const SizedBox(height: 10),

            // View full details button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/report-detail/${report.id}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'View Full Details',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Priority Badge ────────────────────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  final int score;
  const _PriorityBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final Color color = score > 7
        ? AppColors.tertiary
        : (score > 4 ? AppColors.secondary : AppColors.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PRIORITY',
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
