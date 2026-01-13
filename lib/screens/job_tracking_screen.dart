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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Live Tracking', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
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
                color: Theme.of(context).dividerColor.withOpacity(0.05),
                image: DecorationImage(
                   colorFilter: Theme.of(context).brightness == Brightness.dark 
                       ? ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken) 
                       : null,
                   image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=Brooklyn+Bridge,New+York,NY&zoom=13&size=600x300&maptype=roadmap&markers=color:blue%7Clabel:S%7C40.702147,-74.015794&markers=color:green%7Clabel:G%7C40.711614,-74.012318&key=YOUR_API_KEY'), 
                   fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Icon(Icons.local_shipping_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                       const SizedBox(width: 8),
                       Text('Contractor is on the way', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                   CircleAvatar(
                     radius: 28,
                     backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                     child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 28),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Contractor', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
                         Text(job['contractorName'] ?? 'Assigned Contractor', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                         Text('Verified Pro', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.success)),
                       ],
                     ),
                   ),
                   IconButton(
                     onPressed: () {
                        // In a real app, this would open the phone dialer
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling contractor...')));
                     },
                     icon: const Icon(Icons.phone_rounded, color: AppTheme.success),
                     style: IconButton.styleFrom(backgroundColor: AppTheme.success.withOpacity(0.1)),
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
                    _buildTimelineDot(context, active: currentStep >= 0, last: false),
                    _buildTimelineLine(context, active: currentStep > 0),
                    _buildTimelineDot(context, active: currentStep >= 1, last: false),
                    _buildTimelineLine(context, active: currentStep > 1),
                    _buildTimelineDot(context, active: currentStep >= 2, last: true),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimelineItem(context, 'Request Accepted', 'Your contractor has reviewed and accepted the job.', active: currentStep >= 0),
                      const SizedBox(height: 32),
                      _buildTimelineItem(context, 'Work In Progress', 'Contractor is currently working on your repair.', active: currentStep >= 1),
                      const SizedBox(height: 32),
                      _buildTimelineItem(context, 'Job Completed', 'The work is done. Please review and pay.', active: currentStep >= 2),
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

  Widget _buildTimelineDot(BuildContext context, {required bool active, required bool last}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).cardColor, width: 3),
        boxShadow: active ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
      ),
    );
  }

  Widget _buildTimelineLine(BuildContext context, {required bool active}) {
    return Container(
      width: 2,
      height: 60,
      color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.2),
    );
  }

  Widget _buildTimelineItem(BuildContext context, String title, String desc, {required bool active}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: active ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: active ? Theme.of(context).colorScheme.onSurface : Theme.of(context).hintColor)),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }
}
