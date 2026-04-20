import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/report_model.dart';
import '../../data/report_providers.dart';

class ReportDetailPage extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailPage({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  late ReportModel report;
  bool isUpvoted = false;
  late int localUpvotes;
  late int localPriority;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadReport();
      _initialized = true;
    }
  }

  void _loadReport() {
    // Try to find in cache first (city feed OR my reports)
    final cityReports = ref.read(cityReportsProvider).asData?.value ?? [];
    final myReports = ref.read(myReportsProvider).asData?.value ?? [];
    final allReports = [...cityReports, ...myReports];

    report = allReports.firstWhere(
      (r) => r.id == widget.reportId,
      orElse: () => mockReports.first,
    );
    localUpvotes = report.upvotes;
    localPriority = report.priorityScore;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleUpvote() {
    setState(() {
      if (isUpvoted) {
        localUpvotes--;
        localPriority -= 2;
      } else {
        localUpvotes++;
        localPriority += 2;
      }
      isUpvoted = !isUpvoted;
    });
    
    Feedback.forTap(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isUpvoted ? 'You supported this report!' : 'Support removed'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isUpvoted ? AppColors.statusResolved : AppColors.statusPending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportColor = _getCategoryColor();

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (report.images.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentImageIndex = index),
                      itemCount: report.images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          report.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: reportColor.withOpacity(0.2),
                            child: Icon(
                              _getCategoryIcon(),
                              size: 80,
                              color: reportColor.withOpacity(0.4),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: reportColor.withOpacity(0.2),
                      child: Icon(
                        _getCategoryIcon(),
                        size: 80,
                        color: reportColor.withOpacity(0.4),
                      ),
                    ),
                  
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black45, Colors.transparent, Colors.black54],
                        stops: [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),

                  if (report.images.length > 1)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 60,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${report.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  if (report.images.length > 1)
                    Positioned(
                      bottom: 60,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          report.images.length,
                          (index) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Report #${report.id.padLeft(4, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              report.category,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          _statusBadge(report.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.location,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: AppColors.outline),
                          const SizedBox(width: 4),
                          Text(
                            'Reported ${_timeAgo(report.date)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildMetric(
                            label: 'COMMUNITY SUPPORT',
                            value: '$localUpvotes Votes',
                            icon: isUpvoted ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                            color: isUpvoted ? AppColors.statusResolved : AppColors.primary,
                          ).animate(target: isUpvoted ? 1 : 0).shimmer(duration: 400.ms),
                          const SizedBox(width: 24),
                          _buildMetric(
                            label: 'PRIORITY LEVEL',
                            value: '$localPriority Score',
                            icon: Icons.analytics_outlined,
                            color: AppColors.statusInProgress,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _toggleUpvote,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isUpvoted ? AppColors.statusResolved : AppColors.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: isUpvoted 
                                ? AppColors.statusResolved.withOpacity(0.05) 
                                : Colors.transparent,
                          ),
                          icon: Icon(
                            isUpvoted ? Icons.check_circle : Icons.add_moderator_outlined,
                            color: isUpvoted ? AppColors.statusResolved : AppColors.primary,
                          ),
                          label: Text(
                            isUpvoted ? 'SUPPORTED BY YOU' : 'SUPPORT THIS REPORT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isUpvoted ? AppColors.statusResolved : AppColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ).animate(target: isUpvoted ? 1 : 0).scale(duration: 200.ms, begin: const Offset(1, 1), end: const Offset(1.02, 1.02)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        report.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Precise Location',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => context.go('/tracking'),
                            icon: const Icon(Icons.map_outlined,
                                color: AppColors.primary, size: 16),
                            label: const Text('View on Map',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 140,
                          color: const Color(0xFFD8E8D4),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                  size: Size.infinite, painter: _MapGridPainter()),
                              const Icon(Icons.location_on,
                                  color: AppColors.primary, size: 36),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.my_location_rounded,
                              size: 14, color: AppColors.outline),
                          const SizedBox(width: 6),
                          Text(
                            report.location,
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status Timeline',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (report.statusHistory.isEmpty)
                         _buildTimelineStep(
                           title: 'Reported',
                           body: 'Your report has been successfully registered.',
                           time: DateFormat('MMM dd, HH:mm').format(report.date),
                           icon: Icons.upload_file_outlined,
                           iconColor: AppColors.statusPending,
                           isLast: true,
                         )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: report.statusHistory.length,
                          itemBuilder: (context, index) {
                            final history = report.statusHistory[index];
                            final isLast = index == report.statusHistory.length - 1;
                            
                            return _buildTimelineStep(
                              title: history.status.toUpperCase(),
                              body: history.note ?? 'No details provided.',
                              time: DateFormat('MMM dd, HH:mm').format(history.createdAt),
                              icon: _getStatusIcon(history.status),
                              iconColor: _getStatusColor(history.status),
                              isLast: isLast,
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (report.status.toLowerCase() != 'resolved')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => context.pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Add More Evidence',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.outline,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String body,
    required String time,
    required IconData icon,
    required Color iconColor,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            if (!isLast)
              Container(width: 2, height: 48, color: AppColors.outlineVariantSolid),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0x80000000))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurface.withOpacity(0.6),
                        height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return AppColors.statusPending;
      case 'in_progress': return AppColors.statusInProgress;
      case 'resolved': return AppColors.statusResolved;
      default: return AppColors.outline;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.upload_file_outlined;
      case 'in_progress': return Icons.verified_outlined;
      case 'resolved': return Icons.check_circle_outline;
      default: return Icons.info_outline;
    }
  }

  Color _getCategoryColor() {
    if (report.categoryColor != null) {
      try {
        return Color(int.parse(report.categoryColor!.replaceAll('#', '0xFF')));
      } catch (e) {
        return AppColors.primary;
      }
    }
    return AppColors.primary;
  }

  IconData _getCategoryIcon() {
    if (report.categoryIcon != null) {
      // Map basic icon names to Material Icons (add more as needed)
      switch (report.categoryIcon) {
        case 'delete_outline': return Icons.delete_outline;
        case 'water_damage': return Icons.water_damage;
        case 'warning_amber': return Icons.warning_amber;
        case 'delete_sweep': return Icons.delete_sweep;
        case 'more_horiz': return Icons.more_horiz;
      }
    }
    return Icons.eco_outlined;
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 1) return '${diff.inDays} days ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBDD4B8)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    final road = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(0, size.height * 0.65), Offset(size.width, size.height * 0.35), road);
    canvas.drawLine(
        Offset(size.width * 0.35, 0), Offset(size.width * 0.65, size.height), road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

