import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanitation Map'),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Placeholder for the Mapbox Map
          Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.surfaceContainerLow,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 80, color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Mapbox Visualisation Coming Soon',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Implementing Silver/Eco Custom Style...',
                    style: TextStyle(color: AppColors.outline),
                  ),
                ],
              ),
            ),
          ),
          
          // Floating overlay controls as per Stitch design
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.outline),
                  SizedBox(width: 12),
                  Text('Search for a neighborhood...', style: TextStyle(color: AppColors.outline)),
                ],
              ),
            ),
          ),
          
          // Hotspot Legend
          Positioned(
            bottom: 32,
            right: 16,
            child: Column(
              children: [
                _buildLegendItem(AppColors.tertiary, 'Urgent'),
                const SizedBox(height: 8),
                _buildLegendItem(AppColors.secondary, 'Normal'),
                const SizedBox(height: 8),
                _buildLegendItem(AppColors.primary, 'Clean'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
