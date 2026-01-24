import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // Luxury SaaS Palette
  static const Color primary = Color(0xFF0F172A); // Slate 900
  static const Color accent = Color(0xFF0055FF);  // RAP Blue
  static const Color secondary = Color(0xFF0EA5E9); // Sky 500
  static const Color success = Color(0xFF10B981);  // Emerald 500
  static const Color successColor = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);  // Amber 500
  static const Color error = Color(0xFFEF4444);    // Red 500
  static const Color webBg = Color(0xFFF8FAFC);    // Slate 50
  
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);
  static final ValueNotifier<String> currencySymbolNotifier = ValueNotifier('\$');
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme
    final isDark = prefs.getBool('isDarkMode') ?? false;
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    
    // Locale
    final langCode = prefs.getString('languageCode') ?? 'en';
    localeNotifier.value = Locale(langCode);
    
    // Currency
    currencySymbolNotifier.value = prefs.getString('currency') ?? '\$';

    // Listeners to save changes
    themeModeNotifier.addListener(() {
      prefs.setBool('isDarkMode', themeModeNotifier.value == ThemeMode.dark);
    });
    
    localeNotifier.addListener(() {
      prefs.setString('languageCode', localeNotifier.value.languageCode);
    });
    
    currencySymbolNotifier.addListener(() {
      prefs.setString('currency', currencySymbolNotifier.value);
    });
  }


  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: primary,
        secondary: accent,
        surface: Colors.white,
        onSurface: primary,
        error: error,
      ),
      dividerColor: const Color(0xFFE2E8F0),
      hintColor: const Color(0xFF64748B),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(color: primary, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        elevation: 0, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
        color: Colors.white
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accent, width: 2)),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accent,
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Slate
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: accent,
        primary: accent,
        secondary: secondary,
        surface: const Color(0xFF1E293B), // Card color for dark
        onSurface: Colors.white,
        error: error,
        surfaceContainer: const Color(0xFF334155),
      ),
      dividerColor: Colors.white.withValues(alpha: 0.1),
      hintColor: const Color(0xFF94A3B8),
      cardColor: const Color(0xFF1E293B),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
        color: const Color(0xFF1E293B)
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accent, width: 2)),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
      ),
    );
  }

  static BoxDecoration glassDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primary, Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient accentGradient = const LinearGradient(
    colors: [accent, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
