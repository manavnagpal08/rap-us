import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/theme/app_theme.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();

    return Scaffold(
      backgroundColor: AppTheme.webBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: db.getContractors(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final contractors = snapshot.data ?? [];

                if (contractors.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(32),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    mainAxisExtent: 220,
                  ),
                  itemCount: contractors.length,
                  itemBuilder: (context, index) {
                    final contractor = contractors[index];
                    return _buildContractorCard(context, contractor);
                  },
                );
              },
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
                'Contractors',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              Text('Verified professionals in your area', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
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
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          Text(
            'Coming Soon to Your Area',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'We are currently onboarding top-tier contractors.',
            style: GoogleFonts.inter(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildContractorCard(BuildContext context, Map<String, dynamic> c) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                child: Text(
                  c['name'][0].toUpperCase(),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.accent),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.primary)),
                    Text(c['category'], style: GoogleFonts.inter(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.verified_rounded, color: AppTheme.success, size: 20),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text('${c['city']}, ${c['state']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                // Show contractor details dialog
                showDialog(
                  context: context, // Note: This needs context. Since we are in a helper method, we might need to pass context or refactor.
                  // Wait, we can't easily access context here if it's not passed. 
                  // Let's refactor _buildContractorCard to take context.
                  builder: (ctx) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      width: 500,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(radius: 30, backgroundColor: AppTheme.accent.withValues(alpha: 0.1), child: Text(c['name'][0], style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accent))),
                            const SizedBox(width: 20),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(c['name'], style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              Text(c['category'], style: GoogleFonts.inter(fontSize: 14, color: AppTheme.accent)),
                            ])),
                            IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close))
                          ]),
                          const SizedBox(height: 24),
                          Text('About', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
                          const SizedBox(height: 8),
                          Text(c['bio'] ?? 'No bio available.', style: GoogleFonts.inter(color: const Color(0xFF64748B), height: 1.5)),
                          const SizedBox(height: 24),
                          Row(children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Text('${c['city']}, ${c['state']}', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                          ]),
                          const SizedBox(height: 32),
                          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () async {
                             final auth = AuthService();
                             final db = DatabaseService();
                             final user = auth.currentUser;
                             
                             if (user == null) {
                               Navigator.pop(ctx);
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
                               return;
                             }
                             
                             await db.createJob({
                               'contractorId': c['id'],
                               'customerName': user.displayName ?? 'Customer',
                               'customerId': user.uid,
                               'title': 'New Lead from Marketplace',
                               'location': '${c['city']}, ${c['state']}',
                               'status': 'pending',
                               'amount': 0.0, // Initial leads have no amount
                             });
                             
                             Navigator.pop(ctx);
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection request sent!')));
                          }, child: const Text('Contact Contractor')))
                        ],
                      ),
                    ),
                  )
                );
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Text('View Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primary)),
            ),
          ),
        ],
      ),
    );
  }
}
