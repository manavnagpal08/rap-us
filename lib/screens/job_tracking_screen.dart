import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/screens/group_chat_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobTrackingScreen({super.key, required this.job});

  @override
  State<JobTrackingScreen> createState() => _JobTrackingScreenState();
}

class _JobTrackingScreenState extends State<JobTrackingScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('jobs').doc(widget.job['id']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final jobData = snapshot.data?.data() ?? widget.job;
        final jobId = snapshot.data?.id ?? widget.job['id'];
        final job = {...jobData, 'id': jobId};
        
        final status = job['status'] ?? 'pending';
        final steps = ['pending', 'in_progress', 'completed'];
        final currentStep = steps.indexOf(status);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, job),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(context, currentStep),
                      if (job['aiAccuracyBadge'] != null) ...[
                        const SizedBox(height: 24),
                        _buildAccuracySection(context, job),
                      ],
                      const SizedBox(height: 32),
                      _buildSectionTitle('Change Orders'),
                      _buildChangeOrdersSection(context, job),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Project Team'),
                      _buildTeamSection(context, job),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Progress Logs'),
                      _buildLogsSection(context, job),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Site Visit Booking'),
                      _buildBookingSection(context, job),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToTeamChat(context, job),
            icon: const Icon(Icons.group_rounded, color: Colors.white),
            label: const Text('Open Team Chat', style: TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.primary,
          ).animate().scale(delay: 500.ms),
        );
      }
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic> job) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Theme.of(context).cardColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(job['title'] ?? 'Job Tracking', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
        background: Opacity(
          opacity: 0.6,
          child: Image.network(
            'https://maps.googleapis.com/maps/api/staticmap?center=Brooklyn+Bridge,New+York,NY&zoom=13&size=600x300&maptype=roadmap&markers=color:blue%7Clabel:S%7C40.702147,-74.015794&markers=color:green%7Clabel:G%7C40.711614,-74.012318&key=YOUR_API_KEY',
            fit: BoxFit.cover,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.ios_share_rounded),
          onPressed: () => _shareProject(job),
        ),
      ],
    );
  }

  Widget _buildAccuracySection(BuildContext context, Map<String, dynamic> job) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppTheme.success, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Accuracy Improved!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.success)),
                Text('This project had ${job['aiAccuracyBadge']} estimate accuracy.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.success)),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildChangeOrdersSection(BuildContext context, Map<String, dynamic> job) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getChangeOrders(job['id']),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Text('No change orders requested.', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor));
        }

        return Column(
          children: orders.map((order) {
            final isPending = order['status'] == 'pending';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isPending ? AppTheme.warning.withValues(alpha: 0.3) : Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('New Scope Requested', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      Text('\$${order['requestedAmount']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(order['reason'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).hintColor)),
                  if (isPending) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _db.approveChangeOrder(job['id'], order['id'], (order['requestedAmount'] as num).toDouble()),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text('Status: ${order['status'].toString().toUpperCase()}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success)),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _shareProject(Map<String, dynamic> job) {
    final shareUrl = 'https://rap-us.web.app/project/${job['id']}';
    Share.share('Check out our project progress on RAP: $shareUrl');
  }

  Widget _buildStatusCard(BuildContext context, int currentStep) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusStep('Pending', currentStep >= 0),
              _statusLine(currentStep >= 1),
              _statusStep('Working', currentStep >= 1),
              _statusLine(currentStep >= 2),
              _statusStep('Done', currentStep >= 2),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _getStatusMessage(currentStep),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _statusStep(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: active ? AppTheme.success : Theme.of(context).dividerColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: active ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? AppTheme.success : Theme.of(context).hintColor)),
      ],
    );
  }

  Widget _statusLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: active ? AppTheme.success : Theme.of(context).dividerColor.withValues(alpha: 0.2),
      ),
    );
  }

  String _getStatusMessage(int step) {
    switch (step) {
      case 0: return 'Your request has been posted. Waiting for work to begin.';
      case 1: return 'The contractor is currently working on your project.';
      case 2: return 'Project complete! Please review the final work.';
      default: return 'Project status update.';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor, letterSpacing: 1.2)),
    );
  }

  Widget _buildTeamSection(BuildContext context, Map<String, dynamic> job) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), child: const Icon(Icons.construction_rounded, color: AppTheme.primary)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job['contractorName'] ?? 'Assigned Pro', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Main Contractor', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _callContractor(),
            icon: const Icon(Icons.phone_outlined, color: AppTheme.success),
            style: IconButton.styleFrom(backgroundColor: AppTheme.success.withValues(alpha: 0.1)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildLogsSection(BuildContext context, Map<String, dynamic> job) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getProjectLogs(job['id']),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                Icon(Icons.history_edu_rounded, color: Theme.of(context).hintColor.withValues(alpha: 0.2), size: 40),
                const SizedBox(height: 12),
                Text('No progress updates yet', style: GoogleFonts.inter(color: Theme.of(context).hintColor)),
              ],
            ),
          );
        }

        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log['imageUrl'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(log['imageUrl'], height: 80, width: double.infinity, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        height: 80, 
                        width: double.infinity,
                        decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.image_outlined),
                      ),
                    const SizedBox(height: 12),
                    Text(log['note'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Text(_formatDate(log['createdAt']), style: GoogleFonts.inter(fontSize: 10, color: Theme.of(context).hintColor)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBookingSection(BuildContext context, Map<String, dynamic> job) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text('Schedule Site Visit', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            job['siteVisit'] != null 
                ? 'Visit scheduled for ${_formatDate(job['siteVisit'])}'
                : 'Book a 15-minute inspection to finalize project scope and materials.',
            style: GoogleFonts.inter(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showBookingDialog(context, job),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primary, elevation: 0),
              child: const Text('Book Now'),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context, Map<String, dynamic> job) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );

      if (pickedTime != null && mounted) {
        final bookingDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );
        
        await _db.bookSiteVisit(job['contractorId'], job['id'], bookingDateTime);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking confirmed! Profile synced.')));
        }
      }
    }
  }

  void _navigateToTeamChat(BuildContext context, Map<String, dynamic> job) async {
    final members = [job['customerId'], job['contractorId']];
    // In a real app we'd fetch or create the groupChatId
    // For demo, we use jobId as the groupChatId base
    final groupChatId = 'team_${job['id']}';
    
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GroupChatScreen(groupChatId: groupChatId, jobTitle: job['title']),
    ));
  }

  Future<void> _callContractor() async {
    final Uri telLauncherUri = Uri(scheme: 'tel', path: '5550123'); // Mock phone for demo, would come from contractor data
    if (await canLaunchUrl(telLauncherUri)) {
      await launchUrl(telLauncherUri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch dialer.')));
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '...';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '...';
    }
    return DateFormat('MMM dd, hh:mm a').format(date);
  }
}
