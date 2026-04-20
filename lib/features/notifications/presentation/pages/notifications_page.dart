import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('CleanCity',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Civic Clarity',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Notification Center',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time status updates on your environmental and infrastructure reports in the Bamenda District.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurface.withOpacity(0.6),
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Resolution Progress banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resolution Progress',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('You have 3 active reports being addressed today.',
                            style: TextStyle(fontSize: 12, color: AppColors.outline)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notifications list
            _buildNotification(
              context,
              icon: Icons.check_circle_outline,
              iconColor: AppColors.primary,
              iconBg: AppColors.primary.withOpacity(0.1),
              title: 'Status Change: Resolved',
              badge: 'RESOLVED',
              badgeColor: AppColors.primary,
              body:
                  'The waste overflow reported at Commercial Avenue, Bamenda has been cleared. Sanitation Team A completed the cleanup at 14:30.',
              time: '14:35',
            ),
            _buildNotification(
              context,
              icon: Icons.engineering_outlined,
              iconColor: Colors.orange[700]!,
              iconBg: Colors.orange.withOpacity(0.1),
              title: 'Status Change: Assigned to Team',
              badge: 'ASSIGNED',
              badgeColor: Colors.orange[700]!,
              body:
                  'Your report regarding the blocked drainage in Food Market Road has been assigned to the Sanitation Unit. ETA for repair is 48 hours.',
              time: '11:15',
            ),
            _buildNotification(
              context,
              icon: Icons.priority_high_rounded,
              iconColor: AppColors.tertiary,
              iconBg: const Color(0xFFFFDAD7),
              title: 'Status Change: Urgent Action Required',
              badge: 'URGENT',
              badgeColor: AppColors.tertiary,
              body:
                  'Please provide a photo of the waste pile location. Our team is on-site but needs a specific landmark to identify the exact location.',
              time: '09:02',
            ),
            _buildNotification(
              context,
              icon: Icons.hourglass_top_outlined,
              iconColor: AppColors.outline,
              iconBg: AppColors.surfaceContainerHigh,
              title: 'Status Change: Under Review',
              badge: 'UNDER REVIEW',
              badgeColor: AppColors.outline,
              body:
                  'The municipal planning office has received your request regarding illegal dumping in Nkwen District. It is currently being assessed.',
              time: 'Yesterday',
            ),

            // Footer banner
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      color: AppColors.primary, size: 32),
                  const SizedBox(height: 12),
                  const Text('Your reports matter.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    "Since joining CleanCity, you have helped resolve 12 environmental issues in your neighborhood. You're in the top 5% of active civic contributors this month.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurface.withOpacity(0.6),
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNotification(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String badge,
    required Color badgeColor,
    required String body,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Text(time,
                  style: TextStyle(fontSize: 11, color: AppColors.onSurface.withOpacity(0.45))),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(badge,
                style: TextStyle(
                    color: badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurface.withOpacity(0.7),
                  height: 1.4)),
        ],
      ),
    );
  }
}
