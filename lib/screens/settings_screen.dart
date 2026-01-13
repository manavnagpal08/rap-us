import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/screens/security_screen.dart';
import 'package:rap_app/screens/support_screen.dart';
import 'package:rap_app/services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  bool _notificationsEnabled = true;

  String _currency = 'USD';

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSectionTitle('Profile'),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Guest User',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          user?.email ?? 'No email linked',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _showEditProfileDialog(context, user),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Preferences
            _buildSectionTitle('Preferences'),
            _buildSettingsGroup([
              _buildSettingTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Enable push alerts for new estimates',
                trailing: Switch.adaptive(
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                  activeColor: AppTheme.accent,
                ),
              ),
              _buildSettingTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch to a darker visual style',
                trailing: Switch.adaptive(
                  value: AppTheme.themeModeNotifier.value == ThemeMode.dark,
                  onChanged: (v) {
                    setState(() {
                      AppTheme.themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                    });
                  },
                  activeColor: AppTheme.accent,
                ),
              ),
              _buildSettingTile(
                icon: Icons.payments_outlined,
                title: 'Currency',
                subtitle: 'Select your preferred currency',
                trailing: DropdownButton<String>(
                  value: _currency,
                  underline: const SizedBox(),
                  onChanged: (v) => setState(() => _currency = v!),
                  items: ['USD', 'EUR', 'GBP', 'INR']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ),
            ]),
            
            const SizedBox(height: 32),
            
            // Account
            _buildSectionTitle('Account'),
            _buildSettingsGroup([
              _buildSettingTile(
                icon: Icons.security_rounded,
                title: 'Security',
                subtitle: 'Password, Biometrics & 2FA',
                onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecurityScreen()));
                },
              ),
              _buildSettingTile(
                icon: Icons.help_outline_rounded,
                title: 'Support',
                subtitle: 'Help center & documentation',
                onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen()));
                },
              ),
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: 'About RAP',
                subtitle: 'Version 1.0.0 (Build 5)',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AboutDialog(
                      applicationName: 'RAP Precision',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent),
                      children: const [Text('RAP is the new standard for AI-powered repairs and estimations.')],
                    ),
                  );
                },
              ),
            ]),
            
            const SizedBox(height: 40),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  await _auth.signOut();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFFEE2E2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded),
                    const SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF334155), size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF64748B),
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
    );
  }

  void _showEditProfileDialog(BuildContext context, user) {
    if (user == null) return;
    final nameController = TextEditingController(text: user.displayName);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await user.updateDisplayName(nameController.text.trim());
              await _db.updateUserProfile(user.uid, {'fullName': nameController.text.trim()});
              if (mounted) setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
