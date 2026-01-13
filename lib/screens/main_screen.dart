import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/screens/home_screen.dart';
import 'package:rap_app/screens/history_screen.dart';
import 'package:rap_app/screens/marketplace_screen.dart';
import 'package:rap_app/screens/admin_screen.dart';
import 'package:rap_app/screens/settings_screen.dart';
import 'package:rap_app/screens/contractor_dashboard.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/theme/app_theme.dart';

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
          const ContractorDashboard(),
          const MarketplaceScreen(),
        ]
      : [
          const HomeScreen(),
          const HistoryScreen(),
          const MarketplaceScreen(),
          if (isAdmin) const AdminScreen(),
        ];

    return Scaffold(
      body: Row(
        children: [
          if (isWide) _buildSidebar(isAdmin, isContractor),
          Expanded(
            child: Container(
              color: AppTheme.webBg,
              child: accessibleScreens[_selectedIndex.clamp(0, accessibleScreens.length - 1)],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isWide
          ? NavigationBar(
              elevation: 0,
              backgroundColor: Colors.white,
              selectedIndex: _selectedIndex.clamp(0, accessibleScreens.length - 1),
              onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
              destinations: isContractor 
                ? [
                    const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Pro'),
                    const NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Market'),
                  ]
                : [
                    const NavigationDestination(icon: Icon(Icons.add_a_photo_outlined), label: 'New'),
                    const NavigationDestination(icon: Icon(Icons.history), label: 'History'),
                    const NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Market'),
                    if (isAdmin) const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
                  ],
            )
          : null,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
            await _auth.signOut();
            if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
        },
        backgroundColor: Colors.redAccent,
        mini: true, 
        tooltip: 'Logout',
        child: const Icon(Icons.logout, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildSidebar(bool isAdmin, bool isContractor) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: const Color(0xFFE2E8F0))),
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
                    _navItem(0, Icons.dashboard_outlined, 'Pro Dashboard'),
                    _navItem(1, Icons.storefront_outlined, 'Public Directory'),
                  ]
                : [
                    _navItem(0, Icons.add_a_photo_outlined, 'New Estimate'),
                    _navItem(1, Icons.history_rounded, 'History'),
                    _navItem(2, Icons.storefront_outlined, 'Contractors'),
                    if (isAdmin) _navItem(3, Icons.admin_panel_settings_outlined, 'Admin Panel'),
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
              color: AppTheme.primary,
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
            color: isSelected ? AppTheme.accent.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.accent : const Color(0xFF64748B),
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.accent : const Color(0xFF64748B),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Settings',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
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
