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
import 'package:rap_app/screens/login_screen.dart';
import 'package:rap_app/screens/documentation_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AuthService _auth = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleLogin() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // New Order: Estimates, Contractors, History, Settings, About Us
    final List<Widget> screens = [
      const HomeScreen(),
      const MarketplaceScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
      const DocumentationScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Persistent Top Header
          _buildTopHeader(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: Row(
              children: [
                // Sidebar
                NavigationRail(
                  backgroundColor: const Color(0xFFFBFBFE),
                  elevation: 0,
                  extended: MediaQuery.of(context).size.width > 1200,
                  minExtendedWidth: 200,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                  labelType: MediaQuery.of(context).size.width > 1200 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  selectedLabelTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF0055FF)),
                  unselectedLabelTextStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  selectedIconTheme: const IconThemeData(color: Color(0xFF0055FF)),
                  unselectedIconTheme: const IconThemeData(color: Color(0xFF64748B)),
                  indicatorColor: const Color(0xFF0055FF).withOpacity(0.1),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.description_outlined),
                      selectedIcon: Icon(Icons.description),
                      label: Text('Estimates'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.group_outlined),
                      selectedIcon: Icon(Icons.group),
                      label: Text('Contractors'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history),
                      label: Text('History'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.info_outline),
                      selectedIcon: Icon(Icons.info),
                      label: Text('About Us'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFEEEEEE)),
                // Main Content
                Expanded(
                  child: screens[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    final user = _auth.currentUser;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Logo
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0055FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  'R',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'RAP',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            // Search Bar (Center-ish)
            if (MediaQuery.of(context).size.width > 800)
              Container(
                width: 400,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search projects, contractors...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            const Spacer(),
            // Theme Toggle
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppTheme.themeModeNotifier,
              builder: (context, mode, child) {
                final isDark = mode == ThemeMode.dark;
                return IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: const Color(0xFF64748B),
                  ),
                  onPressed: () {
                    AppTheme.themeModeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                  },
                  tooltip: 'Toggle Theme',
                );
              },
            ),
            const SizedBox(width: 8),
            // Notification Bell
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
            const SizedBox(width: 12),
            // User Profile / Guest Menu
            if (user != null)
              _buildUserMenu(user)
            else
              _buildGuestMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMenu(user) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      position: PopupMenuPosition.under,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFF1F5F9),
            radius: 16,
            child: Text(
              user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.displayName ?? 'User Name',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              Text(
                user.email ?? 'user@example.com',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
              ),
            ],
          ),
          const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
        ],
      ),
      onSelected: (value) async {
        if (value == 'settings') {
          setState(() => _selectedIndex = 3);
        } else if (value == 'logout') {
          await _auth.signOut();
          setState(() {});
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          child: Text('My Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: Color(0xFF64748B)),
              SizedBox(width: 12),
              Text('Profile'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20, color: Color(0xFF64748B)),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Text('Log out', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildGuestMenu() {
    return Row(
      children: [
        Text(
          'Welcome Guest',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0055FF),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            minimumSize: const Size(80, 36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
