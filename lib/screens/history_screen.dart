import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/services/pdf_service.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:rap_app/screens/job_tracking_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();
    final PdfService pdf = PdfService();
    final AuthService auth = AuthService();

    return Scaffold(
      backgroundColor: AppTheme.webBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Jobs Section
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: db.getCustomerJobs(auth.currentUser?.uid ?? ''),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                      
                      final activeJobs = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ACTIVE JOBS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
                          const SizedBox(height: 16),
                          ...activeJobs.map((job) => _buildActiveJobCard(context, job)),
                          const SizedBox(height: 48),
                        ],
                      );
                    },
                  ),

                  Text('ESTIMATE HISTORY', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
                  const SizedBox(height: 16),

                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: db.getEstimateHistory(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }

                      final history = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          final date = item['createdAt'] != null ? (item['createdAt']).toDate() : DateTime.now();
                          return _buildHistoryCard(context, item, date, pdf);
                        },
                      );
                    },
                  ),
                ],
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
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'History',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              Text('Your past estimations and reports', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          Text(
            'No History Found',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first estimate to see it here.',
            style: GoogleFonts.inter(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item, DateTime date, PdfService pdf) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showEstimateDetails(context, item, pdf),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.sticky_note_2_outlined, color: AppTheme.primary),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['item_summary'] ?? 'Unknown Item',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${item['total_estimate_range_usd']['likely']}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 24),
                  ),
                  _buildConfidenceBadge(item['confidence_level']),
                ],
              ),
              const SizedBox(width: 16),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(String? level) {
    Color color = AppTheme.success;
    if (level?.toLowerCase() == 'medium') color = AppTheme.warning;
    if (level?.toLowerCase() == 'low') color = AppTheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        level?.toUpperCase() ?? 'N/A',
        style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  void _showEstimateDetails(BuildContext context, Map<String, dynamic> item, PdfService pdf) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(40),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['item_summary'],
                        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildConfidenceBadge(item['confidence_level']),
                const SizedBox(height: 32),
                
                _buildMetricRow('Labor Cost', '\$${item['labor_cost_final_usd']}', 'Includes 20% discount'),
                const Divider(height: 32),
                _buildMetricRow('Material Cost', '\$${item['material_cost_total_usd']}', 'Estimated market rates'),
                
                const SizedBox(height: 40),
                Text('ANALYSIS SUMMARY', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Text(
                  item['repair_vs_replace_note'],
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), height: 1.6),
                ),
                
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => pdf.generateAndPrintEstimate(item, null),
                          icon: const Icon(Icons.download_rounded, color: Colors.white),
                          label: const Text('Export PDF'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, String sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.primary)),
            Text(sub, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          ],
        ),
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
      ],
    );
  }
  Widget _buildActiveJobCard(BuildContext context, Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('IN PROGRESS', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.timelapse_rounded, color: Colors.white.withValues(alpha: 0.6)),
            ],
          ),
          const SizedBox(height: 20),
          Text(job['title'] ?? 'Repair Job', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Contractor: ${job['contractorName'] ?? 'Assigned Contractor'}', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                 Navigator.of(context).push(MaterialPageRoute(builder: (_) => JobTrackingScreen(job: job)));
              },
              icon: const Icon(Icons.map_rounded, color: AppTheme.primary),
              label: const Text('Track Live'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
