import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DocumentationScreen extends StatelessWidget {
  const DocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0055FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'KNOWLEDGE HUB',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0055FF),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to RAP',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The future of home repair and renovation estimation.',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sections
          SliverPadding(
            padding: const EdgeInsets.all(40),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 32,
                mainAxisSpacing: 32,
                mainAxisExtent: 260,
              ),
              delegate: SliverChildListDelegate([
                _buildInfoCard(
                  context,
                  icon: Icons.auto_awesome_outlined,
                  title: 'Smart Estimates',
                  description: 'Our AI analyzes object type, dimensions, and materials from a single photo to provide instant cost projections.',
                  accentColor: const Color(0xFF0055FF),
                ).animate().fadeIn(delay: 0.ms).slideX(begin: -0.2),
                _buildInfoCard(
                  context,
                  icon: Icons.verified_user_outlined,
                  title: 'Verified Pros',
                  description: 'Every contractor on RAP undergoes a rigorous verification process to ensure quality and reliability.',
                  accentColor: const Color(0xFF10B981),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.2),
                _buildInfoCard(
                  context,
                  icon: Icons.eco_outlined,
                  title: 'Green Advantage',
                  description: 'We suggest sustainable material alternatives that can save you money and protect the environment.',
                  accentColor: const Color(0xFFF59E0B),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                _buildInfoCard(
                  context,
                  icon: Icons.security_outlined,
                  title: 'Secure Payments',
                  description: 'Built-in security features like 2FA and Biometrics keep your financial and project data safe.',
                  accentColor: const Color(0xFF6366F1),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              ]),
            ),
          ),

          // Mission Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(40, 0, 40, 60),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Our Mission',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'To bring transparency, efficiency, and intelligence to the home improvement industry through cutting-edge AI technology.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  const Icon(
                    Icons.rocket_launch_outlined,
                    size: 80,
                    color: Colors.white24,
                  ),
                ],
              ),
            ),
          ),
          
          // Services List Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Renovation & Repair Services',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildServiceChip('Plumbing'),
                      _buildServiceChip('Electrical'),
                      _buildServiceChip('Carpentry'),
                      _buildServiceChip('Painting'),
                      _buildServiceChip('HVAC'),
                      _buildServiceChip('Roofing'),
                      _buildServiceChip('Flooring'),
                      _buildServiceChip('Masonry'),
                      _buildServiceChip('Drywall'),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
          
          // Footer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Center(
                child: Text(
                  '© 2026 RAP US Technologies. All rights reserved.',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0055FF),
        ),
      ),
    );
  }
}
