import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/theme/app_theme.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final AuthService _auth = AuthService();
  bool _biometricsEnabled = false;
  bool _twoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Security', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSecurityOption(
              icon: Icons.lock_reset_rounded,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: () => _showAiGuidance(
                title: 'Password Update',
                explanation: 'Regular password updates protect against unauthorized access. I will send a secure reset link to your email.',
                actionLabel: 'Send Link',
                onConfirm: _sendPasswordReset,
              ),
            ),
            const SizedBox(height: 16),
            _buildSecurityOption(
              icon: Icons.fingerprint_rounded,
              title: 'Biometrics',
              subtitle: 'Use FaceID or Fingerprint',
              trailing: Switch.adaptive(
                value: _biometricsEnabled,
                onChanged: (val) => _showAiGuidance(
                  title: val ? 'Enable Biometrics' : 'Disable Biometrics',
                  explanation: val 
                      ? 'Biometrics allow for faster, secure access using your unique physical traits. This data stays on your device.'
                      : 'Disabling biometrics employs standard password entry. Your biometric data remains on your device but won\'t unlock this app.',
                  actionLabel: val ? 'Enable' : 'Disable',
                  onConfirm: () => setState(() => _biometricsEnabled = val),
                ),
                activeColor: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 16),
            _buildSecurityOption(
              icon: Icons.security_rounded,
              title: 'Two-Factor Authentication',
              subtitle: 'Add an extra layer of security',
              trailing: Switch.adaptive(
                value: _twoFactorEnabled,
                onChanged: (val) => _showAiGuidance(
                  title: val ? 'Enable 2FA' : 'Disable 2FA',
                  explanation: val
                      ? 'Two-Factor Authentication (2FA) requires a code from your phone in addition to your password. This significantly reduces the risk of account theft.'
                      : 'Disabling 2FA removes the extra verification step. This makes logging in faster but less secure.',
                  actionLabel: val ? 'Setup 2FA' : 'Turn Off',
                  onConfirm: () => setState(() => _twoFactorEnabled = val),
                ),
                activeColor: AppTheme.accent,
              ),
            ),
          ].animate(interval: 100.ms).fadeIn().slideX(begin: 0.1, end: 0),
        ),
      ),
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24).animate(target: onTap != null ? 1 : 0).scale(duration: 200.ms),
        ),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
      ),
    );
  }

  void _showAiGuidance({
    required String title,
    required String explanation,
    required String actionLabel,
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Security Assistant', style: GoogleFonts.inter(color: AppTheme.accent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(explanation, style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF475569), height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(actionLabel, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      try {
        await _auth.sendPasswordResetEmail(user.email!);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Reset link sent to ${user.email}'), 
               backgroundColor: AppTheme.success,
             ),
           );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }
}
