import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/screens/home_screen.dart';
import 'package:rap_app/screens/history_screen.dart';
import 'package:rap_app/screens/marketplace_screen.dart';
import 'package:rap_app/screens/admin_screen.dart';
import 'package:rap_app/screens/settings_screen.dart';
import 'package:rap_app/screens/contractor_dashboard.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/screens/chat_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AuthService _auth = AuthService();
  String _userRole = 'user';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await _auth.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final bool isWide = MediaQuery.of(context).size.width > 900;
    final bool isAdmin = _auth.isAdmin;
    final bool isContractor = _userRole == 'contractor';

    final List<Widget> accessibleScreens = isContractor 
      ? [
          const ContractorDashboard(), // 0
          const MarketplaceScreen(), // 1
          const ChatListScreen(), // 2
          const SettingsScreen(), // 3
        ]
      : [
          const HomeScreen(), // 0
          const HistoryScreen(), // 1
          const ChatListScreen(), // 2
          const MarketplaceScreen(), // 3
          if (isAdmin) const AdminScreen() else const SettingsScreen(), // 4
        ];

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Row(
        children: [
          if (isWide) _buildSidebar(isAdmin, isContractor),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedIndex),
                  child: accessibleScreens[_selectedIndex.clamp(0, accessibleScreens.length - 1)],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isWide
          ? NavigationBar(
              elevation: 0,
              backgroundColor: Theme.of(context).cardColor,
              selectedIndex: _selectedIndex.clamp(0, accessibleScreens.length - 1),
              onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
              destinations: isContractor 
                ? [
                    NavigationDestination(icon: const Icon(Icons.dashboard_outlined), label: l10n.proDashboard),
                    NavigationDestination(icon: const Icon(Icons.storefront_outlined), label: l10n.marketplace),
                    NavigationDestination(icon: const Icon(Icons.chat_bubble_outline_rounded), label: l10n.messages),
                    NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l10n.settings),
                  ]
                : [
                    NavigationDestination(icon: const Icon(Icons.add_a_photo_outlined), label: l10n.newEstimate),
                    NavigationDestination(icon: const Icon(Icons.history), label: l10n.history),
                    NavigationDestination(icon: const Icon(Icons.chat_bubble_outline_rounded), label: l10n.messages),
                    NavigationDestination(icon: const Icon(Icons.storefront_outlined), label: l10n.contractors),
                    if (isAdmin) NavigationDestination(icon: const Icon(Icons.admin_panel_settings_outlined), label: l10n.adminPanel) else NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l10n.settings),
                  ],
            )
          : null,
    );
  }

  Widget _buildSidebar(bool isAdmin, bool isContractor) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          _buildLogo(),
          const SizedBox(height: 50),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: isContractor 
                ? [
                    _navItem(0, Icons.dashboard_outlined, l10n.proDashboard),
                    _navItem(1, Icons.storefront_outlined, l10n.marketplace),
                    _navItem(2, Icons.chat_bubble_outline_rounded, l10n.messages),
                    _navItem(3, Icons.settings_outlined, l10n.settings),
                  ]
                : [
                    _navItem(0, Icons.add_a_photo_outlined, l10n.newEstimate),
                    _navItem(1, Icons.history_rounded, l10n.history),
                    _navItem(2, Icons.chat_bubble_outline_rounded, l10n.messages),
                    _navItem(3, Icons.storefront_outlined, l10n.contractors),
                    if (isAdmin) _navItem(4, Icons.admin_panel_settings_outlined, l10n.adminPanel) else _navItem(4, Icons.settings_outlined, l10n.settings),
                  ],
            ),
          ),
          _buildUserCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            'RAP',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.accent,
              radius: 20,
              child: Text(
                _auth.currentUser?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _auth.currentUser?.displayName ?? 'User',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Settings',
                    style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFF94A3B8)),
              onPressed: () async {
                await _auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
