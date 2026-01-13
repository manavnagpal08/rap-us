import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';

class ContractorDashboard extends StatefulWidget {
  const ContractorDashboard({super.key});

  @override
  State<ContractorDashboard> createState() => _ContractorDashboardState();
}

class _ContractorDashboardState extends State<ContractorDashboard> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      backgroundColor: AppTheme.webBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsSection(),
                    const SizedBox(height: 48),
                    _buildSectionTitle('Active Projects'),
                    _buildProjectList(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contractor Dashboard',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              Text('Manage your business and leads', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
          // Removed Test Button
        ],
      ),
    );
  }

  void _showJobDialog(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('Job Details', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                   IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ]
              ),
              const SizedBox(height: 24),
              _detailRow('Project', job['title']),
              _detailRow('Customer', job['customerName']),
              _detailRow('Location', job['location']),
              _detailRow('Status', (job['status'] ?? 'pending').toUpperCase()),
              
              const SizedBox(height: 32),
              
              if (job['status'] == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                           await _db.updateContractorJobStatus(job['id'], 'rejected');
                           Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error), foregroundColor: AppTheme.error),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                           await _db.updateContractorJobStatus(job['id'], 'in_progress');
                           Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
                
               if (job['status'] == 'in_progress')
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                      onPressed: () async {
                         await _db.updateContractorJobStatus(job['id'], 'completed');
                         Navigator.pop(ctx);
                      },
                      child: const Text('Mark as Completed'),
                   ),
                 ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _db.getContractorStats(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'leads': 0, 'active': 0, 'earnings': 0.0};
        
        return Row(
          children: [
            _statCard('Total Leads', '${stats['leads']}', Icons.flash_on_rounded, AppTheme.accent),
            const SizedBox(width: 24),
            _statCard('Active Jobs', '${stats['active']}', Icons.work_outline_rounded, AppTheme.success),
            const SizedBox(width: 24),
            _statCard('Earnings', '\$${stats['earnings']}', Icons.payments_outlined, AppTheme.primary),
          ],
        );
      }
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () {
           // Placeholder for future filtering
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Filter by $label')));
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 24),
              Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              Text(label, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getContractorJobs(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }
        
        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No active jobs yet', style: GoogleFonts.inter(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return InkWell(
              onTap: () => _showJobDialog(job),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.maps_home_work_outlined, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job['title'] ?? 'Untitled Job', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Customer: ${job['customerName'] ?? 'Unknown'} • ${job['location'] ?? 'No Location'}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${job['amount'] ?? 0}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text((job['status'] ?? 'PENDING').toUpperCase(), style: const TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }
}
