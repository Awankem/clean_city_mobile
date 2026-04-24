import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/report_card.dart';
import '../../domain/report_model.dart';
import '../../data/mock_reporting_data.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                              'BAMENDA DISTRICT',
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
                      const Text(
                        '124',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: -2,
                          height: 1,
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
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: MockReportingData.mockCityFeed.length,
                    itemBuilder: (context, index) {
                      final report = MockReportingData.mockCityFeed[index];
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 12),
                        child: ReportCard(
                          category: report.category,
                          date: DateFormat('MMM dd').format(report.date),
                          status: report.status,
                          location: report.location,
                          upvotes: report.upvotes,
                          onTap: () => context.push('/report-detail/${report.id}'),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28),

                // Live Hotspots
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'Live Hotspots',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),

                _buildHotspot(
                  context,
                  icon: Icons.warning_amber_rounded,
                  iconBg: const Color(0xFFFFDAD7),
                  iconColor: AppColors.tertiary,
                  title: 'Commercial Avenue, Bamenda',
                  subtitle: '3 active reports · High Priority',
                  badge: 'URGENT',
                  badgeColor: AppColors.tertiary,
                ),
                _buildHotspot(
                  context,
                  icon: Icons.recycling_rounded,
                  iconBg: AppColors.statusInProgress.withOpacity(0.12),
                  iconColor: AppColors.statusInProgress,
                  title: 'Food Market Road, Bamenda',
                  subtitle: '2 active reports · Medium Priority',
                  badge: 'IN PROGRESS',
                  badgeColor: AppColors.statusInProgress,
                ),
                _buildHotspot(
                  context,
                  icon: Icons.water_damage_outlined,
                  iconBg: AppColors.statusPending.withOpacity(0.1),
                  iconColor: AppColors.statusPending,
                  title: 'Nkwen District',
                  subtitle: '1 report · Under review',
                  badge: 'REPORTED',
                  badgeColor: AppColors.statusPending,
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
}
