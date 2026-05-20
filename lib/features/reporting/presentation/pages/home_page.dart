import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_status_utils.dart';
import '../../../../shared/widgets/admin_stat_card.dart';
import '../../../../shared/widgets/notification_icon_button.dart';
import '../../../../shared/widgets/report_card.dart';
import '../../domain/report_model.dart';
import '../../data/report_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReportsAsync = ref.watch(myReportsProvider);
    final cityReportsAsync = ref.watch(cityReportsProvider);

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
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: const [NotificationIconButton()],
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'YOUR DASHBOARD',
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
                      myReportsAsync.when(
                        data: (reports) {
                          final resolvedCount = reports
                              .where(
                                (r) => r.status.toLowerCase() == 'resolved',
                              )
                              .length;
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
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
                        'Reports of your reports resolved.',
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

                // Your report stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: myReportsAsync.when(
                    data: (reports) {
                      final pending = reports
                          .where((r) => r.status.toLowerCase() == 'pending')
                          .length;
                      final inProgress = reports
                          .where((r) => r.status.toLowerCase() == 'in_progress')
                          .length;
                      final resolved = reports
                          .where((r) => r.status.toLowerCase() == 'resolved')
                          .length;
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.05,
                        children: [
                          AdminStatCard(
                            label: 'Total Reports',
                            value: '${reports.length}',
                            icon: Icons.fact_check_outlined,
                            accent: AppColors.primary,
                          ),
                          AdminStatCard(
                            label: 'Pending',
                            value: '$pending',
                            icon: Icons.pending_actions_outlined,
                            accent: AppColors.tertiaryContainer,
                            badge: pending > 0 ? 'Active' : null,
                          ),
                          AdminStatCard(
                            label: 'In Progress',
                            value: '$inProgress',
                            icon: Icons.moped_outlined,
                            accent: AppColors.secondary,
                          ),
                          AdminStatCard(
                            label: 'Resolved',
                            value: '$resolved',
                            icon: Icons.task_alt_outlined,
                            accent: AppColors.primaryContainer,
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Reports section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Recent Reports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/reports'),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Scrollable report cards
                SizedBox(
                  height: 228,
                  child: myReportsAsync.when(
                    data: (reports) {
                      final sorted = [...reports]
                        ..sort((a, b) => b.date.compareTo(a.date));
                      final recentReports = sorted.take(5).toList();
                      if (recentReports.isEmpty) {
                        return const Center(
                          child: Text(
                            'You haven\'t submitted any reports yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        );
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: recentReports.length,
                        itemBuilder: (context, index) {
                          final report = recentReports[index];
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 12),
                            child: ReportCard(
                              compact: true,
                              id: report.id,
                              category: report.category,
                              date: DateFormat('MMM dd').format(report.date),
                              status: report.status,
                              location: report.location,
                              images: report.images,
                              upvotes: report.upvotes,
                              onTap: () =>
                                  context.push('/report-detail/${report.id}'),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
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

                cityReportsAsync.when(
                  data: (reports) {
                    final highPriorityReports =
                        reports
                            .where((r) => r.status.toLowerCase() != 'resolved')
                            .toList()
                          ..sort(
                            (a, b) =>
                                b.priorityScore.compareTo(a.priorityScore),
                          );

                    if (highPriorityReports.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Text(
                          'No active priority issues in the city.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      );
                    }

                    final displayCount = highPriorityReports.length > 3
                        ? 3
                        : highPriorityReports.length;
                    return Column(
                      children: List.generate(displayCount, (index) {
                        final report = highPriorityReports[index];

                        final badge = ReportStatusUtils.badgeLabel(
                          report.status,
                        );
                        final badgeColor = ReportStatusUtils.badgeBackground(
                          report.status,
                        );
                        final badgeTextColor = ReportStatusUtils.color(
                          report.status,
                        );

                        return GestureDetector(
                          onTap: () =>
                              context.push('/report-detail/${report.id}'),
                          child: _buildHotspot(
                            context,
                            icon: _getCategoryIcon(report.categoryIcon),
                            iconBg: badgeColor.withOpacity(0.12),
                            iconColor: badgeTextColor == Colors.white
                                ? badgeColor
                                : badgeTextColor,
                            title: report.location,
                            subtitle:
                                '${report.category} · Priority Score: ${report.priorityScore}',
                            badge: badge,
                            badgeColor: badgeColor,
                            badgeTextColor: badgeTextColor,
                          ),
                        );
                      }),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
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
        label: const Text(
          'Report Issue',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
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
    Color badgeTextColor = AppColors.onSurface,
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
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeTextColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    if (iconName != null) {
      switch (iconName) {
        case 'delete_outline':
          return Icons.delete_outline;
        case 'water_damage':
          return Icons.water_damage;
        case 'warning_amber':
          return Icons.warning_amber;
        case 'delete_sweep':
          return Icons.delete_sweep;
        case 'more_horiz':
          return Icons.more_horiz;
      }
    }
    return Icons.eco_outlined;
  }
}
