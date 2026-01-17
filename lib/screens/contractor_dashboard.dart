import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/screens/chat_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:rap_app/services/ai_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/screens/verification_center_screen.dart';

class ContractorDashboard extends StatefulWidget {
  const ContractorDashboard({super.key});

  @override
  State<ContractorDashboard> createState() => _ContractorDashboardState();
}

class _ContractorDashboardState extends State<ContractorDashboard> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  final AiService _ai = AiService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) return const Center(child: Text('Please log in'));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 40 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsSection(context),
                const SizedBox(height: 32),
                _buildActionGrid(context),
                const SizedBox(height: 40),
                _buildVerificationBanner(context),
                const SizedBox(height: 40),
                _buildSectionTitle(context, l10n.activeProjects),
                _buildProjectList(context),
                const SizedBox(height: 48),
                _buildActivityFeed(context),
                const SizedBox(height: 48),
                _buildMarketingSection(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Remove _buildHeader as it's now handled by MainScreen contextually.


  // Removed _createTestJob as per user request to remove debug/demo data

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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showChangeOrderDialog(job);
                          },
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Change Order'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.warning, side: const BorderSide(color: AppTheme.warning)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showCompleteJobDialog(job);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                          child: Text(l10n.markAsCompleted),
                        ),
                      ),
                    ],
                  ),
                if (job['status'] == 'in_progress' || job['status'] == 'pending')
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
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
                        if (job['status'] == 'in_progress') ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showAddLogDialog(job);
                              },
                              icon: const Icon(Icons.add_a_photo_outlined),
                              label: const Text('Post Update'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Pro Mode: Voice Log
                  if (job['status'] == 'in_progress')
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.1), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.mic_none_rounded, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pro Mode: Hands-Free Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                Text('Tap & say "Finished framing..."', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
                              ],
                            ),
                          ),
                          IconButton.filled(
                            onPressed: () {
                               Navigator.pop(ctx);
                               _startVoiceLogSession(job);
                            }, 
                            icon: const Icon(Icons.mic),
                            style: IconButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                          ),
                        ],
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

  void _showChangeOrderDialog(Map<String, dynamic> job) {
    final amountController = TextEditingController(text: job['amount'].toString());
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Change Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'New Total Amount (\$)', prefixIcon: Icon(Icons.attach_money)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason for Change', hintText: 'Explain the scope change...'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('AI will analyze this reason for the customer.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.accent))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _db.requestChangeOrder(job['id'], {
                'requestedAmount': double.tryParse(amountController.text) ?? 0.0,
                'reason': reasonController.text,
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  void _showCompleteJobDialog(Map<String, dynamic> job) {
    final costController = TextEditingController(text: job['amount'].toString());
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the final actual cost of the project to calculate AI accuracy.'),
            const SizedBox(height: 16),
            TextField(
              controller: costController,
              decoration: const InputDecoration(labelText: 'Final Actual Cost (\$)', prefixIcon: Icon(Icons.payments_outlined)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final finalCost = double.tryParse(costController.text) ?? 0.0;
              await _db.completeJobWithAccuracy(job['id'], finalCost);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Finalize Project'),
          ),
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
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationCenterScreen()));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, foregroundColor: Colors.white),
                child: Text(l10n.verifyNow),
              ),
            ],
          ),
        );
      }
    );
  }

  void _showAddLogDialog(Map<String, dynamic> job) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Post Progress Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add_a_photo_rounded, size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(hintText: 'Describe the work done...', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isEmpty) return;
              await _db.addProgressLog(job['id'], noteController.text.trim());
              if (!ctx.mounted) return;
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress log posted!')));
            },
            child: const Text('Post Update'),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    File? selectedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.docVerificationTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.docVerificationSubtitle),
                const SizedBox(height: 24),
                ListTile(
                  leading: Icon(selectedFile != null ? Icons.check_circle_rounded : Icons.description_outlined, 
                      color: selectedFile != null ? AppTheme.success : null),
                  title: Text(l10n.insurancePolicy),
                  subtitle: Text(selectedFile != null ? 'File selected: ${selectedFile!.path.split('/').last}' : l10n.pdfOrImage),
                  trailing: const Icon(Icons.upload_file),
                  onTap: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    );
                    if (result != null) {
                      setDialogState(() => selectedFile = File(result.files.single.path!));
                    }
                  },
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text('Uploading highly secured documents...', style: GoogleFonts.inter(fontSize: 10, color: Theme.of(context).hintColor)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: (selectedFile == null || isUploading) ? null : () async {
                  setDialogState(() => isUploading = true);
                  
                  final uid = _auth.currentUser!.uid;
                  final fileName = 'verification/$uid/insurance_${DateTime.now().millisecondsSinceEpoch}.${selectedFile!.path.split('.').last}';
                  
                  final downloadUrl = await _db.uploadFile(fileName, selectedFile!);
                  
                  if (downloadUrl != null) {
                    await _db.requestVerification(uid, {
                      'insuranceUrl': downloadUrl,
                      'fileName': selectedFile!.path.split('/').last,
                      'uploadedAt': DateTime.now().toIso8601String(),
                    });
                    
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.docsSubmitted)));
                    }
                  } else {
                    setDialogState(() => isUploading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Please try again.'), backgroundColor: AppTheme.error));
                    }
                  }
                },
                child: isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(l10n.submitForAiReview),
              ),
            ],
          );
        }
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
        
        final allJobs = snapshot.data ?? [];
        final jobs = allJobs.where((j) => j['status'] == 'in_progress').toList();
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
  void _startVoiceLogSession(Map<String, dynamic> job) {
    String recognizedText = '';
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Auto-start listening when sheet opens
          if (!_isListening && _speechEnabled) {
            _speech.listen(
              onResult: (result) {
                setSheetState(() {
                  recognizedText = result.recognizedWords;
                });
              },
            ).then((_) {
               setSheetState(() => _isListening = true);
            });
          }

          return Container(
            height: 400,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: _isListening ? AppTheme.error.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                    color: _isListening ? AppTheme.error : AppTheme.primary,
                    size: 40,
                  ).animate(target: _isListening ? 1 : 0).shake(hz: 2),
                ),
                const SizedBox(height: 24),
                Text(
                  _isListening ? 'Listening...' : 'Processing...',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        recognizedText.isEmpty ? 'Speak now...' : recognizedText,
                        style: GoogleFonts.inter(
                          fontSize: 18, 
                          color: recognizedText.isEmpty ? Colors.grey : Colors.black87
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _speech.stop();
                          setSheetState(() => _isListening = false);
                          Navigator.pop(ctx);
                        },
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: recognizedText.isEmpty ? null : () async {
                          _speech.stop();
                          setSheetState(() => _isListening = false);
                          
                          // Process with AI
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI is formatting your log...')));
                          Navigator.pop(ctx);
                          
                          try {
                            final processed = await _ai.parseVoiceLog(recognizedText);
                            final note = processed['log_note'];
                            final time = processed['time_spent']; 
                            
                            final finalLog = time != null ? "$note (Time: $time)" : note;
                            
                            await _db.addProgressLog(job['id'], finalLog);
                            if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log Posted Successfully!'), backgroundColor: AppTheme.success));
                            }
                          } catch (e) {
                             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Post Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      _speech.stop();
      setState(() => _isListening = false);
    });
  }

  Widget _buildActionGrid(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _actionCard(
          context,
          'Find Leads',
          Icons.search_rounded,
          const Color(0xFF6366F1),
          () => Navigator.pushNamed(context, '/contractor_leads'),
        ),
        _actionCard(
          context,
          'Earnings',
          Icons.account_balance_wallet_outlined,
          const Color(0xFF10B981),
          () => Navigator.pushNamed(context, '/contractor_earnings'),
        ),
        _actionCard(
          context,
          'Project History',
          Icons.history_rounded,
          const Color(0xFFF59E0B),
          () => Navigator.pushNamed(context, '/contractor_history'),
        ),
        _actionCard(
          context,
          'Marketplace',
          Icons.storefront_outlined,
          const Color(0xFFEC4899),
          () => Navigator.pushNamed(context, '/marketplace'),
        ),
      ],
    );
  }

  Widget _actionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 2 > 200 ? 180 : (MediaQuery.of(context).size.width - 64) / 2,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed(BuildContext context) {
    // Return empty or fetch real data. Since we don't have real logs stream setup in this view yet, hide.
   return const SizedBox.shrink();
  }

  Widget _buildMarketingSection(BuildContext context) {
    // Hide simulated marketing data
    return const SizedBox.shrink();
  }
}
