import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/widgets/premium_background.dart';

class CompanyInfoScreen extends StatelessWidget {
  final String title;
  final String type; // 'team', 'careers', 'press'

  const CompanyInfoScreen({super.key, required this.title, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
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
                child: _buildContent(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (type) {
      case 'team':
        return _buildTeamContent(context);
      case 'careers':
        return _buildCareersContent(context);
      case 'press':
        return _buildPressContent(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTeamContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("Meet the Artisans", "The people behind RAP Colorado."),
        const SizedBox(height: 48),
        _buildTeamMember("Kaaysha Rao", "Founder & CEO", "Visionary leader with a passion for transforming construction standards in Colorado."),
        _buildTeamMember("Marcus Thorne", "Head of Quality", "20+ years of experience in high-end residential construction and inspection."),
        _buildTeamMember("Sarah Chen", "Product Design", "Creating intuitive digital tools for homeowners and contractors."),
      ],
    );
  }

  Widget _buildCareersContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("Build Your Career", "Join us in redefining the future of construction."),
        const SizedBox(height: 48),
        _buildJobOpening("Senior Flutter Developer", "Engineering • Remote / Denver", "Work on our state-of-the-art mobile and web applications."),
        _buildJobOpening("Operations Manager", "Operations • Denver", "Streamlining contractor vetting and project management flows."),
        _buildJobOpening("Community Liaison", "Growth • Colorado", "Building relationships with the best local artisans and homeowners."),
        const SizedBox(height: 40),
        Center(
          child: Text(
            "Send your resume to careers@coloradorap.com",
            style: GoogleFonts.inter(color: AppTheme.accent, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPressContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("Press Room", "Latest news and updates from RAP Colorado."),
        const SizedBox(height: 48),
        _buildPressRelease("Jan 2026", "RAP Colorado Launches AI-Driven Estimation Tool", "Redefining how homeowners plan their luxury renovations."),
        _buildPressRelease("Nov 2025", "RAP Secures \$10M Series A Funding", "Accelerating our mission to bring transparency to construction."),
        _buildPressRelease("Aug 2025", "Named 'Innovator of the Year' by CO Construction Assoc.", "Recognizing our commitment to quality and artisan empowerment."),
      ],
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 16),
        Container(width: 60, height: 4, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildTeamMember(String name, String role, String bio) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.person_rounded, color: AppTheme.accent, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(role, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(bio, style: GoogleFonts.inter(fontSize: 15, color: Colors.white60, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX();
  }

  Widget _buildJobOpening(String title, String meta, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Icon(Icons.arrow_forward_rounded, color: AppTheme.accent, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(meta, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Text(description, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.5)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildPressRelease(String date, String title, String summary) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(summary, style: GoogleFonts.inter(fontSize: 15, color: Colors.white60, height: 1.5)),
          const SizedBox(height: 16),
          Text("Read More", style: GoogleFonts.inter(fontSize: 14, color: Colors.white, decoration: TextDecoration.underline)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }
}
