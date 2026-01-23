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
  bool _showJobs = false;
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showJobs ? _buildJobsGrid(context) : _buildContractorsGrid(context),
            ),
          ),
          // Floating Togglebar
          Positioned(
            top: 24,
            left: 24,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  _toggleButton(l10n.contractors, !_showJobs, () => setState(() => _showJobs = false)),
                  _toggleButton(l10n.jobBoard, _showJobs, () => setState(() => _showJobs = true)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildContractorsGrid(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getContractors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context);
        }

        final contractors = snapshot.data!;
        
        // Responsive columns
        final width = MediaQuery.of(context).size.width;
        int crossAxisCount = 1;
        if (width > 700) crossAxisCount = 2;
        if (width > 1100) crossAxisCount = 3;
        if (width > 1500) crossAxisCount = 4;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            mainAxisExtent: 320, // Taller card for better layout
          ),
          itemCount: contractors.length,
          itemBuilder: (context, index) => _buildContractorCard(context, contractors[index])
              .animate(delay: (index * 50).ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
        );
      },
    );
  }

  Widget _buildJobsGrid(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getPublicJobs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context, isJobs: true);
        }

        final jobs = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            mainAxisExtent: 280,
          ),
          itemCount: jobs.length,
          itemBuilder: (context, index) => _buildJobCard(context, jobs[index])
              .animate(delay: (index * 100).ms)
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack)
              .slideY(begin: 0.2, end: 0),
        );
      },
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) {
    final l10n = AppLocalizations.of(context)!; // Added missing l10n definition
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.rocket_launch_outlined, color: AppTheme.accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job['title'] ?? 'Untitled Project', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Posted by ${job['customerName']}', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.accent),
              const SizedBox(width: 4),
              Text(job['location'] ?? 'Remote', style: GoogleFonts.inter(fontSize: 12)),
              const Spacer(),
              Text('Valued at \$${job['amount']}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.success)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _showBidDialog(context, job),
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(l10n.submitBid, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBidDialog(BuildContext context, Map<String, dynamic> job) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController(text: job['amount'].toString());
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.submitBid, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: l10n.bidAmount, prefixIcon: const Icon(Icons.attach_money)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Notes to Customer', hintText: 'Explain why you are the best fit...'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _db.submitBid(job['id'], {
                'amount': double.tryParse(amountController.text) ?? 0.0,
                'note': noteController.text,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.bidSuccess)));
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {bool isJobs = false}) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(isJobs ? Icons.work_outline_rounded : Icons.storefront_rounded, size: 48, color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 24),
            Text(
              isJobs ? 'No Open Jobs' : l10n.comingSoon,
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              isJobs ? 'Check back later for new opportunities.' : l10n.onboardingContractors,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Theme.of(context).hintColor),
            ),
            if (!isJobs) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _requestCoverage(context),
                icon: const Icon(Icons.map_rounded),
                label: const Text('Request Coverage in my Area'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _requestCoverage(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Coverage'),
        content: const Text('We will notify our network of pros about interest in your area. You will receive an alert when a verified contractor joins.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }


  Widget _buildContractorCard(BuildContext context, Map<String, dynamic> c) {
    final l10n = AppLocalizations.of(context)!;
    final isGuest = _auth.currentUser == null; 

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showContractorDetails(context, c),
          hoverColor: Theme.of(context).primaryColor.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Avatar + Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Container(
                       width: 64,
                       height: 64,
                       decoration: BoxDecoration(
                         gradient: LinearGradient(
                           colors: [
                             Theme.of(context).primaryColor.withValues(alpha: 0.1),
                             Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1)
                           ],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                         ),
                         shape: BoxShape.circle,
                       ),
                       alignment: Alignment.center,
                       child: Text(
                         c['name'][0].toUpperCase(),
                         style: GoogleFonts.outfit(
                           fontSize: 28,
                           fontWeight: FontWeight.bold,
                           color: Theme.of(context).primaryColor,
                         ),
                       ),
                     ),
                     const Spacer(),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                       decoration: BoxDecoration(
                         color: AppTheme.success.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
                       ),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           const Icon(Icons.verified_rounded, color: AppTheme.success, size: 14),
                           const SizedBox(width: 4),
                           Text(
                             "VERIFIED",
                             style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success, letterSpacing: 0.5),
                           ),
                         ],
                       ),
                     )
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Info
                Text(
                  c['name'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c['category'].toString().toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).hintColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${c['city']}, ${c['state']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                const Divider(height: 32),
                
                // Action
                if (isGuest)
                   SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: const Text('Login to Connect'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).hintColor,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                             onPressed: () => _showContractorDetails(context, c),
                             style: OutlinedButton.styleFrom(
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                               side: BorderSide(color: Theme.of(context).dividerColor),
                             ),
                             child: Text(l10n.viewProfile),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 44,
                        width: 44,
                        child: IconButton.filled(
                          onPressed: () {
                             Navigator.push(
                               context, 
                               MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: c['id'], otherUserName: c['name']))
                             );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                          style: IconButton.styleFrom(
                             backgroundColor: Theme.of(context).primaryColor,
                             foregroundColor: Colors.white,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      )
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContractorDetails(BuildContext context, Map<String, dynamic> c) {
    final l10n = AppLocalizations.of(context)!;
    final isGuest = _auth.currentUser == null;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).colorScheme.tertiary
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(Icons.close, color: Colors.white),
                              ),
                            ),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 4),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                c['name'][0].toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              c['name'],
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                c['category'].toString().toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats / Location Row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "LOCATION",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${c['city']}, ${c['state']}',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_rounded, color: AppTheme.success, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        "VERIFIED PRO",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Bio
                            Text(
                              l10n.about,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              c['bio'] ?? l10n.noBio,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                height: 1.6,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Actions
                            if (isGuest)
                              Center(
                                child: Text(
                                  "Login to call or message",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                                            otherUserId: c['id'],
                                            otherUserName: c['name'],
                                          )));
                                        },
                                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                                        label: Text(l10n.message),
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final user = _auth.currentUser;
                                          if (user == null) {
                                            Navigator.pop(ctx);
                                            return;
                                          }
                                          await _db.createJob({
                                            'contractorId': c['id'],
                                            'customerName': user.displayName ?? 'Customer',
                                            'customerId': user.uid,
                                            'title': 'New Lead from Marketplace',
                                            'location': '${c['city']}, ${c['state']}',
                                            'status': 'pending',
                                            'amount': 0.0,
                                          });
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Connection request sent!'))
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.flash_on_rounded),
                                        label: Text(l10n.hire),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
