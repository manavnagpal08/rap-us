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

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _auth = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0); // Default to Contractors
    _checkRole();
  }

  Future<void> _checkRole() async {
    // Role check is less relevant for initial guest access but kept for future use
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Top Header Row
              Container(
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
                          color: const Color(0xFF0055FF), // RAP Blue
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'R',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'RAP',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      // User Profile
                      if (_auth.currentUser != null)
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFF1F5F9),
                              radius: 16,
                              child: Text(
                                _auth.currentUser?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
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
                              children: [
                                Text(
                                  _auth.currentUser?.displayName ?? 'John Doe',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  _auth.currentUser?.email ?? 'john@example.com',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        TextButton(
                          onPressed: _handleLogin,
                          child: Text('Log In', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0055FF))),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Tab Bar Row
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF0055FF),
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: [
                    Tab(
                      height: 48, 
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Contractors'),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      height: 48, 
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.description_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Estimates'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  color: const Color(0xFFFBFBFE), 
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      const MarketplaceScreen(),   
                      const HomeScreen(),          
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Bottom Left Floating Button (About Us)
          Positioned(
            left: 20,
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentationScreen()));
                },
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('About Us'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
              ),
            ),
          ),
          // Bottom Right Helping Circle
          Positioned(
            right: 20,
            bottom: 20,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.question_mark_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
