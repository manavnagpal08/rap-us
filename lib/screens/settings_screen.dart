import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.settings, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSectionTitle(context, 'Profile'),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          user?.email ?? 'No email linked',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _showEditProfileDialog(context, user),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Preferences
            _buildSectionTitle(context, l10n.preferences),
            _buildSettingsGroup(context, [
              _buildSettingTile(
                context,
                icon: Icons.notifications_none_rounded,
                title: l10n.notifications,
                subtitle: 'Enable push alerts for new estimates',
                trailing: Switch.adaptive(
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              _buildSettingTile(
                context,
                icon: Icons.dark_mode_outlined,
                title: l10n.darkMode,
                subtitle: 'Switch to a darker visual style',
                trailing: Switch.adaptive(
                  value: AppTheme.themeModeNotifier.value == ThemeMode.dark,
                  onChanged: (v) {
                    setState(() {
                      AppTheme.themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              _buildSettingTile(
                context,
                icon: Icons.payments_outlined,
                title: l10n.activeCurrency,
                subtitle: 'Select your preferred currency',
                trailing: DropdownButton<String>(
                  value: _currency,
                  dropdownColor: Theme.of(context).cardColor,
                  underline: const SizedBox(),
                  onChanged: (v) {
                    setState(() {
                      _currency = v!;
                      switch (v) {
                        case 'EUR':
                          AppTheme.currencySymbolNotifier.value = '€';
                          break;
                        case 'GBP':
                          AppTheme.currencySymbolNotifier.value = '£';
                          break;
                        case 'INR':
                          AppTheme.currencySymbolNotifier.value = '₹';
                          break;
                        default:
                          AppTheme.currencySymbolNotifier.value = '\$';
                      }
                    });
                  },
                  items: ['USD', 'EUR', 'GBP', 'INR']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: Theme.of(context).colorScheme.onSurface))))
                      .toList(),
                ),
              ),
              _buildSettingTile(
                context,
                icon: Icons.language_rounded,
                title: l10n.language,
                subtitle: 'Change app language',
                trailing: DropdownButton<String>(
                  value: AppTheme.localeNotifier.value.languageCode,
                  dropdownColor: Theme.of(context).cardColor,
                  underline: const SizedBox(),
                  onChanged: (v) {
                    if (v != null) {
                      AppTheme.localeNotifier.value = Locale(v);
                      setState(() {});
                    }
                  },
                  items: [
                    {'code': 'en', 'name': 'English'},
                    {'code': 'es', 'name': 'Español'},
                    {'code': 'fr', 'name': 'Français'},
                    {'code': 'de', 'name': 'Deutsch'},
                    {'code': 'it', 'name': 'Italiano'},
                    {'code': 'pt', 'name': 'Português'},
                    {'code': 'hi', 'name': 'हिन्दी'},
                  ].map((e) => DropdownMenuItem(value: e['code'], child: Text(e['name']!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)))).toList(),
                ),
              ),
            ]),
            
            const SizedBox(height: 32),
            
            // Account
            _buildSectionTitle(context, l10n.account),
            _buildSettingsGroup(context, [
              _buildSettingTile(
                context,
                icon: Icons.security_rounded,
                title: l10n.security,
                subtitle: 'Password, Biometrics & 2FA',
                onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecurityScreen()));
                },
              ),
              _buildSettingTile(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Support',
                subtitle: 'Help center & documentation',
                onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen()));
                },
              ),
              _buildSettingTile(
                context,
                icon: Icons.info_outline_rounded,
                title: l10n.aboutRap,
                subtitle: 'Version 1.0.0 (Build 5)',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AboutDialog(
                      applicationName: l10n.appTitle,
                      applicationVersion: '1.0.0',
                      applicationIcon: Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary),
                      children: [Text(l10n.aboutDescription)],
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
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.error,
                  elevation: 0,
                  side: BorderSide(color: AppTheme.error.withValues(alpha: 0.2)),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: Theme.of(context).hintColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
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
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Theme.of(context).hintColor,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: Theme.of(context).dividerColor),
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
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
