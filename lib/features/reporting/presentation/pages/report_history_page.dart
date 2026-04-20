import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/report_card.dart';
import '../../domain/report_model.dart';
import '../../data/report_providers.dart';

class ReportHistoryPage extends ConsumerStatefulWidget {
  final bool showCityFeed;

  const ReportHistoryPage({super.key, this.showCityFeed = false});

  @override
  ConsumerState<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends ConsumerState<ReportHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.showCityFeed) {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            color: AppColors.primary,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'CleanCity Reports',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                        onPressed: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'MY ACTIVITY'),
                    Tab(text: 'CITY FEED'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyActivityView(),
                _buildCityFeedView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyActivityView() {
    final myReportsAsync = ref.watch(myReportsProvider);

    return myReportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (reports) {
        if (reports.isEmpty) {
          return _buildEmptyState('You haven\'t submitted any reports yet.');
        }

        final resolvedCount = reports.where((r) => r.status.toLowerCase() == 'resolved').length;
        final inProgressCount = reports.where((r) => r.status.toLowerCase() == 'in_progress').length;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Track Your Contribution',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(
                          '${reports.length * 5} Impact Points',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatPill('${reports.length}', 'Submitted', AppColors.primary),
                            const SizedBox(width: 8),
                            _buildStatPill('$inProgressCount', 'In Progress', AppColors.statusInProgress),
                            const SizedBox(width: 8),
                            _buildStatPill('$resolvedCount', 'Resolved', AppColors.statusResolved),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (reports.isNotEmpty) _buildLatestUpdateHighlight(reports.first),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Text('My Report History',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return ReportCard(
                        category: report.category,
                        date: DateFormat('MMM dd, yyyy').format(report.date),
                        status: report.status,
                        location: report.location,
                        images: report.images,
                        upvotes: report.upvotes,
                        onTap: () => context.push('/report-detail/${report.id}'),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCityFeedView() {
    final cityReportsAsync = ref.watch(cityReportsProvider);

    return cityReportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (reports) {
        final filteredReports = _activeFilter == 'All'
            ? reports
            : reports.where((r) {
                String statusLower = r.status.toLowerCase();
                if (_activeFilter == 'Pending') return statusLower == 'pending';
                if (_activeFilter == 'In Progress') return statusLower == 'in_progress';
                if (_activeFilter == 'Resolved') return statusLower == 'resolved';
                return false;
              }).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DISCOVER',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 1.5)),
                        SizedBox(height: 4),
                        Text('Community Reports',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Support nearby issues to increase their priority.',
                            style: TextStyle(fontSize: 13, color: AppColors.outline)),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _activeFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _activeFilter = filter),
                            backgroundColor: Colors.white,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            side: BorderSide(
                                color: isSelected ? AppColors.primary : const Color(0xFFBEC9C0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            showCheckmark: false,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (filteredReports.isEmpty)
                    _buildEmptyState('No reports found for this filter.'),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return ReportCard(
                        category: report.category,
                        date: DateFormat('MMM dd, yyyy').format(report.date),
                        status: report.status,
                        location: report.location,
                        images: report.images,
                        upvotes: report.upvotes,
                        onTap: () => context.push('/report-detail/${report.id}'),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.outline.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AppColors.outline.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildLatestUpdateHighlight(ReportModel report) {
    final latestUpdate = report.statusHistory.isNotEmpty ? report.statusHistory.first : null;
    
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LATEST TRACKING',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.outline,
                              letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(report.category,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      Text('Report #${report.id.padLeft(4, '0')} • ${report.location}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0x80000000))),
                    ],
                  ),
                ),
                _statusBadge(report.status),
              ],
            ),
          ),
          _buildTimelineEntry(
            icon: Icons.notifications_none_outlined,
            iconColor: AppColors.primary,
            title: latestUpdate?.status.toUpperCase() ?? 'REPORTED',
            time: latestUpdate != null ? _timeAgo(latestUpdate.createdAt) : 'Recently',
            body: latestUpdate?.note ?? 'Your report is currently pending review.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending': color = AppColors.statusPending; break;
      case 'in_progress': color = AppColors.statusInProgress; break;
      case 'resolved': color = AppColors.statusResolved; break;
      default: color = AppColors.outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildStatPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTimelineEntry({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String body,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
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
                Container(width: 2, height: 32, color: AppColors.outlineVariantSolid),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 16 : 0),
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
                  if (body.isNotEmpty)
                    Text(body,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0x99000000),
                            height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

