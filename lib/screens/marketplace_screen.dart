7      ),
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
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.contractors,
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
                Text(l10n.verifiedPros, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
              ],
            ),
          ],
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.storefront_rounded, size: 48, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.comingSoon,
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingContractors,
            style: GoogleFonts.inter(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildContractorCard(BuildContext context, Map<String, dynamic> c) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
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
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  c['name'][0].toUpperCase(),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                    Text(c['category'], style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.verified_rounded, color: AppTheme.success, size: 20),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).hintColor),
              const SizedBox(width: 4),
              Text('${c['city']}, ${c['state']}', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
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
                    backgroundColor: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      width: 500,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(radius: 30, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), child: Text(c['name'][0], style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))),
                            const SizedBox(width: 20),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(c['name'], style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                              Text(c['category'], style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.primary)),
                            ])),
                            IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close))
                          ]),
                          const SizedBox(height: 24),
                          Text(l10n.about, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
                          const SizedBox(height: 8),
                          Text(c['bio'] ?? l10n.noBio, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5)),
                          const SizedBox(height: 24),
                          Row(children: [
                            Icon(Icons.location_on_outlined, size: 18, color: Theme.of(context).hintColor),
                            const SizedBox(width: 8),
                            Text('${c['city']}, ${c['state']}', style: GoogleFonts.inter(color: Theme.of(context).hintColor)),
                          ]),
                          const SizedBox(height: 32),
                           Row(
                             children: [
                               Expanded(
                                 child: OutlinedButton(
                                   onPressed: () {
                                     Navigator.pop(ctx);
                                     Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                                       otherUserId: c['id'],
                                       otherUserName: c['name'],
                                     )));
                                   },
                                   style: OutlinedButton.styleFrom(
                                     foregroundColor: Theme.of(context).colorScheme.primary,
                                     side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                     padding: const EdgeInsets.symmetric(vertical: 16),
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                   ),
                                   child: Text(l10n.message),
                                 ),
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: ElevatedButton(
                                   onPressed: () async {
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
                             
                             if (ctx.mounted) Navigator.pop(ctx);
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection request sent!')));
                             }
                          }, 
                                   style: ElevatedButton.styleFrom(
                                     padding: const EdgeInsets.symmetric(vertical: 16),
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                   ),
                                   child: Text(l10n.hire),
                                 ),
                               ),
                             ],
                           )
                        ],
                      ),
                    ),
                  )
                );
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
              ),
              child: Text(l10n.viewProfile, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
            ),
          ),
        ],
      ),
    );
  }
}
