import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/screens/chat_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contractors',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {}, // Add contractor functionality placeholder
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Add Contractor',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.getContractors(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Mock data if empty for visualization purposes since we might not have data in DB
                final contractors = (snapshot.hasData && snapshot.data!.isNotEmpty) 
                    ? snapshot.data! 
                    : [
                        {
                          'name': 'Mike Johnson',
                          'category': 'General Contractor',
                          'phone': '(555) 123-4567',
                          'email': 'mike.j@construction.com',
                          'license': '#C-12345',
                          'verified': true,
                          'experience': '5+ years experience',
                          'initials': 'MJ'
                        },
                         {
                          'name': 'Sarah Smith',
                          'category': 'Electrician',
                          'phone': '(555) 987-6543',
                          'email': 'sarah.s@sparky.com',
                          'license': '#E-99887',
                          'verified': true,
                          'experience': '10+ years experience',
                          'initials': 'SS'
                        }
                      ];

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: contractors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final c = contractors[index];
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: const Color(0xFFE3F2FD), // Light Blue
                                child: Text(
                                  c['initials'] ?? c['name'].substring(0, 1),
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1976D2), // Blue Text
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['name'],
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c['category'] ?? 'Contractor',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 24,
                                      runSpacing: 8,
                                      children: [
                                        if (c['phone'] != null)
                                          Text('Phone: ${c['phone']}', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700])),
                                        if (c['email'] != null)
                                          Text('Email: ${c['email']}', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700])),
                                        if (c['license'] != null)
                                          Text('License: ${c['license']}', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700])),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Pills
                                    Row(
                                      children: [
                                        if (c['verified'] == true)
                                          Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F5E9), // Light Green
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Verified',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF2E7D32),
                                              ),
                                            ),
                                          ),
                                        if (c['experience'] != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE3F2FD), // Light Blue
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              c['experience'],
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF1565C0),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Message Button
                                    OutlinedButton.icon(
                                      onPressed: () {
                                         Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                                            otherUserId: c['id'] ?? 'user_1',
                                            otherUserName: c['name'],
                                          )));
                                      },
                                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                      label: const Text('Message'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        side: BorderSide(color: Colors.grey[300]!),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
