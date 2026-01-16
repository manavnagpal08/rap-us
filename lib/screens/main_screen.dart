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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/services/ai_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AuthService _auth = AuthService();
  bool _isLoading = true;
  bool _showChat = false;

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
            child: Stack(
              children: [
                Row(
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
                          icon: Icon(Icons.shopping_bag_outlined),
                          selectedIcon: Icon(Icons.shopping_bag),
                          label: Text('My Orders'),
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
                
                // Floating Chatbot Button
                Positioned(
                  right: 24,
                  bottom: 24,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _showChat = !_showChat),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFF0055FF).withOpacity(0.1), width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/robot_avatar.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ).animate(target: _showChat ? 0 : 1).shake(hz: 2, curve: Curves.easeInOut).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                    ),
                  ),
                ),

                // Chat Overlay
                if (_showChat)
                  Positioned(
                    right: 24,
                    bottom: 100,
                    child: _buildChatBotUI().animate().fadeIn().scale(alignment: Alignment.bottomRight),
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
            // New Logo
            Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
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
            
            // Language Switcher
            ValueListenableBuilder<Locale>(
              valueListenable: AppTheme.localeNotifier,
              builder: (context, locale, child) {
                return PopupMenuButton<String>(
                  tooltip: 'Change Language',
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      locale.languageCode.toUpperCase(),
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ),
                  onSelected: (String code) {
                    AppTheme.localeNotifier.value = Locale(code);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    _buildLanguageItem('en', 'English'),
                    _buildLanguageItem('hi', 'हिन्दी (Hindi)'),
                    _buildLanguageItem('es', 'Español'),
                    _buildLanguageItem('pt', 'Português'),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),

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

  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [
    {'role': 'bot', 'text': "Hello! I'm your RAP project assistant. How can I help you with your estimation or contractor search today?"},
    {'role': 'bot', 'text': "You can ask me about:\n• Recent estimates\n• Contractor availability\n• Project timelines"},
  ];
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  bool _isChatLoading = false;

  void _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'text': text});
      _chatController.clear();
      _isChatLoading = true;
    });
    
    _scrollToBottom();

    // Get AI response
    try {
        final response = await _aiService.getHelpResponse(text);
        if (mounted) {
            setState(() {
                _chatMessages.add({'role': 'bot', 'text': response});
                _isChatLoading = false;
            });
            _scrollToBottom();
        }
    } catch (e) {
        if (mounted) {
            setState(() {
                 _chatMessages.add({'role': 'bot', 'text': "I'm having trouble connecting. Please try again."});
                 _isChatLoading = false;
            });
        }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildChatBotUI() {
    return Container(
      width: 400,
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0055FF).withOpacity(0.15),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            // Chat Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0055FF), Color(0xFF0088FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(child: Image.asset('assets/images/robot_avatar.png', fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RAP Assistant', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Online • AI Powered', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _showChat = false),
                  ),
                ],
              ),
            ),
            
            // Chat Messages
            Expanded(
              child: Container(
                color: const Color(0xFFF8FAFC),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _chatMessages.length + (_isChatLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _chatMessages.length) {
                        return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                ),
                                child: const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(strokeWidth: 2)
                                ),
                            ),
                        );
                    }
                    
                    final msg = _chatMessages[index];
                    final isUser = msg['role'] == 'user';
                    return isUser ? _buildUserMessage(msg['text']!) : _buildBotMessage(msg['text']!);
                  },
                ),
              ),
            ),

            // Chat Input
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _chatController,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF0055FF), Color(0xFF0088FF)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0x400055FF), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ).animate(target: 1).scale(curve: Curves.easeOutBack),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserMessage(String text) {
    return Align(
        alignment: Alignment.centerRight,
        child: Container(
            margin: const EdgeInsets.only(bottom: 12, left: 60),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0055FF), Color(0xFF0077FF)]),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4),
                ),
                boxShadow: [BoxShadow(color: Color(0x200055FF), blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.5)),
        ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildBotMessage(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 60),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B), height: 1.5),
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  PopupMenuItem<String> _buildLanguageItem(String code, String name) {
    return PopupMenuItem<String>(
      value: code,
      child: Text(name, style: GoogleFonts.inter(fontSize: 14)),
    );
  }
}
