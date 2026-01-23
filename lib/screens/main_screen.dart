import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/screens/home_screen.dart';
import 'package:rap_app/widgets/premium_background.dart';
import 'package:rap_app/screens/history_screen.dart';
import 'package:rap_app/screens/marketplace_screen.dart';
import 'package:rap_app/screens/settings_screen.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/screens/login_screen.dart';
import 'package:rap_app/screens/documentation_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/services/ai_service.dart';
import 'package:rap_app/screens/my_home_inventory_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:rap_app/screens/emergency_sos_dialog.dart';
import 'package:rap_app/services/database_service.dart';
import 'dart:convert';
import 'package:rap_app/screens/contractor_dashboard.dart';
import 'package:rap_app/screens/contractor_leads_screen.dart';
import 'package:rap_app/screens/contractor_earnings_screen.dart';
import 'package:rap_app/screens/contractor_history_screen.dart';
import 'package:rap_app/screens/rap_gpt_screen.dart';
import 'package:rap_app/screens/ai_room_visualizer_screen.dart';
import 'package:rap_app/screens/admin_screen.dart';
import 'package:rap_app/screens/maintenance_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  String _userRole = 'user';
  bool _showChat = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String? _lastBroadcastId;

  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [
    {'role': 'bot', 'text': "Hello! I'm your RAP project assistant. How can I help you with your estimation or contractor search today?"},
  ];
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  bool _isChatLoading = false;
  bool _isEstimating = false;

  void _handleEstimateChange(bool isEstimating) {
    if (_isEstimating != isEstimating && mounted) {
      setState(() => _isEstimating = isEstimating);
    }
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _checkRole();
    _listenForBroadcasts();
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    if (mounted) setState(() {});
  }

  Map<String, dynamic>? _userProfile;
  
  Future<void> _checkRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final profile = await _db.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _userRole = profile?['role'] ?? 'user';
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isAdmin {
    final email = _auth.currentUser?.email;
    if (email == 'kaaysha.rao@gmail.com' || email == 'admin@rap.com' || email == 'manav.nagpal2005@gmail.com') return true;
    return _userProfile?['role'] == 'admin';
  }

  void _listenForBroadcasts() {
    _db.getBroadcastNotifications().listen((notifications) {
      if (notifications.isNotEmpty && mounted) {
        final last = notifications.first;
        if (_lastBroadcastId != last['id']) {
          setState(() => _lastBroadcastId = last['id']);
          _showBroadcastNotification(last['title'] ?? 'Announcement', last['body'] ?? '');
        }
      }
    });
  }

  void _showBroadcastNotification(String title, String body) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            Text(body, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF0055FF),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(label: 'Dismiss', textColor: Colors.white, onPressed: () {}),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  void _startListening() async {
    if (!_speechEnabled) return;
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _chatController.text = result.recognizedWords;
          if (result.finalResult) {
            _sendMessage();
            _stopListening();
          }
        });
      },
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'text': text});
      _chatController.clear();
      _isChatLoading = true;
    });
    
    _scrollToBottom();

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

  void _handleLogin() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;
    final bool isContractor = _userRole == 'contractor';

    final bool isDesktop = MediaQuery.of(context).size.width >= 900;
    final bool isGuest = FirebaseAuth.instance.currentUser == null;

    final List<Widget> screens = isContractor 
      ? [
          const ContractorDashboard(),
          const ContractorLeadsScreen(),
          const ContractorEarningsScreen(),
          const ContractorHistoryScreen(),
          const SettingsScreen(),
          const DocumentationScreen(),
          if (_isAdmin) const AdminScreen(),
        ]
      : [
          HomeScreen(onEstimatingChanged: _handleEstimateChange),
          if (!isGuest) const AiRoomVisualizerScreen(),
          const MarketplaceScreen(),
          if (!isGuest) const HistoryScreen(),
          if (!isGuest) const MyHomeInventoryScreen(),
          const SettingsScreen(),
          const DocumentationScreen(),
          if (_isAdmin) const AdminScreen(),
        ];

    return StreamBuilder<Map<String, dynamic>>(
      stream: _db.getMaintenanceSettings(),
      builder: (context, mSnapshot) {
        final maintenance = mSnapshot.data ?? {'isEnabled': false, 'message': 'Under Maintenance'};
        if (maintenance['isEnabled'] == true && !_isAdmin) {
          return MaintenanceScreen(
            message: maintenance['message'],
            allowFeedback: maintenance['allowFeedback'] ?? true,
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          extendBody: true, 
          bottomNavigationBar: (isDesktop || _isEstimating) ? null : _buildCustomBottomNav(l10n, isContractor, isGuest),
          body: Stack(
            children: [
              const PremiumBackground(),
              Column(
                children: [
                  _buildTopHeader(isContractor),
                  StreamBuilder<Map<String, dynamic>>(
                    stream: _db.getBannerSettings(),
                    builder: (context, bSnapshot) {
                      final banner = bSnapshot.data ?? {'isEnabled': false};
                      if (banner['isEnabled'] != true) return const SizedBox.shrink();
                      
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () async {
                              if (banner['link'] != null && banner['link'].toString().isNotEmpty) {
                                final url = Uri.parse(banner['link']);
                                if (await canLaunchUrl(url)) await launchUrl(url);
                              }
                            },
                            child: Stack(
                              children: [
                                if (banner['imageUrl'] != null && banner['imageUrl'].toString().isNotEmpty)
                                  Image.network(
                                    banner['imageUrl'],
                                    width: double.infinity,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                else
                                  Container(
                                    height: 80,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.7)]),
                                    ),
                                  ),
                                Container(
                                  height: 80,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    banner['message'] ?? 'Check out our new update!',
                                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().slideY(begin: -1, end: 0);
                    },
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isDesktop)
                              NavigationRail(
                                backgroundColor: Theme.of(context).cardColor,
                                elevation: 0,
                                extended: MediaQuery.of(context).size.width > 1200,
                                minExtendedWidth: 200,
                                selectedIndex: _selectedIndex,
                                onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                                labelType: MediaQuery.of(context).size.width > 1200 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                                selectedLabelTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF0055FF)),
                                unselectedLabelTextStyle: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor),
                                selectedIconTheme: const IconThemeData(color: Color(0xFF0055FF)),
                                unselectedIconTheme: IconThemeData(color: Theme.of(context).hintColor),
                                indicatorColor: const Color(0xFF0055FF).withValues(alpha: 0.1),
                                destinations: isContractor 
                                  ? [
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.dashboard_outlined),
                                        selectedIcon: const Icon(Icons.dashboard),
                                        label: Text(l10n.proDashboard),
                                      ),
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.flash_on_outlined),
                                        selectedIcon: const Icon(Icons.flash_on),
                                        label: const Text('Leads'), 
                                      ),
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.payments_outlined),
                                        selectedIcon: const Icon(Icons.payments),
                                        label: const Text('Earnings'),
                                      ),
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.history_rounded),
                                        selectedIcon: const Icon(Icons.history),
                                        label: Text(l10n.history),
                                      ),
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.settings_outlined),
                                        selectedIcon: const Icon(Icons.settings),
                                        label: Text(l10n.settings),
                                      ),
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.article_outlined),
                                        selectedIcon: const Icon(Icons.article),
                                        label: const Text('Docs'),
                                      ),
                                      if (_isAdmin)
                                        const NavigationRailDestination(
                                          icon: Icon(Icons.admin_panel_settings_outlined),
                                          selectedIcon: Icon(Icons.admin_panel_settings),
                                          label: Text('Admin'),
                                        ),
                                    ]
                                  : [
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.description_outlined),
                                        selectedIcon: const Icon(Icons.description),
                                        label: Text(l10n.estimates),
                                      ),
                                      if (!isGuest)
                                        NavigationRailDestination(
                                          icon: const Icon(Icons.auto_fix_high_outlined),
                                          selectedIcon: const Icon(Icons.auto_fix_high),
                                          label: const Text('AI Redesign'),
                                        ),
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.group_outlined),
                                        selectedIcon: const Icon(Icons.group),
                                        label: Text(l10n.contractors),
                                      ),
                                      if (!isGuest)
                                        NavigationRailDestination(
                                          icon: const Icon(Icons.shopping_bag_outlined),
                                          selectedIcon: const Icon(Icons.shopping_bag),
                                          label: Text(l10n.history),
                                        ),
                                      if (!isGuest)
                                        NavigationRailDestination(
                                          icon: const Icon(Icons.home_work_outlined),
                                          selectedIcon: const Icon(Icons.home_work),
                                          label: const Text('My Home'),
                                        ),
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.settings_outlined),
                                        selectedIcon: const Icon(Icons.settings),
                                        label: Text(l10n.settings),
                                      ),
                                      NavigationRailDestination(
                                        icon: const Icon(Icons.info_outline),
                                        selectedIcon: const Icon(Icons.info),
                                        label: Text(l10n.aboutRap),
                                      ),
                                      if (_isAdmin)
                                        const NavigationRailDestination(
                                          icon: Icon(Icons.admin_panel_settings_outlined),
                                          selectedIcon: Icon(Icons.admin_panel_settings),
                                          label: Text('Admin'),
                                        ),
                                    ],
                              ),
                            if (isDesktop)
                              VerticalDivider(thickness: 1, width: 1, color: Theme.of(context).dividerColor),
                            Expanded(
                              child: screens.length > _selectedIndex ? screens[_selectedIndex] : screens[0],
                            ),
                          ],
                        ),
                        if (!isContractor) ...[
                          Positioned(
                            left: 24,
                            bottom: isDesktop ? 24 : 100,
                            child: FloatingActionButton.extended(
                              onPressed: () {
                                  showDialog(
                                     context: context,
                                     barrierDismissible: false,
                                     builder: (context) => const EmergencySOSDialog(),
                                  );
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: const Icon(Icons.warning_amber_rounded).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1),
                              label: const Text('SOS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ).animate().scale(begin: const Offset(0,0), duration: 500.ms, curve: Curves.elasticOut),
                          ),

                          Positioned(
                            right: 24,
                            bottom: isDesktop ? 100 : 180,
                            child: FloatingActionButton(
                              heroTag: 'gpt',
                              backgroundColor: Colors.black,
                              child: const Icon(Icons.psychology_alt, color: Color(0xFF00FF9D)),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const RapGptSheet(),
                                );
                              },
                            ).animate().scale(delay: 200.ms),
                          ),

                          Positioned(
                            right: 24,
                            bottom: isDesktop ? 24 : 100,
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
                                      BoxShadow(color: const Color(0xFF0055FF).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                                    ],
                                    border: Border.all(color: const Color(0xFF0055FF).withValues(alpha: 0.1), width: 2),
                                  ),
                                  child: ClipOval(child: Image.asset('assets/images/robot_avatar.png', fit: BoxFit.cover)),
                                ).animate(target: _showChat ? 0 : 1).shake(hz: 0.5, curve: Curves.easeInOut).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                              ),
                            ),
                          ),

                          if (_showChat)
                            Positioned(
                              right: 24,
                              bottom: isDesktop ? 100 : 180,
                              child: _buildChatBotUI().animate().fadeIn().scale(alignment: Alignment.bottomRight),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopHeader(bool isContractor) {
    final user = _auth.currentUser;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 8), // Reduced top margin
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32, vertical: isMobile ? 8 : 12), // Reduced vertical padding
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.9), 
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: ClipRRect( 
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            bottom: false,
            child: Row(
          children: [
            if (!isContractor)
            Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: isMobile ? 32 : 36, // Increased slightly
                  height: isMobile ? 32 : 36,
                  fit: BoxFit.contain,
                ).animate().rotate(duration: 800.ms, curve: Curves.easeOutBack),
                const SizedBox(width: 8),
                Text(
                  'RAP',
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(),
              ],
            )
            else
              Builder(
                builder: (context) {
                  String title = l10n.proDashboard;
                  if (_selectedIndex == 1) title = 'Job Leads';
                  if (_selectedIndex == 2) title = 'Earnings';
                  if (_selectedIndex == 3) title = 'Project History';
                  if (_selectedIndex == 4) title = l10n.settings;
                  if (_selectedIndex == 5) title = 'Documentation';
                  
                  return Text(
                    title,
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  );
                }
              ),
            
            const Spacer(),
            
            if (!isMobile && !isContractor)
              Container(
                width: 400,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).hintColor),
                    prefixIcon: Icon(Icons.search, size: 18, color: Theme.of(context).hintColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              
            if (!isMobile) const Spacer(),
            Row(
              children: [
                if (!isMobile) ...[
                  ValueListenableBuilder<Locale>(
                    valueListenable: AppTheme.localeNotifier,
                    builder: (context, locale, child) {
                      return PopupMenuButton<String>(
                        icon: Text(locale.languageCode.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                        onSelected: (String code) => AppTheme.localeNotifier.value = Locale(code),
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          _buildLanguageItem('en', 'English'),
                          _buildLanguageItem('hi', 'Hindi'),
                          _buildLanguageItem('es', 'Español'),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppTheme.themeModeNotifier,
                  builder: (context, mode, child) {
                    final isDark = mode == ThemeMode.dark;
                    return IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: Theme.of(context).hintColor,
                        size: 20,
                      ),
                      onPressed: () { AppTheme.themeModeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark; },
                    ).animate().rotate(begin: 0, end: 0.5, duration: 500.ms);
                  },
                ),
                const SizedBox(width: 8),
                if (user != null)
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = isContractor ? 4 : 4),
                    child: CircleAvatar(
                      radius: isMobile ? 16 : 18,
                      backgroundColor: const Color(0xFF0055FF),
                      backgroundImage: _userProfile?['photoBase64'] != null 
                        ? MemoryImage(base64Decode(_userProfile!['photoBase64']))
                        : null,
                      child: _userProfile?['photoBase64'] == null 
                        ? Text(
                            user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ) 
                        : null,
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(delay: 2000.ms, duration: 1000.ms),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.login_rounded),
                    onPressed: _handleLogin,
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
    ),
    );
  }

  PopupMenuItem<String> _buildLanguageItem(String code, String name) {
    return PopupMenuItem<String>(value: code, child: Text(name, style: GoogleFonts.inter(fontSize: 13)));
  }

  Widget _buildCustomBottomNav(AppLocalizations l10n, bool isContractor, bool isGuest) {
    final items = isContractor 
      ? [
          {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'label': l10n.proDashboard},
          {'icon': Icons.flash_on_outlined, 'activeIcon': Icons.flash_on, 'label': 'Leads'},
          {'icon': Icons.payments_outlined, 'activeIcon': Icons.payments, 'label': 'Earnings'},
          {'icon': Icons.history_rounded, 'activeIcon': Icons.history, 'label': l10n.history},
          {'icon': Icons.settings_outlined, 'activeIcon': Icons.settings, 'label': l10n.settings},
          if (_isAdmin) {'icon': Icons.admin_panel_settings_outlined, 'activeIcon': Icons.admin_panel_settings, 'label': 'Admin'},
      ]
      : [
          {'icon': Icons.description_outlined, 'activeIcon': Icons.description, 'label': l10n.estimates},
          if (!isGuest) {'icon': Icons.auto_fix_high_outlined, 'activeIcon': Icons.auto_fix_high, 'label': 'AI Redesign'},
          {'icon': Icons.group_outlined, 'activeIcon': Icons.group, 'label': l10n.contractors},
          if (!isGuest) {'icon': Icons.shopping_bag_outlined, 'activeIcon': Icons.shopping_bag, 'label': l10n.history},
          if (!isGuest) {'icon': Icons.home_work_outlined, 'activeIcon': Icons.home_work, 'label': 'My Home'},
          {'icon': Icons.settings_outlined, 'activeIcon': Icons.settings, 'label': l10n.settings},
          if (_isAdmin) {'icon': Icons.admin_panel_settings_outlined, 'activeIcon': Icons.admin_panel_settings, 'label': 'Admin'},
      ];

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                Theme.of(context).scaffoldBackgroundColor,
              ],
              stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10)),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isSelected = _selectedIndex == index;
            final item = items[index];
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0055FF).withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? (item['activeIcon'] as IconData) : (item['icon'] as IconData),
                      color: isSelected ? const Color(0xFF0055FF) : Theme.of(context).hintColor,
                      size: 24,
                    ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 200.ms),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item['label'] as String,
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0055FF)),
                        ).animate().fadeIn().slideY(begin: 0.2),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildChatBotUI() {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    
    return Container(
      width: isMobile ? size.width - 48 : 400,
      height: isMobile ? size.height * 0.6 : 600,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0055FF).withValues(alpha: 0.15), blurRadius: 60, offset: const Offset(0, 20)),
        ],
        border: Border.all(color: Theme.of(context).dividerColor, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0055FF), Color(0xFF0088FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48, padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(child: Image.asset('assets/images/robot_avatar.png', fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.rapBot, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Online • AI Powered', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _showChat = false)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _chatMessages.length + (_isChatLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _chatMessages.length) return Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)), child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
                    final msg = _chatMessages[index];
                    final isUser = msg['role'] == 'user';
                    return isUser ? _buildUserMessage(msg['text']!) : _buildBotMessage(msg['text']!);
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: Row(
                children: [
                   Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                      child: TextField(
                        controller: _chatController,
                        onSubmitted: (_) => _sendMessage(),
                        style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(hintText: _isListening ? 'Listening...' : l10n.typeMessage, hintStyle: GoogleFonts.inter(fontSize: 14, color: _isListening ? AppTheme.accent : Theme.of(context).hintColor), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? AppTheme.accent : null),
                    onPressed: _isListening ? _stopListening : _startListening
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(backgroundColor: const Color(0xFF0055FF), child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sendMessage)),
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
        margin: const EdgeInsets.only(bottom: 12, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(color: Color(0xFF0055FF), borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20), topRight: Radius.circular(20))),
        child: Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
      ),
    );
  }

  Widget _buildBotMessage(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomRight: Radius.circular(20), topRight: Radius.circular(20)), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
      ),
    );
  }
}
