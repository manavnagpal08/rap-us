import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/l10n/app_localizations.dart';

class VerificationCenterScreen extends StatefulWidget {
  const VerificationCenterScreen({super.key});

  @override
  State<VerificationCenterScreen> createState() => _VerificationCenterScreenState();
}

class _VerificationCenterScreenState extends State<VerificationCenterScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      // In a real app, this would be a specific document in a 'verifications' collection
      final profile = await _db.getUserProfile(uid);
      if (mounted) {
        setState(() {
          _verificationStatus = profile?['verificationdata'] ?? {};
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Verification Center', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrustScore(),
            const SizedBox(height: 32),
            Text('Required Credentials', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 16),
            _buildCredentialItem(
              title: 'Identity Verification',
              subtitle: 'Upload a government-issued ID',
              icon: Icons.person_outline_rounded,
              key: 'identity',
            ),
            _buildCredentialItem(
              title: 'Professional License',
              subtitle: 'State contractor license',
              icon: Icons.badge_outlined,
              key: 'license',
            ),
            _buildCredentialItem(
              title: 'Insurance Certificate',
              subtitle: 'General Liability Insurance',
              icon: Icons.shield_outlined,
              key: 'insurance',
            ),
             const SizedBox(height: 32),
            Text('Earned Badges', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 16),
             Wrap(
               spacing: 16,
               runSpacing: 16,
               children: [
                 _buildBadge('Background Checked', Icons.verified_user, true),
                 _buildBadge('Top Rated', Icons.star, _getScore() > 80),
                 _buildBadge('Eco-Friendly', Icons.eco, false), // Example
                 _buildBadge('Quick Responder', Icons.timer, false),
               ],
             )
          ],
        ),
      ),
    );
  }

  int _getScore() {
    // Mock logic
    int score = 20; // Base
    if (_verificationStatus?['identity_verified'] == true) score += 30;
    if (_verificationStatus?['license_verified'] == true) score += 30;
    if (_verificationStatus?['insurance_verified'] == true) score += 20;
    return score;

  }

  Widget _buildTrustScore() {
    int score = _getScore();
    Color color = score > 70 ? AppTheme.success : (score > 40 ? AppTheme.warning : AppTheme.error);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), Theme.of(context).cardColor]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
               SizedBox(
                 width: 80, height: 80, 
                 child: CircularProgressIndicator(value: score / 100, strokeWidth: 8, color: color, backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1))
               ),
               Text('$score%', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trust Score', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Complete verifications to boost your score and get 3x more leads.', style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCredentialItem({required String title, required String subtitle, required IconData icon, required String key}) {
    // Check status in map (mock keys: identity_status, etc.)
    String status = _verificationStatus?['${key}_status'] ?? 'pending'; // pending, verified, rejected
    bool isUploaded = status != 'pending';
    bool isVerified = status == 'verified';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isVerified ? AppTheme.success.withValues(alpha: 0.3) : Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (isVerified ? AppTheme.success : AppTheme.primary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(isVerified ? Icons.check_circle : icon, color: isVerified ? AppTheme.success : AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(isVerified ? 'Verified' : (status == 'submitted' ? 'Under Review' : subtitle), 
                  style: GoogleFonts.inter(fontSize: 12, color: isVerified ? AppTheme.success : Theme.of(context).hintColor)
                ),
              ],
            ),
          ),
          if (!isVerified && status != 'submitted')
          ElevatedButton(
            onPressed: () => _uploadDoc(key),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              elevation: 0,
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: const Text('Upload'),
          )
        ],
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon, bool earned) {
    return Opacity(
      opacity: earned ? 1.0 : 0.4,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: earned ? const Color(0xFFFFD700).withValues(alpha: 0.1) : Theme.of(context).dividerColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: earned ? const Color(0xFFFFD700) : Colors.transparent),
        ),
        child: Column(
          children: [
            Icon(icon, color: earned ? const Color(0xFFFFD700) : Theme.of(context).hintColor, size: 32),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDoc(String key) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading document...')));
      }
      // Mock Upload
      File file = File(result.files.single.path!);
      String fileName = 'verification/${_auth.currentUser!.uid}/$key.${file.path.split('.').last}';
      String? url = await _db.uploadFile(fileName, file);

      if (url != null) {
         await _db.updateUserProfile(_auth.currentUser!.uid, {
           'verificationdata.${key}_status': 'submitted',
           'verificationdata.${key}_url': url,
           'verificationdata.updated_at': DateTime.now().toIso8601String(),
         });
         await _loadStatus();
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document submitted for review!')));
         }
      }
    }
  }
}
