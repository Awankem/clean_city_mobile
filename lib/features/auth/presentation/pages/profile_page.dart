import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../reporting/data/report_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReportsAsync = ref.watch(myReportsProvider);
    final reportsCount = myReportsAsync.asData?.value.length ?? 0;
    
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: const Text('CleanCity',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryContainer],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Text('JA',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Jean-Luc Ambassa',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('jl.ambassa@civic.cm',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.onSurface.withOpacity(0.55))),
                            const SizedBox(height: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'TOP 5% CONTRIBUTOR',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Impact stats row
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      _buildImpact('$reportsCount', 'Reports\nSubmitted'),
                      _verticalDivider(),
                      _buildImpact('${(reportsCount * 0.7).floor()}', 'Issues\nResolved'),
                      _verticalDivider(),
                      _buildImpact('Top 5%', 'This\nMonth'),
                    ],
                  ),
                ),


                // City contribution banner
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco_rounded, color: Colors.white, size: 32),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Direct improvement to city health',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text('Your reports have led to 8 verified cleanups',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Settings section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Notification Settings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),

                _buildSettingCard(
                  icon: Icons.notifications_active_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Real-time status updates on reports',
                  trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.primary),
                ),
                _buildSettingCard(
                  icon: Icons.sms_outlined,
                  title: 'SMS Alerts',
                  subtitle: 'Urgent civic announcements only',
                  trailing: Switch(value: false, onChanged: (_) {}, activeColor: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Account Settings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),

                _buildSettingCard(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  subtitle: 'English (Cameroon)',
                  trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
                ),
                _buildSettingCard(
                  icon: Icons.security_outlined,
                  title: 'Security',
                  subtitle: 'Two-factor authentication enabled',
                  trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/welcome'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.tertiary,
                        side: BorderSide(color: AppColors.tertiary.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign Out',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpact(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: value.length > 3 ? 16 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.onSurface.withOpacity(0.55))),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 40, color: AppColors.surfaceContainerHighest);
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: AppColors.onSurface.withOpacity(0.5))),
        trailing: trailing,
      ),
    );
  }
}
