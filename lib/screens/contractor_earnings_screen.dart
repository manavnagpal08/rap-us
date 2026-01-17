import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContractorEarningsScreen extends StatefulWidget {
  const ContractorEarningsScreen({super.key});

  @override
  State<ContractorEarningsScreen> createState() => _ContractorEarningsScreenState();
}

class _ContractorEarningsScreenState extends State<ContractorEarningsScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _db.getContractorStats(_auth.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data ?? {'earnings': 0.0, 'completed': 0};
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalBalance(stats['earnings'] ?? 0.0),
                const SizedBox(height: 40),
                Text('FINANCIAL OVERVIEW', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor, letterSpacing: 1.5)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildSmallStats('Projects', '${stats['completed'] ?? 0}', Icons.done_all_rounded, AppTheme.success)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSmallStats('Avg. Ticket', '\$${((stats['earnings'] ?? 0) / (stats['completed'] == 0 ? 1 : stats['completed'])).toStringAsFixed(0)}', Icons.analytics_outlined, AppTheme.accent)),
                  ],
                ),
                const SizedBox(height: 40),
                _buildPayoutSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalBalance(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Text('Total Revenue', style: GoogleFonts.inter(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Text('\$${amount.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('Verifying with AI Precision', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack);
  }

  Widget _buildSmallStats(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX();
  }

  Widget _buildPayoutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFF1F5F9),
            child: Icon(Icons.account_balance_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settled Balance', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Funds are ready for withdrawal', style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}
