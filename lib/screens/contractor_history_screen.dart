import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContractorHistoryScreen extends StatefulWidget {
  const ContractorHistoryScreen({super.key});

  @override
  State<ContractorHistoryScreen> createState() => _ContractorHistoryScreenState();
}

class _ContractorHistoryScreenState extends State<ContractorHistoryScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db.getContractorJobs(_auth.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allJobs = snapshot.data ?? [];
          final history = allJobs.where((j) => j['status'] == 'completed' || j['status'] == 'rejected').toList();

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('No project history yet', style: GoogleFonts.inter(color: Theme.of(context).hintColor)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final job = history[index];
              return _buildHistoryCard(job);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> job) {
    final isCompleted = job['status'] == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (isCompleted ? AppTheme.success : AppTheme.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
              color: isCompleted ? AppTheme.success : AppTheme.error,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job['title'] ?? 'Past Project', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(job['customerName'] ?? 'Unknown Customer', style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).hintColor)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${job['amount']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(
                isCompleted ? 'COMPLETED' : 'REJECTED',
                style: GoogleFonts.inter(
                  fontSize: 10, 
                  fontWeight: FontWeight.w900, 
                  color: isCompleted ? AppTheme.success : AppTheme.error,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }
}
