import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/report_card.dart';
import '../../domain/report_model.dart';
import '../../data/report_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(cityReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          // Glassmorphism SliverAppBar - dark green, blurs over content
          SliverAppBar(
            expandedHeight: 60,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.primary.withOpacity(0.92),
            elevation: 0,
            title: const Text(
              'CleanCity',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero stats banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'CITY OVERVIEW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      reportsAsync.when(
                        data: (reports) {
                          final resolvedCount = reports.where((r) => r.status.toLowerCase() == 'resolved').length;
                          return Text(
                            '$resolvedCount',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: -2,
                              height: 1,
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          height: 56,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          ),
                        ),
                        error: (_, __) => const Text(
                          '0',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                      ),
                      Text(
                        'Reports Resolved across the city.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.onSurface.withOpacity(0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Recent Reports section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Reports',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => context.go('/reports?feed=true'),
                        child: const Text('View All',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Scrollable report cards
                SizedBox(
                  height: 200,
                  child: reportsAsync.when(
                    data: (reports) {
                      final activeReports = reports.where((r) => r.status.toLowerCase() != 'resolved').toList();
                      if (activeReports.isEmpty) {
                        return const Center(
                          child: Text(
                            'No active reports currently.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        );
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: activeReports.length > 5 ? 5 : activeReports.length,
                        itemBuilder: (context, index) {
                          final report = activeReports[index];
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 12),
                            child: ReportCard(
                              id: report.id,
                              category: report.category,
                              date: DateFormat('MMM dd').format(report.date),
                              status: report.status,
                              location: report.location,
                              upvotes: report.upvotes,
                              onTap: () => context.push('/report-detail/${report.id}'),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // High Priority Issues
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'High Priority Issues',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),

                reportsAsync.when(
                  data: (reports) {
                    final highPriorityReports = reports
                        .where((r) => r.status.toLowerCase() != 'resolved')
                        .toList()
                      ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

                    if (highPriorityReports.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          'No active priority issues reported.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      );
                    }

                    final displayCount = highPriorityReports.length > 3 ? 3 : highPriorityReports.length;
                    return Column(
                      children: List.generate(displayCount, (index) {
                        final report = highPriorityReports[index];
                        
                        // Map status to badge
                        String badge = 'REPORTED';
                        Color badgeColor = AppColors.statusPending;
                        if (report.status.toLowerCase() == 'in_progress') {
                          badge = 'IN PROGRESS';
                          badgeColor = AppColors.statusInProgress;
                        }

                        return GestureDetector(
                          onTap: () => context.push('/report-detail/${report.id}'),
                          child: _buildHotspot(
                            context,
                            icon: _getCategoryIcon(report.categoryIcon),
                            iconBg: badgeColor.withOpacity(0.12),
                            iconColor: badgeColor,
                            title: report.location,
                            subtitle: '${report.category} · Priority Score: ${report.priorityScore}',
                            badge: badge,
                            badgeColor: badgeColor,
                          ),
                        );
                      }),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/submit-report'),
        backgroundColor: AppColors.primary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
        label: const Text('Report Issue',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _buildHotspot(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.onSurface.withOpacity(0.55))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(badge,
                style: TextStyle(
                    color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    if (iconName != null) {
      switch (iconName) {
        case 'delete_outline': return Icons.delete_outline;
        case 'water_damage': return Icons.water_damage;
        case 'warning_amber': return Icons.warning_amber;
        case 'delete_sweep': return Icons.delete_sweep;
        case 'more_horiz': return Icons.more_horiz;
      }
    }
    return Icons.eco_outlined;
  }
}
