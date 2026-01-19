import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final DatabaseService _db = DatabaseService();
  final _promptController = TextEditingController();
  final _openAiController = TextEditingController();
  final _geminiController = TextEditingController();
  final _privacyController = TextEditingController();
  final _termsController = TextEditingController();
  String _activeProvider = 'gemini';
  bool _isSaving = false;

  final _userSearchController = TextEditingController();
  final _notificationTitleController = TextEditingController();
  final _notificationBodyController = TextEditingController();
  String _userSearchQuery = '';
  bool _isMaintenanceMode = false;
  final _appVersionController = TextEditingController(text: '1.0.4');

  // Feature Flags
  bool _flagSosEnabled = true;
  bool _flagAiVisualizerEnabled = true;
  bool _flagRewardsEnabled = true;
  bool _flagPublicMarketplaceEnabled = true;

  final _maintenanceMessageController = TextEditingController();
  bool _allowMaintenanceFeedback = true;

  final _bannerMessageController = TextEditingController();
  final _bannerImageController = TextEditingController();
  final _bannerLinkController = TextEditingController();
  bool _isBannerEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _userSearchController.addListener(() {
      setState(() {
        _userSearchQuery = _userSearchController.text.toLowerCase();
      });
    });
  }

  // ... _loadSettings and _saveSettings remain same ...

  // ... build method remains same ...

  Widget _buildUserManagementTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: TextField(
              controller: _userSearchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                hintStyle: GoogleFonts.inter(color: Theme.of(context).hintColor),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _db.getAllUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final allUsers = snapshot.data!;

              final users = allUsers.where((u) {
                final name = (u['fullName'] ?? '').toString().toLowerCase();
                final email = (u['email'] ?? '').toString().toLowerCase();
                return name.contains(_userSearchQuery) || email.contains(_userSearchQuery);
              }).toList();

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('No users found', style: GoogleFonts.inter(color: Theme.of(context).hintColor)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isBlocked = user['isBlocked'] == true;
                  final role = user['role'] ?? 'user';
                  final isContractor = role == 'contractor';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).cardColor,
                          Theme.of(context).cardColor.withValues(alpha: 0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isBlocked ? AppTheme.error.withValues(alpha: 0.3) : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isContractor ? Colors.orange : AppTheme.primary,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: (isContractor ? Colors.orange : AppTheme.primary).withValues(alpha: 0.1),
                              child: Text(
                                user['fullName']?[0] ?? 'U',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isContractor ? Colors.orange : AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      user['fullName'] ?? 'Unknown User',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isBlocked ? Theme.of(context).hintColor : Theme.of(context).colorScheme.onSurface,
                                        decoration: isBlocked ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    if (isContractor) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.verified, size: 16, color: Colors.orange),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.email_outlined, size: 12, color: Theme.of(context).hintColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      user['email'] ?? 'No email',
                                      style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                                  color: isBlocked ? AppTheme.success : AppTheme.error.withValues(alpha: 0.7),
                                ),
                                tooltip: isBlocked ? 'Unblock User' : 'Block User',
                                onPressed: () async {
                                  await _db.toggleUserBlock(user['id'], !isBlocked);
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isBlocked ? 'User Unblocked' : 'User Blocked')));
                                },
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).hintColor),
                                onSelected: (value) {
                                  if (value == 'edit_role') _showRolePicker(context, user);
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit_role',
                                    child: Row(
                                      children: [
                                        Icon(Icons.admin_panel_settings_outlined, size: 18, color: Theme.of(context).colorScheme.onSurface),
                                        const SizedBox(width: 12),
                                        const Text('Change Role'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadSettings() async {
    final settings = await _db.getAiSettings();
    final privacy = await _db.getLegalText('privacy_policy');
    final terms = await _db.getLegalText('terms_conditions');

    setState(() {
      _promptController.text = settings['system_prompt'] ?? '';
      _openAiController.text = settings['openai_key'] ?? '';
      _geminiController.text = settings['gemini_key'] ?? '';
      _activeProvider = settings['active_provider'] ?? 'gemini';
      _privacyController.text = privacy ?? '';
      _termsController.text = terms ?? '';
    });

    // Load Maintenance Settings
    _db.getMaintenanceSettings().first.then((m) {
      setState(() {
        _isMaintenanceMode = m['isEnabled'] ?? false;
        _maintenanceMessageController.text = m['message'] ?? '';
        _allowMaintenanceFeedback = m['allowFeedback'] ?? true;
      });
    });

    // Load Banner Settings
    _db.getBannerSettings().first.then((b) {
      setState(() {
        _isBannerEnabled = b['isEnabled'] ?? false;
        _bannerMessageController.text = b['message'] ?? '';
        _bannerImageController.text = b['imageUrl'] ?? '';
        _bannerLinkController.text = b['link'] ?? '';
      });
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _db.updateAiSettings({
        'system_prompt': _promptController.text,
        'openai_key': _openAiController.text,
        'gemini_key': _geminiController.text,
        'active_provider': _activeProvider,
      });
      await _db.updateLegalText('privacy_policy', _privacyController.text);
      await _db.updateLegalText('terms_conditions', _termsController.text);

      await _db.updateMaintenanceSettings({
        'isEnabled': _isMaintenanceMode,
        'message': _maintenanceMessageController.text,
        'allowFeedback': _allowMaintenanceFeedback,
      });

      await _db.updateBannerSettings({
        'isEnabled': _isBannerEnabled,
        'message': _bannerMessageController.text,
        'imageUrl': _bannerImageController.text,
        'link': _bannerLinkController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 10,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
              color: Theme.of(context).cardColor,
              child: TabBar(
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).hintColor,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: [
                  Tab(text: 'Verification'),
                  Tab(text: 'Users'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'Support'),
                  Tab(text: 'API Health'),
                  Tab(text: 'AI & Settings'),
                  Tab(text: 'Broadcast'),
                  Tab(text: 'Platform Alerts'),
                  Tab(text: 'Control Center'),
                  Tab(text: 'Logs'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildVerificationTab(),
                  _buildUserManagementTab(),
                  _buildAnalyticsTab(),
                  _buildSupportTab(),
                  _buildApiHealthTab(),
                  _buildSettingsTab(),
                  _buildNotificationsTab(),
                  _buildPlatformAlertsTab(),
                  _buildControlTab(),
                  _buildLogsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getPendingContractors(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final contractors = snapshot.data!;

        if (contractors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'All caught up!',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                Text(
                  'No pending contractor verifications.',
                  style: GoogleFonts.inter(color: Theme.of(context).hintColor),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: contractors.length,
          itemBuilder: (context, index) {
            final c = contractors[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          child: Text(
                            c['name'][0],
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['name'],
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                c['category'] ?? 'General Contractor',
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PENDING',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _detailRow(Icons.email_outlined, c['email'] ?? 'No email'),
                    const SizedBox(height: 8),
                    _detailRow(Icons.phone_outlined, c['phone'] ?? 'No phone'),
                    const SizedBox(height: 8),
                    _detailRow(
                      Icons.location_on_outlined,
                      '${c['city'] ?? ''}, ${c['state'] ?? ''}',
                    ),
                    const SizedBox(height: 8),
                    _detailRow(
                      Icons.business,
                      'License: ${c['licenseNumber'] ?? 'N/A'}',
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _launchEmail(c['email']),
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text('Contact'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _db.verifyContractor(c['id'], true);
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Contractor Verified!'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                          },
                          icon: const Icon(
                            Icons.verified_user_rounded,
                            size: 18,
                          ),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).hintColor),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  void _launchEmail(String? email) async {
    if (email == null) return;
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(),
          const SizedBox(height: 48),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildAiConfigCard(),
          const SizedBox(height: 48),
          _buildSectionTitle('Legal Configuration'),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Privacy Policy (Markdown)',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _privacyController.text = _defaultPrivacyPolicy;
                      },
                      child: const Text(
                        'Generate Default',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _privacyController,
                  maxLines: 6,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Terms & Conditions (Markdown)',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _termsController.text = _defaultTerms;
                      },
                      child: const Text(
                        'Generate Default',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _termsController,
                  maxLines: 6,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildSectionTitle('System Prompt Control'),
          _buildPromptCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Configuration',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              'Global system configuration and metrics',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('Deploy Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).hintColor,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _db.getAdminStats(),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ?? {'total_estimates': '0', 'total_contractors': '0'};
        return Row(
          children: [
            _statTile(
              'Total Estimates',
              stats['total_estimates'].toString(),
              Icons.analytics_outlined,
            ),
            const SizedBox(width: 24),
            _statTile(
              'Verified Contractors',
              stats['total_contractors'].toString(),
              Icons.people_outline_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).hintColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiConfigCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _providerChoice(
                'openai',
                'OpenAI GPT-4o',
                Icons.auto_awesome_rounded,
              ),
              const SizedBox(width: 16),
              _providerChoice('gemini', 'Google Gemini', Icons.bolt_rounded),
            ],
          ),
          const SizedBox(height: 32),
          _buildKeyInput('OpenAI API Key', _openAiController),
          const SizedBox(height: 24),
          _buildKeyInput('Gemini API Key', _geminiController),
        ],
      ),
    );
  }

  Widget _providerChoice(String id, String name, IconData icon) {
    bool selected = _activeProvider == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeProvider = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter API Access Key',
            fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPromptCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: _promptController,
        maxLines: 10,
        style: GoogleFonts.inter(fontSize: 14, height: 1.6),
        decoration: InputDecoration(
          hintText: 'System behavior instructions...',
          fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
        ),
      ),
    );
  }

  final String _defaultPrivacyPolicy = """
# Privacy Policy

**Effective Date:** January 1, 2026

**1. Introduction**
Welcome to RAP US ("we," "our," or "us"). We are committed to protecting your personal information and your right to privacy.

**2. Information We Collect**
- **Personal Information:** Name, email address, phone number, and address provided during registration.
- **Usage Data:** Information on how you interact with our app.
- **Images:** Photos uploaded for estimation or visualization purposes.

**3. How We Use Your Information**
We use your information to:
- Provide and manage your account.
- Process your requests and orders.
- Improve our services and user experience.

**4. Sharing Your Information**
We do not sell your personal information. We may share information with verified contractors solely for the purpose of fulfilling your service requests.

**5. Contact Us**
If you have questions about this policy, please contact us at support@rap.com.
""";

  final String _defaultTerms = """
# Terms and Conditions

**Effective Date:** January 1, 2026

**1. Acceptance of Terms**
By accessing and using RAP US, you accept and agree to be bound by the terms and provision of this agreement.

**2. Use of Service**
You agree to use our service for lawful purposes only. You are prohibited from posting or transmitting any unlawful, threatening, libelous, defamatory, obscene, or profane material.

**3. Accounts**
When you create an account with us, you must provide us information that is accurate, complete, and current at all times. Failure to do so constitutes a breach of the Terms.

**4. Intellectual Property**
The Service and its original content, features, and functionality are and will remain the exclusive property of RAP US and its licensors.

**5. Termination**
We may terminate or suspend access to our Service immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.
""";
  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Global Announcement'),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Push Notification',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will send a notification to ALL registered users.',
                  style: GoogleFonts.inter(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _notificationTitleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notificationBodyController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Message Body',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_notificationTitleController.text.isEmpty ||
                          _notificationBodyController.text.isEmpty)
                        return;
                      // Mock send
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification Dispatched!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                      _notificationTitleController.clear();
                      _notificationBodyController.clear();
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Broadcast Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRolePicker(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Assign Role'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              _db.updateUserProfile(user['id'], {'role': 'user'});
              Navigator.pop(ctx);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('User'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              _db.updateUserProfile(user['id'], {'role': 'contractor'});
              Navigator.pop(ctx);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Contractor'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              _db.updateUserProfile(user['id'], {'role': 'admin'});
              Navigator.pop(ctx);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Administrator'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Growth Metrics'),
          Row(
            children: [
              _miniStat(
                'Monthly Rev',
                '\$0.00',
                Icons.trending_up,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _miniStat('New Users', '0', Icons.person_add, Colors.blue),
              const SizedBox(width: 16),
              _miniStat('AI Tokens', '0', Icons.auto_awesome, Colors.orange),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Revenue Overview'),
          Container(
            height: 250,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _bar(0.1, 'Jan'),
                _bar(0.1, 'Feb'),
                _bar(0.1, 'Mar'),
                _bar(0.1, 'Apr'),
                _bar(0.1, 'May'),
                _bar(0.1, 'Jun'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Top Performing Regions'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No regional data available.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(
              val,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(double height, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 150 * height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _regionTile(String name, int count) {
    return ListTile(
      title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$count Projects',
          style: TextStyle(
            color: AppTheme.accent,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildControlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Feature Flags'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                _flagTile(
                  'Emergency SOS System',
                  'Enable/Disable the global SOS button',
                  _flagSosEnabled,
                  (v) => setState(() => _flagSosEnabled = v),
                ),
                const Divider(height: 1),
                _flagTile(
                  'AI Room Visualizer',
                  'Toggle access to the AI redesign feature',
                  _flagAiVisualizerEnabled,
                  (v) => setState(() => _flagAiVisualizerEnabled = v),
                ),
                const Divider(height: 1),
                _flagTile(
                  'Referrals & Rewards',
                  'Enable loyalty points and referral tracking',
                  _flagRewardsEnabled,
                  (v) => setState(() => _flagRewardsEnabled = v),
                ),
                const Divider(height: 1),
                _flagTile(
                  'Public Marketplace',
                  'Allow unverified users to browse contractors',
                  _flagPublicMarketplaceEnabled,
                  (v) => setState(() => _flagPublicMarketplaceEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Platform Health'),
          Row(
            children: [
              Expanded(
                child: _buildHealthCard(
                  'Server Status',
                  'OPTIMAL',
                  Icons.dns_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHealthCard(
                  'Database',
                  'HEALTHY',
                  Icons.storage_rounded,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Platform Control'),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                const Divider(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _appVersionController,
                        decoration: const InputDecoration(
                          labelText: 'Force Update Version',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Update Version'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Database Management'),
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  'Flush Cache',
                  Icons.cached_rounded,
                  Colors.orange,
                  () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _actionCard(
                  'Backup Now',
                  Icons.cloud_upload_rounded,
                  Colors.blue,
                  () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _actionCard(
                  'Clean Logs',
                  Icons.delete_outline_rounded,
                  Colors.red,
                  () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _flagTile(
    String title,
    String subtitle,
    bool val,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12)),
      value: val,
      onChanged: onChanged,
    );
  }

  Widget _actionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(
    String title,
    String status,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 16),
          Text(
            status,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('AI Infrastructure Logs'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No infrastructure logs captured.',
                  style: GoogleFonts.inter(color: Theme.of(context).hintColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Security & Audit Trial'),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Audit trial is currently empty.',
                  style: GoogleFonts.inter(color: Theme.of(context).hintColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _auditRow(String title, String actor, String action, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_toggle_off, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$actor: $action',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Active Support Queue'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No active support tickets.',
                  style: GoogleFonts.inter(color: Theme.of(context).hintColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Color _getStatusColor(String status) {
    switch (status) {
      case 'URGENT':
        return Colors.red;
      case 'OPEN':
        return Colors.blue;
      case 'RESOLVED':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Widget _buildApiHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('API Response Latency (ms)'),
          Container(
            height: 200,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(12, (i) => _latencyBar(0.1)),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Provider Status'),
          Row(
            children: [
              _providerStatus('GPT-4o', 'Awaiting Sync', Colors.grey),
              const SizedBox(width: 16),
              _providerStatus('Gemini 1.5', 'Awaiting Sync', Colors.grey),
              const SizedBox(width: 16),
              _providerStatus('Claude 3.5', 'Awaiting Sync', Colors.grey),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Token Efficiency'),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                _efficiencyRow('Prompt Compression', '0%', Colors.grey),
                const Divider(height: 32),
                _efficiencyRow('Cache Hit Rate', '0%', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Maintenance Mode'),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Enable Maintenance Mode',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Prevents users from accessing the app during updates.',
                  ),
                  value: _isMaintenanceMode,
                  activeColor: AppTheme.error,
                  onChanged: (v) => setState(() => _isMaintenanceMode = v),
                ),
                const Divider(height: 32),
                TextField(
                  controller: _maintenanceMessageController,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance Message',
                    hintText: 'e.g. We are performing server maintenance...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Allow Feedback during Maintenance'),
                  value: _allowMaintenanceFeedback,
                  onChanged: (v) =>
                      setState(() => _allowMaintenanceFeedback = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Global Image Banner'),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Enable Banner',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  value: _isBannerEnabled,
                  onChanged: (v) => setState(() => _isBannerEnabled = v),
                ),
                const Divider(height: 32),
                TextField(
                  controller: _bannerMessageController,
                  decoration: const InputDecoration(
                    labelText: 'Banner Text',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bannerImageController,
                  decoration: const InputDecoration(
                    labelText: 'Banner Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bannerLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Redirection Link',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Platform Configuration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 48),
          _buildSectionTitle('Maintenance Feedback'),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _db.getMaintenanceFeedback(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final feedback = snapshot.data!;
              if (feedback.isEmpty)
                return Center(
                  child: Text(
                    'No feedback received.',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                );

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: feedback.length,
                itemBuilder: (context, index) {
                  final f = feedback[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(f['message'] ?? 'No message'),
                      subtitle: Text(
                        '${f['email'] ?? 'Anonymous'} • ${f['timestamp'] != null ? (f['timestamp'] as dynamic).toDate().toString() : 'Just now'}',
                      ),
                      leading: const Icon(
                        Icons.feedback_rounded,
                        color: Colors.orange,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _latencyBar(double h) {
    return Container(
      width: 12,
      height: 150 * h,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _providerStatus(String name, String status, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            Text(status, style: GoogleFonts.inter(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _efficiencyRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
