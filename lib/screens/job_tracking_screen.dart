import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/theme/app_theme.dart';

class JobTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobTrackingScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final status = job['status'] ?? 'pending';
    final steps = ['pending', 'in_progress', 'completed'];
    final currentStep = steps.indexOf(status);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Live Tracking', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Map Placeholder (in a real app this would be Google Maps)
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                image: const DecorationImage(
                   image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=Brooklyn+Bridge,New+York,NY&zoom=13&size=600x300&maptype=roadmap&markers=color:blue%7Clabel:S%7C40.702147,-74.015794&markers=color:green%7Clabel:G%7C40.711614,-74.012318&key=YOUR_API_KEY'), 
                   fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       const Icon(Icons.local_shipping_outlined, size: 16, color: AppTheme.primary),
                       const SizedBox(width: 8),
                       Text('Contractor is on the way', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Contractor Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                   CircleAvatar(
                     radius: 28,
                     backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                     child: const Icon(Icons.person, color: AppTheme.primary, size: 28),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Contractor', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                         Text('John Doe', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                         Text('4.9 ★ (120 Jobs)', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.warning)),
                       ],
                     ),
                   ),
                   IconButton(
                     onPressed: () {
                        // In a real app, this would open the phone dialer
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling contractor...')));
                     },
                     icon: const Icon(Icons.phone_rounded, color: AppTheme.success),
                     style: IconButton.styleFrom(backgroundColor: AppTheme.success.withValues(alpha: 0.1)),
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Timeline
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _buildTimelineDot(active: currentStep >= 0, last: false),
                    _buildTimelineLine(active: currentStep > 0),
                    _buildTimelineDot(active: currentStep >= 1, last: false),
                    _buildTimelineLine(active: currentStep > 1),
                    _buildTimelineDot(active: currentStep >= 2, last: true),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimelineItem('Request Accepted', 'Your contractor has reviewed and accepted the job.', active: currentStep >= 0),
                      const SizedBox(height: 32),
                      _buildTimelineItem('Work In Progress', 'Contractor is currently working on your repair.', active: currentStep >= 1),
                      const SizedBox(height: 32),
                      _buildTimelineItem('Job Completed', 'The work is done. Please review and pay.', active: currentStep >= 2),
                    ],
                  ),
                ),
              ],
            ),
          ].animate().fadeIn().slideY(begin: 0.1, end: 0),
        ),
      ),
    );
  }

  Widget _buildTimelineDot({required bool active, required bool last}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: active ? AppTheme.primary : const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: active ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
      ),
    );
  }

  Widget _buildTimelineLine({required bool active}) {
    return Container(
      width: 2,
      height: 60,
      color: active ? AppTheme.primary : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildTimelineItem(String title, String desc, {required bool active}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: active ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: active ? const Color(0xFF1E293B) : const Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }
}
