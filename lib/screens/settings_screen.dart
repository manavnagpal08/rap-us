import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/screens/security_screen.dart';
import 'package:rap_app/screens/support_screen.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/widgets/premium_background.dart';

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
  
  // Profile State
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final profile = await _db.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
    );
    
    if (image != null && _auth.currentUser != null) {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      
      setState(() => _isLoading = true);
      try {
        await _db.updateUserProfile(_auth.currentUser!.uid, {'photoBase64': base64String});
        await _loadProfile(); // Refresh
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!'), backgroundColor: AppTheme.success));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update image: $e'), backgroundColor: AppTheme.error));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    
    // Fallback values
    final displayName = user?.displayName ?? _userProfile?['fullName'] ?? 'Guest User';
    final email = user?.email ?? _userProfile?['email'] ?? 'No email linked';
    final photoBase64 = _userProfile?['photoBase64'];
    final referralCode = _userProfile?['referralCode'] ?? 'NOT GENERATED';
    final loyaltyPoints = _userProfile?['loyaltyPoints'] ?? 0;
    
    // Auto-generate code if missing
    if (_userProfile != null && _userProfile!['referralCode'] == null && user != null && !_isLoading) {
      _db.generateReferralCode(user.uid).then((_) => _loadProfile());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const PremiumBackground(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                title: Text(l10n.settings, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                centerTitle: true,
                floating: true,
                elevation: 0,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    
                    // --- Profile Card ---
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.glassDecoration(color: Theme.of(context).cardColor.withOpacity(0.85)),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _updateProfileImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.accent, width: 3),
                                    boxShadow: [
                                      BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                    backgroundImage: photoBase64 != null 
                                      ? MemoryImage(base64Decode(photoBase64))
                                      : null,
                                    child: photoBase64 == null 
                                      ? Text(
                                          displayName.substring(0, 1).toUpperCase(),
                                          style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.accent),
                                        ) 
                                      : null,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: GestureDetector(
                                  onTap: _updateProfileImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                          const SizedBox(height: 16),
                          Text(
                            displayName,
                            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                          Text(
                            email,
                            style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).hintColor),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _showEditProfileDialog(context, user),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit Profile'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // --- Preferences ---
                    _buildSectionHeader(context, l10n.preferences).animate().fadeIn(delay: 500.ms),
                    _buildSettingsGroup(context, [
                      _buildSettingTile(
                        context,
                        icon: Icons.notifications_none_rounded,
                        title: l10n.notifications,
                        subtitle: 'Enable push alerts for new projects',
                        trailing: Switch.adaptive(
                          value: _notificationsEnabled,
                          onChanged: (v) => setState(() => _notificationsEnabled = v),
                          activeColor: AppTheme.accent,
                        ),
                      ),
                      _buildSettingTile(
                        context,
                        icon: Icons.dark_mode_outlined,
                        title: l10n.darkMode,
                        subtitle: 'Switch to immersive dark mode',
                        trailing: ValueListenableBuilder<ThemeMode>(
                          valueListenable: AppTheme.themeModeNotifier,
                          builder: (context, mode, _) => Switch.adaptive(
                            value: mode == ThemeMode.dark,
                            onChanged: (v) => AppTheme.themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light,
                            activeColor: AppTheme.accent,
                          ),
                        ),
                      ),
                      _buildSettingTile(
                        context,
                        icon: Icons.language_rounded,
                        title: l10n.language,
                        subtitle: 'Change interface language',
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: AppTheme.localeNotifier.value.languageCode,
                            dropdownColor: Theme.of(context).cardColor,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                            onChanged: (v) {
                              if (v != null) setState(() => AppTheme.localeNotifier.value = Locale(v));
                            },
                            items: [
                              {'code': 'en', 'name': 'English'},
                              {'code': 'es', 'name': 'Español'},
                              {'code': 'hi', 'name': 'हिन्दी'},
                              {'code': 'fr', 'name': 'Français'},
                              {'code': 'de', 'name': 'Deutsch'},
                            ].map((e) => DropdownMenuItem(value: e['code'], child: Text(e['name']!))).toList(),
                          ),
                        ),
                      ),
                    ]).animate().fadeIn(delay: 600.ms).slideX(),
                    
                    const SizedBox(height: 32),
                    
                    // --- Rewards & Points ---
                    _buildSectionHeader(context, 'Rewards').animate().fadeIn(delay: 700.ms),
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showRedemptionDialog(context, loyaltyPoints, user?.uid ?? ''),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                  child: const Icon(Icons.stars_rounded, color: Colors.white, size: 32),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$loyaltyPoints Points', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                      Text('Redeem for discounts & gifts', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 800.ms).scale(),

                    _buildSettingsGroup(context, [
                      _buildSettingTile(
                        context,
                        icon: Icons.share_rounded,
                        title: 'Refer & Earn',
                        subtitle: 'Your Code: $referralCode',
                        onTap: () {
                           // ignore: deprecated_member_use
                           Share.share('Use my RAP code $referralCode for a discount on your next project!');
                        },
                      ),
                      _buildSettingTile(
                        context,
                        icon: Icons.card_giftcard_rounded,
                        title: 'Enter Invite Code',
                        subtitle: 'Got a code from a friend?',
                        onTap: () => _showReferralInputDialog(context),
                      ),
                    ]).animate().fadeIn(delay: 900.ms).slideX(),
                    
                    const SizedBox(height: 32),
                    
                    // --- Account ---
                    _buildSectionHeader(context, l10n.account).animate().fadeIn(delay: 1000.ms),
                    _buildSettingsGroup(context, [
                      _buildSettingTile(
                        context,
                        icon: Icons.security_rounded,
                        title: l10n.security,
                        subtitle: '2FA, Password & Biometrics',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecurityScreen())),
                      ),
                      _buildSettingTile(
                        context,
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        subtitle: 'FAQs and Customer Service',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
                      ),
                      _buildSettingTile(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: l10n.aboutRap,
                        subtitle: 'v1.0.0 (Pro Edition)',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AboutDialog(
                              applicationName: l10n.appTitle,
                              applicationVersion: '1.0.0',
                              applicationIcon: Icon(Icons.auto_awesome_rounded, color: AppTheme.accent, size: 40),
                              children: [Text(l10n.aboutDescription, style: GoogleFonts.inter())],
                            ),
                          );
                        },
                      ),
                    ]).animate().fadeIn(delay: 1100.ms).slideX(),
                    
                    const SizedBox(height: 48),

                    // --- Sign Out & Danger ---
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _auth.signOut();
                          if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor,
                          foregroundColor: Theme.of(context).colorScheme.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: Theme.of(context).colorScheme.error.withOpacity(0.2)),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1200.ms),
                    
                    const SizedBox(height: 16),
                    
                    Center(
                      child: TextButton(
                        onPressed: _showDeleteAccountDialog,
                        child: Text(
                          'Delete Account',
                          style: GoogleFonts.inter(color: Colors.red.withOpacity(0.6), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1300.ms),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Theme.of(context).hintColor.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: AppTheme.glassDecoration(color: Theme.of(context).cardColor.withOpacity(0.6)),
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
    // Add divider unless last item logic if needed, but simple list is fine
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).hintColor)),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing
              else Icon(Icons.chevron_right_rounded, color: Theme.of(context).dividerColor.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, user) {
    if (user == null) return;
    final nameController = TextEditingController(text: user.displayName ?? _userProfile?['fullName']);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                await user.updateDisplayName(nameController.text.trim());
                await _db.updateUserProfile(user.uid, {'fullName': nameController.text.trim()});
                await _loadProfile();
              } finally {
                setState(() => _isLoading = false);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReferralInputDialog(BuildContext context) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Enter Invite Code'),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Code',
            hintText: 'RAP-XXXX',
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await _db.applyReferral(codeController.text.trim().toUpperCase());
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success ? 'Code applied! Points added.' : 'Invalid or expired code.'),
                    backgroundColor: success ? AppTheme.success : AppTheme.error,
                 ));
                 if (success) _loadProfile();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showRedemptionDialog(BuildContext context, int currentPoints, String uid) {
    final rewards = [
      {'name': '\$5 Amazon Gift Card', 'points': 500, 'type': 'amazon', 'icon': Icons.card_giftcard},
      {'name': '10% Service Discount', 'points': 800, 'type': 'service_discount', 'icon': Icons.local_offer},
      {'name': '\$20 RAP Credit', 'points': 1500, 'type': 'credit', 'icon': Icons.account_balance_wallet},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.stars_rounded, color: AppTheme.accent, size: 32),
                const SizedBox(width: 12),
                Text('Redeem Rewards', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            Text('You have $currentPoints points available.', style: GoogleFonts.inter(color: Theme.of(context).hintColor)),
            const SizedBox(height: 24),
            ...rewards.map((r) {
              final cost = r['points'] as int;
              final canAfford = currentPoints >= cost;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: canAfford ? AppTheme.accent.withOpacity(0.3) : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(r['icon'] as IconData, color: AppTheme.accent),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          Text('$cost Points', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: canAfford ? () async {
                         Navigator.pop(ctx);
                         final result = await _db.redeemPoints(uid, cost, r['type'] as String);
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                             content: Text(result['message']),
                             backgroundColor: result['success'] ? AppTheme.success : AppTheme.error,
                           ));
                           if (result['success']) _loadProfile();
                         }
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Theme.of(context).dividerColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Get'),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone and all data will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
             onPressed: () async {
               // Implement delete logic here if backend supports it
               // For now just sign out
               Navigator.pop(ctx);
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please contact support to delete your account permanently.')));
             }, 
             style: TextButton.styleFrom(foregroundColor: Colors.red),
             child: const Text('Delete')
          ),
        ],
      ),
    );
  }
}

