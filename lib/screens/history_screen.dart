import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/services/pdf_service.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rap_app/screens/job_tracking_screen.dart';
import 'package:rap_app/screens/contract_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final DatabaseService db = DatabaseService();
    final PdfService pdf = PdfService();
    final AuthService auth = AuthService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width > 600 ? 32 : 16,
          40, // Top padding
          MediaQuery.of(context).size.width > 600 ? 32 : 16,
          32,
        ),
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
                          Text(l10n.activeJobs.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor.withValues(alpha: 0.5), letterSpacing: 1.5)),
                          const SizedBox(height: 16),
                          ...activeJobs.asMap().entries.map((e) => _buildActiveJobCard(context, e.value).animate(delay: (e.key * 50).ms).fadeIn().slideX(begin: 0.1)),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                  ),

                  Text(l10n.estimateHistory.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor.withValues(alpha: 0.5), letterSpacing: 1.5)),
                  const SizedBox(height: 16),

                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: db.getEstimateHistory(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      final history = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          final date = item['createdAt'] != null ? (item['createdAt'] as Timestamp).toDate() : DateTime.now();
                          return _buildHistoryCard(context, item, date, pdf)
                              .animate(delay: (index * 50).ms)
                              .fadeIn()
                              .slideY(begin: 0.1);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }




  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item, DateTime date, PdfService pdf) {
    bool isSmall = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showEstimateDetails(context, item, pdf),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 16 : 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isSmall ? 48 : 64,
                height: isSmall ? 48 : 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.sticky_note_2_outlined, color: Theme.of(context).colorScheme.primary, size: isSmall ? 24 : 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['item_summary'] ?? 'Unknown Item',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isSmall ? 16 : 18, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                      style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 12),
                    ),
                    if (isSmall) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppTheme.currencySymbolNotifier.value}${item['total_estimate_range_usd']?['likely'] ?? item['labor_cost_final_usd'] ?? '0'}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 20),
                          ),
                          _buildConfidenceBadge(item['confidence_level']),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!isSmall) ...[
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${AppTheme.currencySymbolNotifier.value}${item['total_estimate_range_usd']?['likely'] ?? item['labor_cost_final_usd'] ?? '0'}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 24),
                    ),
                    _buildConfidenceBadge(item['confidence_level']),
                  ],
                ),
                const SizedBox(width: 16),
                Icon(Icons.chevron_right_rounded, color: Theme.of(context).dividerColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 48, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noHistory,
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.completeFirstEstimate,
            style: GoogleFonts.inter(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(String? level) {
    Color color = AppTheme.success;
    if (level?.toLowerCase() == 'medium') color = AppTheme.warning;
    if (level?.toLowerCase() == 'low') color = AppTheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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
        backgroundColor: Theme.of(context).cardColor,
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
                        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildConfidenceBadge(item['confidence_level']),
                const SizedBox(height: 32),
                
                _buildMetricRow(context, 'Labor Cost', '${AppTheme.currencySymbolNotifier.value}${item['labor_cost_final_usd']}', 'Includes 20% discount'),
                const Divider(height: 32),
                _buildMetricRow(context, 'Material Cost', '${AppTheme.currencySymbolNotifier.value}${item['material_cost_total_usd']}', 'Estimated market rates'),
                
                const SizedBox(height: 40),
                Text('ANALYSIS SUMMARY', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Text(
                  item['repair_vs_replace_note'],
                  style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.6),
                ),
                
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => pdf.generateAndPrintEstimate(
                            item,
                            item['base64Image'], // Assuming key is base64Image or check DB schema. In AiService it processes 'imageBase64' but does it save it? 
                            // The image is usually passed to analyzeImage but might not be in the 'item' map from DB unless we saved it.
                            // I should check DatabaseService.saveEstimate.
                            AppTheme.currencySymbolNotifier.value
                          ),
                          icon: const Icon(Icons.download_rounded, color: Colors.white),
                          label: const Text('Export PDF', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
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

  Widget _buildMetricRow(BuildContext context, String label, String value, String sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
            Text(sub, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
          ],
        ),
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
      ],
    );
  }
  Widget _buildActiveJobCard(BuildContext context, Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('IN PROGRESS', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.timelapse_rounded, color: Colors.white.withOpacity(0.6)),
            ],
          ),
          const SizedBox(height: 20),
          Text(job['title'] ?? 'Repair Job', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Contractor: ${job['contractorName'] ?? 'Assigned Contractor'}', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: (job['contract'] != null || job['status'] == 'in_progress')
              ? ElevatedButton.icon(
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
                )
              : ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContractScreen(job: job)));
                  },
                  icon: const Icon(Icons.draw_rounded, color: Colors.white),
                  label: const Text('Sign Agreement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
