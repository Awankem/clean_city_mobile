import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 52),

                  // Brand mark
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CleanCity',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Bamenda, Cameroon',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),

                  const Spacer(),

                  // Hero text
                  Text(
                    'Report.\nTrack.\nKeep it clean.',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                      height: 1.2,
                      letterSpacing: -1.2,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.08),

                  const SizedBox(height: 16),

                  Text(
                    'Help keep Bamenda clean by reporting waste issues, tracking resolutions, and connecting with your community.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.outline,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                  const SizedBox(height: 32),

                  // Feature pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(Icons.report_problem_outlined, 'Report Issues'),
                      _pill(Icons.track_changes_outlined, 'Track Progress'),
                      _pill(Icons.people_outline_rounded, 'Join Community'),
                    ],
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                  const Spacer(),

                  // CTA buttons
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => context.push('/signup'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.surfaceContainerHigh, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.15),

                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/'),
                      child: Text(
                        'Continue without signing in',
                        style: TextStyle(
                          color: AppColors.outline,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'Privacy Policy  ·  Terms of Service',
                      style: TextStyle(
                        color: AppColors.outline.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
