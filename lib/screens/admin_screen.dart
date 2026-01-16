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
  String _activeProvider = 'gemini';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _db.getAiSettings();
    setState(() {
      _promptController.text = settings['system_prompt'] ?? '';
      _openAiController.text = settings['openai_key'] ?? '';
      _geminiController.text = settings['gemini_key'] ?? '';
      _activeProvider = settings['active_provider'] ?? 'gemini';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: AppTheme.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
                tabs: const [
                  Tab(text: 'Contractor Verification'),
                  Tab(text: 'System Settings'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildVerificationTab(),
                  _buildSettingsTab(),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final contractors = snapshot.data!;
        
        if (contractors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 64, color: Theme.of(context).hintColor),
                const SizedBox(height: 16),
                Text('All caught up!', style: GoogleFonts.outfit(fontSize: 18, color: Theme.of(context).hintColor)),
                const Text('No pending verification requests.'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: contractors.length,
          itemBuilder: (context, index) {
            final contractor = contractors[index];
            final docs = contractor['verificationDocs'] as Map<String, dynamic>?;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(child: Text(contractor['name']?[0] ?? 'C')),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contractor['name'] ?? 'Unknown', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(contractor['category'] ?? 'General contractor', style: GoogleFonts.inter(color: Theme.of(context).hintColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    if (docs != null && docs.containsKey('insuranceUrl')) ...[
                      Text('Insurance Policy', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.error),
                        title: Text(docs['fileName'] ?? 'insurance_doc.pdf'),
                        trailing: ElevatedButton(
                          onPressed: () => launchUrl(Uri.parse(docs['insuranceUrl'])),
                          child: const Text('View Doc'),
                        ),
                        tileColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _db.verifyContractor(contractor['id'], false),
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _db.verifyContractor(contractor['id'], true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                            child: const Text('Approve & Verify'),
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
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            Text('Global system configuration and metrics', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
          ],
        ),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('Deploy Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _db.getAdminStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total_estimates': '0', 'total_contractors': '0'};
        return Row(
          children: [
            _statTile('Total Estimates', stats['total_estimates'].toString(), Icons.analytics_outlined),
            const SizedBox(width: 24),
            _statTile('Verified Contractors', stats['total_contractors'].toString(), Icons.people_outline_rounded),
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
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                Text(label, style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 13, fontWeight: FontWeight.w500)),
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
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _providerChoice('openai', 'OpenAI GPT-4o', Icons.auto_awesome_rounded),
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
            color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: selected ? Colors.white : Theme.of(context).colorScheme.primary)),
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
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter API Access Key',
            fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _promptController,
        maxLines: 10,
        style: GoogleFonts.inter(fontSize: 14, height: 1.6),
        decoration: InputDecoration(
          hintText: 'System behavior instructions...',
          fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
        ),
      ),
    );
  }
}
