import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContractorLeadsScreen extends StatefulWidget {
  const ContractorLeadsScreen({super.key});

  @override
  State<ContractorLeadsScreen> createState() => _ContractorLeadsScreenState();
}

class _ContractorLeadsScreenState extends State<ContractorLeadsScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db.getContractorJobs(_auth.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allJobs = snapshot.data ?? [];
          final leads = allJobs.where((j) => j['status'] == 'pending' || j['status'] == 'new').toList();

          if (leads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_off_rounded, size: 64, color: Theme.of(context).hintColor.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('No new leads at the moment', style: GoogleFonts.inter(color: Theme.of(context).hintColor)),
                  const SizedBox(height: 8),
                  Text('Check back later for new opportunities!', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor.withOpacity(0.6))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: leads.length,
            itemBuilder: (context, index) {
              final lead = leads[index];
              return _buildLeadCard(lead);
            },
          );
        },
      ),
    );
  }

  Widget _buildLeadCard(Map<String, dynamic> lead) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: AppTheme.accent.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: AppTheme.accent),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead['title'] ?? 'New Request', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).hintColor),
                          const SizedBox(width: 4),
                          Text(lead['location'] ?? 'Unknown Location', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text('\$${lead['amount']}', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.accent)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.02),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _db.updateContractorJobStatus(lead['id'], 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(color: AppTheme.error.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.reject),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _db.updateContractorJobStatus(lead['id'], 'in_progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.accept),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
