import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/security_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  final SecurityService _security = SecurityService();
  bool _biometricsEnabled = false;
  bool _twoFactorEnabled = false;


  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final user = _auth.currentUser;
    if (user != null) {
      final profile = await _db.getUserProfile(user.uid);
      if (profile != null) {
        if (mounted) {
          setState(() {
            _twoFactorEnabled = profile['is2FAEnabled'] ?? false;
            // Biometrics is usually local-only preference, we can store it too or just leave it
          });
        }
      }
    }
  }

  Future<void> _toggleBiometrics(bool val) async {
    if (val) {
      final authenticated = await _security.authenticateBiometrics();
      if (authenticated) {
        setState(() => _biometricsEnabled = true);
        await _db.updateUserProfile(_auth.currentUser!.uid, {'biometricsEnabled': true});
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometrics enabled!'), backgroundColor: AppTheme.success));
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication failed. Biometrics not enabled.'), backgroundColor: AppTheme.error));
        }
      }
    } else {
      setState(() => _biometricsEnabled = false);
      await _db.updateUserProfile(_auth.currentUser!.uid, {'biometricsEnabled': false});
       if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometrics disabled.'), backgroundColor: Colors.grey));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.security, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSecurityOption(
              icon: Icons.lock_reset_rounded,
              title: l10n.changePassword,
              subtitle: l10n.changePasswordSubtitle,
              onTap: () => _showAiGuidance(
                title: l10n.passwordUpdate,
                explanation: l10n.passwordUpdateExplanation,
                actionLabel: l10n.sendLink,
                onConfirm: _sendPasswordReset,
              ),
            ),
            const SizedBox(height: 16),
            _buildSecurityOption(
              icon: Icons.fingerprint_rounded,
              title: l10n.biometrics,
              subtitle: l10n.biometricsSubtitle,
              onTap: () => _toggleBiometrics(!_biometricsEnabled),
              trailing: Switch.adaptive(
                value: _biometricsEnabled,
                onChanged: _toggleBiometrics,
                activeColor: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 16),
            _buildSecurityOption(
              icon: Icons.security_rounded,
              title: l10n.twoFactor,
              subtitle: l10n.twoFactorSubtitle,
              trailing: Switch.adaptive(
                value: _twoFactorEnabled,
                onChanged: (val) {
                  if (val) {
                    _show2FASetup();
                  } else {
                    _showAiGuidance(
                      title: l10n.disable2FA,
                      explanation: l10n.twoFactorDisableExplanation,
                      actionLabel: l10n.turnOff,
                      onConfirm: () async {
                        setState(() => _twoFactorEnabled = false);
                        await _db.updateUserProfile(_auth.currentUser!.uid, {'is2FAEnabled': false, 'totpSecret': null});
                      },
                    );
                  }
                },
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24).animate(target: onTap != null ? 1 : 0).scale(duration: 200.ms),
        ),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 13)),
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: Theme.of(context).hintColor),
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
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.securityAssistant, style: GoogleFonts.inter(color: AppTheme.accent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 12),
            Text(explanation, style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5)),
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(actionLabel, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel, style: GoogleFonts.inter(color: Theme.of(context).hintColor)),
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
               content: Text('${AppLocalizations.of(context)!.resetLinkSent} ${user.email}'), 
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

  Future<void> _show2FASetup() async {
    final secret = _security.generateTotpSecret();
    final user = _auth.currentUser;
    final uri = _security.getTotpUri(secret, user?.email ?? 'user');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Setup 2-Step Verification', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Scan this QR code with your authenticator app (Google Authenticator, Authy, etc.) to enable 2FA.', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(
                data: uri,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 24),
            Text('Secret Key: $secret', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.accent)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  await _db.updateUserProfile(_auth.currentUser!.uid, {
                    'is2FAEnabled': true,
                    'totpSecret': secret,
                  });
                  setState(() => _twoFactorEnabled = true);
                  if (!context.mounted) return;
                  if (mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('2FA Enabled Successfully!'), backgroundColor: AppTheme.success),
                    );
                  }
                },
                child: const Text('I have scanned the code'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}
