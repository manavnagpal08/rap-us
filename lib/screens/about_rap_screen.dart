import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/widgets/premium_background.dart';

class AboutRapScreen extends StatelessWidget {
  const AboutRapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('About RAP', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const PremiumBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Image.asset('assets/images/logo.png', height: 80),
                          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 24),
                          Text(
                            "RAP Colorado",
                            style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                          Text(
                            "Reliable Artisan Professional",
                            style: GoogleFonts.inter(fontSize: 16, color: AppTheme.accent, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 64),

                    // Mission Content
                    _buildSectionTitle("Our Mission"),
                    _buildParagraph(
                      "At RAP Colorado, we are dedicated to transforming the construction and home improvement industry through transparency, reliability, and professional excellence. Our goal is to bridge the gap between homeowners and skilled artisans, ensuring every project is completed with the highest standards of quality."
                    ),
                    const SizedBox(height: 48),

                    _buildSectionTitle("Why Choose RAP?"),
                    const SizedBox(height: 24),
                    _buildFeature(Icons.verified_user_rounded, "Verified Professionals", "Every contractor on our platform undergoes a rigorous vetting process, including background checks, license verification, and skill assessments."),
                    _buildFeature(Icons.attach_money_rounded, "Transparent Pricing", "No hidden fees or surprise costs. Our AI-driven estimation tools provide accurate, market-based pricing before you even start."),
                    _buildFeature(Icons.security_rounded, "Secure Payments", "Your funds are protected in escrow and only released when milestones are met and you are satisfied with the work."),
                    
                    const SizedBox(height: 48),
                    _buildSectionTitle("Our Story"),
                    _buildParagraph(
                      "Founded in Denver, RAP began with a simple observation: finding a reliable contractor shouldn't be a gamble. We built a platform that empowers both homeowners and honest tradespeople, creating a community built on trust and mutual respect."
                    ),

                    const SizedBox(height: 64),
                    Center(
                      child: Text(
                        "Building the Future of Colorado, One Project at a Time.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Container(margin: const EdgeInsets.only(top: 8), width: 60, height: 4, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
      ],
    ).animate().fadeIn().slideX();
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 16, height: 1.6, color: Colors.white70),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildFeature(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX();
  }
}
