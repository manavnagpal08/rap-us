import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/screens/chat_screen.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 40 : 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsSection(context),
                    const SizedBox(height: 32),
                    _buildVerificationBanner(context),
                    const SizedBox(height: 40),
                    _buildSectionTitle(context, l10n.activeProjects),
                    _buildProjectList(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.proDashboard,
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _db.getUserProfile(_auth.currentUser!.uid),
                      builder: (context, profileSnapshot) {
                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: _db.getContractors().first,
                          builder: (context, contractorsSnapshot) {
                            final contractor = contractorsSnapshot.data?.firstWhere((c) => (c['id'] ?? '') == _auth.currentUser!.uid, orElse: () => {});
                            if (contractor?['isVerified'] == true) {
                              return const Icon(Icons.verified_rounded, color: AppTheme.success, size: 20);
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      }
                    ),
                  ],
                ),
                Text(l10n.manageAccount, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _createTestJob,
              icon: const Icon(Icons.bug_report_rounded, size: 18, color: Colors.white),
              label: Text(l10n.addTestJob, style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTestJob() async {
    try {
      await _db.createJob({
        'title': 'Leaky Faucet Repair',
        'customerName': 'John Smith (Test)',
        'location': 'Downtown, LA',
        'amount': 150.0,
        'status': 'pending',
        'customerId': 'test_user_123',
        'contractorId': _auth.currentUser!.uid,
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.testJobCreated)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showJobDialog(Map<String, dynamic> job) {
    final l10n = AppLocalizations.of(context)!;
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
                   Text(l10n.jobDetails, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                   IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ]
              ),
              const SizedBox(height: 24),
              _detailRow(l10n.project, job['title']),
              _detailRow(l10n.customer, job['customerName']),
              _detailRow(l10n.location, job['location']),
              _detailRow(l10n.status, (job['status'] ?? 'pending').toUpperCase()),
              
              const SizedBox(height: 32),
              
              if (job['status'] == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                           await _db.updateContractorJobStatus(job['id'], 'rejected');
                           if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error), foregroundColor: AppTheme.error),
                        child: Text(l10n.reject),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                           await _db.updateContractorJobStatus(job['id'], 'in_progress');
                           if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                        child: Text(l10n.accept),
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
                         if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(l10n.markAsCompleted),
                   ),
                 ),
                if (job['status'] == 'in_progress' || job['status'] == 'pending')
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                           Navigator.pop(ctx);
                           if (!mounted) return;
                           Navigator.of(context).push(MaterialPageRoute(
                             builder: (_) => ChatScreen(
                               otherUserId: job['customerId'],
                               otherUserName: job['customerName'] ?? 'Customer',
                             ),
                           ));
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: Text(l10n.chatWithCustomer),
                      ),
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
          SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _db.getContractors().first,
      builder: (context, snapshot) {
        final contractor = snapshot.data?.firstWhere((c) => c['id'] == _auth.currentUser!.uid, orElse: () => {});
        final isVerified = contractor?['isVerified'] == true;

        if (isVerified) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.security_rounded, color: AppTheme.warning, size: 32),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.verifiedPro, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    Text(l10n.unverifiedNote, style: GoogleFonts.inter(color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showVerificationDialog(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, foregroundColor: Colors.white),
                child: Text(l10n.verifyNow),
              ),
            ],
          ),
        );
      }
    );
  }

  void _showVerificationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.docVerificationTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.docVerificationSubtitle),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.insurancePolicy),
              subtitle: Text(l10n.pdfOrImage),
              trailing: const Icon(Icons.upload_file),
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              await _db.requestVerification(_auth.currentUser!.uid, {'status': 'submitted'});
              if (!mounted) return;
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.docsSubmitted)));
              }
            },
            child: Text(l10n.submitForAiReview),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, dynamic>>(
      future: _db.getContractorStats(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'leads': 0, 'active': 0, 'earnings': 0.0};
        
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _statCard(context, l10n.totalLeads, '${stats['leads']}', Icons.flash_on_rounded, AppTheme.accent),
            _statCard(context, l10n.activeJobs, '${stats['active']}', Icons.work_outline_rounded, AppTheme.success),
            _statCard(context, l10n.revenue, '\$${stats['earnings']}', Icons.payments_outlined, Theme.of(context).colorScheme.primary),
          ],
        );
      }
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color color) {
    bool isWide = MediaQuery.of(context).size.width > 900;
    
    return Container(
      width: isWide ? 300 : (MediaQuery.of(context).size.width - 60) / 2,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          Text(label, style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildProjectList(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getContractorJobs(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: Padding(
             padding: EdgeInsets.all(40.0),
             child: CircularProgressIndicator(),
           ));
        }
        
        final jobs = snapshot.data ?? [];
        final l10n = AppLocalizations.of(context)!;
        if (jobs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(l10n.noActiveJobs, style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 16)),
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
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.maps_home_work_outlined, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job['title'] ?? l10n.untitledJob, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                          Text('${l10n.customer}: ${job['customerName'] ?? 'Unknown'} • ${job['location'] ?? 'No Location'}', style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).hintColor)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${job['amount'] ?? 0}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text((job['status'] ?? 'PENDING').toUpperCase(), style: const TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.chevron_right_rounded, color: Theme.of(context).hintColor),
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
