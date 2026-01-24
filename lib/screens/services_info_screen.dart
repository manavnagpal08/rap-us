import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/widgets/premium_background.dart';

class ServicesInfoScreen extends StatelessWidget {
  final String selectedService;

  const ServicesInfoScreen({super.key, this.selectedService = "Renovations"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Our Services', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const PremiumBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildServiceGrid(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Expert Craftsmanship", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text("From planning to execution, we provide end-to-end management for all your home improvement needs.", style: GoogleFonts.inter(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 16),
        Container(width: 60, height: 4, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildServiceGrid(BuildContext context) {
    final services = [
      {'title': 'Renovations', 'icon': Icons.home_work_rounded, 'desc': 'Complete home remodeling, kitchen upgrades, and basement finishing.'},
      {'title': 'HVAC Systems', 'icon': Icons.ac_unit_rounded, 'desc': 'Smart heating, ventilation, and air conditioning solutions for year-round comfort.'},
      {'title': 'Roofing', 'icon': Icons.roofing_rounded, 'desc': 'Durable roofing materials and expert installation to protect your home.'},
      {'title': 'Plumbing', 'icon': Icons.plumbing_rounded, 'desc': 'Professional plumbing services, from leak repairs to full system installs.'},
      {'title': 'Electrical', 'icon': Icons.electrical_services_rounded, 'desc': 'Safe and efficient electrical work, including smart home integration.'},
      {'title': 'Landscaping', 'icon': Icons.forest_rounded, 'desc': 'Beautiful outdoor living spaces, irrigation, and garden design.'},
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: services.map((s) => _buildServiceCard(context, s)).toList(),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> s) {
    final bool isSelected = s['title'] == selectedService;
    
    return Container(
      width: 400, // Fixed width for wrap
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? AppTheme.accent : Colors.white.withValues(alpha: 0.1), width: isSelected ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(s['icon'] as IconData, color: AppTheme.accent, size: 32),
          ),
          const SizedBox(height: 24),
          Text(s['title'] as String, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text(s['desc'] as String, style: GoogleFonts.inter(fontSize: 15, color: Colors.white60, height: 1.5)),
          const SizedBox(height: 24),
          InkWell(
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search for ${s['title']} pros in Marketplace')));
            },
            child: Row(
              children: [
                Text("Find Professionals", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: AppTheme.accent, size: 16),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}
