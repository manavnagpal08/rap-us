import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/l10n/app_localizations.dart';

class BidComparisonScreen extends StatefulWidget {
  final String jobId;
  const BidComparisonScreen({super.key, required this.jobId});

  @override
  State<BidComparisonScreen> createState() => _BidComparisonScreenState();
}

class _BidComparisonScreenState extends State<BidComparisonScreen> {
  final DatabaseService _db = DatabaseService();
  
  // Mock data for initial implementation logic (since we might not have live bids yet)
  // In a real scenario, we stream from _db.getBidsForJob(widget.jobId)
  
  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsive table
    final isWide = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Bid Comparison', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db.getBidsForJob(widget.jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // If no bids, show empty state
          final bids = snapshot.data ?? [];
          
          if (bids.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.gavel_outlined, size: 64, color: Theme.of(context).dividerColor),
                   const SizedBox(height: 16),
                   Text('No bids received yet.', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
                   const SizedBox(height: 8),
                   Text('Contractors will appear here once they bid.', style: GoogleFonts.inter(color: Theme.of(context).hintColor)),
                 ],
               ),
             );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Make an informed decision.',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Compare costs, availability, and reputation side-by-side.',
                  style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 32),
                
                // Horizontal Scroll for the Table on Mobile
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       // Labels Column
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const SizedBox(height: 120), // Spacer for headers
                           _buildLabel('Total Cost'),
                           _buildLabel('Availability'),
                           _buildLabel('Time to Complete'),
                           _buildLabel('Reputation'),
                           _buildLabel('Verified Status'),
                           _buildLabel('Warranty'),
                           const SizedBox(height: 24),
                           _buildLabel(''), // Spacer for actions
                         ],
                       ),
                       
                       // Bid Columns
                       ...bids.map((bid) => _buildBidColumn(bid)).toList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      height: 60,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(right: 24),
      child: Text(
        text,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Theme.of(context).hintColor),
      ),
    );
  }

  Widget _buildBidColumn(Map<String, dynamic> bid) {
    final bool isBestValue = bid['isBestValue'] == true;
    final bool isVerified = bid['isVerified'] == true;
    
    return Container(
      width: 250,
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isBestValue ? AppTheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: isBestValue ? 2 : 1
        ),
        boxShadow: isBestValue ? [
          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0,10))
        ] : null,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isBestValue ? AppTheme.primary.withValues(alpha: 0.05) : Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                if (isBestValue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                    child: Text('BEST VALUE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: Text(bid['contractorName']?[0] ?? 'C', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(bid['contractorName'] ?? 'Contractor', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('${bid['rating'] ?? 0.0}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Data Rows
          _buildCell('\$${bid['amount'] ?? 0}', isBold: true, color: AppTheme.primary),
          _buildCell(bid['availability'] ?? 'Unknown'),
          _buildCell(bid['duration'] ?? 'Unknown'),
          _buildStars(bid['rating'] ?? 0.0),
          _buildVerificationBadge(isVerified),
          _buildCell(bid['warranty'] ?? 'None'),
          
          // Action Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () {
                _db.acceptBid(widget.jobId, bid['id'], bid['contractorId'], (bid['amount'] as num).toDouble());
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid Accepted! Preparing contract...')));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isBestValue ? AppTheme.primary : Theme.of(context).cardColor,
                foregroundColor: isBestValue ? Colors.white : AppTheme.primary,
                side: isBestValue ? null : const BorderSide(color: AppTheme.primary),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Accept Bid'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(String text, {bool isBold = false, Color? color}) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isBold ? 18 : 14,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          return Icon(
            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber,
            size: 18,
          );
        }),
      ),
    );
  }

  Widget _buildVerificationBadge(bool verified) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: verified 
        ? const Icon(Icons.verified_rounded, color: AppTheme.success)
        : const Icon(Icons.cancel_outlined, color: Colors.grey),
    );
  }
}
