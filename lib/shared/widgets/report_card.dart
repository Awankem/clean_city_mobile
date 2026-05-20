import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'status_badge.dart';
import '../../core/utils/report_format_utils.dart';

class ReportCard extends StatelessWidget {
  final String id;
  final String category;
  final String date;
  final String status;
  final String location;
  final List<String>? images;
  final int upvotes;
  final VoidCallback onTap;
  /// Tighter layout for horizontal carousels (avoids vertical overflow).
  final bool compact;

  const ReportCard({
    super.key,
    required this.id,
    required this.category,
    required this.date,
    required this.status,
    required this.location,
    this.images,
    this.upvotes = 0,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Get the first image as the thumbnail
    final String? thumbnail = images != null && images!.isNotEmpty ? images!.first : null;

    final imageHeight = compact ? 88.0 : 140.0;
    final contentPadding = compact ? 12.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: compact ? 0 : 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnail != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  thumbnail,
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: imageHeight,
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(Icons.broken_image_outlined, color: AppColors.outline),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ReportFormatUtils.reportId(id),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              category,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge(status: status, compact: compact),
                    ],
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location, 
                          style: const TextStyle(fontSize: 12, color: AppColors.outline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.outline),
                      const SizedBox(width: 4),
                      Text(date, style: const TextStyle(fontSize: 12, color: AppColors.outline)),
                      const Spacer(),
                      // Community feedback indicator for multiple photos
                      if (images != null && images!.length > 1)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.photo_library_outlined, size: 10, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${images!.length}',
                                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      // Upvotes
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.thumb_up_alt_outlined, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              upvotes.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
