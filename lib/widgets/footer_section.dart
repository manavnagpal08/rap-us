import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    const Color footerBg = Color(0xFF0F172A); // Dark Slate Blue
    const Color textColor = Color(0xFF94A3B8); // Slate 400
    const Color linkColor = Colors.white;
    const Color accentColor = Color(0xFFE96D3B); // The Orange from their brand

    return Container(
      color: footerBg,
      padding: const EdgeInsets.only(top: 64, bottom: 24, left: 24, right: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Main Footer Content ---
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Col 1: Brand & Socials
                    Expanded(
                      flex: 2,
                      child: _buildBrandColumn(accentColor, textColor, context),
                    ),
                    const SizedBox(width: 40),
                    // Col 2: Quick Links
                    Expanded(
                      child: _buildLinksColumn("Company", [
                        "About Us",
                        "Our Team",
                        "Careers",
                        "Press",
                        "Contact"
                      ], textColor, linkColor, context),
                    ),
                    const SizedBox(width: 24),
                    // Col 3: Services
                    Expanded(
                      child: _buildLinksColumn("Services", [
                         "Renovations",
                         "HVAC Systems",
                         "Roofing",
                         "Plumbing",
                         "Electrical",
                         "Landscaping"
                      ], textColor, linkColor, context),
                    ),
                    const SizedBox(width: 24),
                    // Col 4: Contact
                    Expanded(
                      flex: 1,
                      child: _buildContactColumn(textColor, linkColor),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     _buildBrandColumn(accentColor, textColor, context),
                     const SizedBox(height: 40),
                     Wrap(
                       spacing: 40,
                       runSpacing: 40,
                       children: [
                         _buildLinksColumn("Company", [
                            "About Us",
                            "Our Team",
                            "Careers", 
                            "Press",
                            "Contact"
                         ], textColor, linkColor, context),
                         _buildLinksColumn("Services", [
                             "Renovations",
                             "HVAC Systems",
                             "Roofing",
                             "Plumbing",
                             "Electrical",
                             "Landscaping"
                          ], textColor, linkColor, context),
                         _buildContactColumn(textColor, linkColor),
                       ],
                     ),
                  ],
                ),

              const SizedBox(height: 64),
              Divider(color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 24),

              // --- Bottom Bar ---
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                     return Column(
                       children: [
                         Text(
                          "© ${DateTime.now().year} Reliable Artisan Professional LLC. All rights reserved.",
                          style: GoogleFonts.inter(fontSize: 12, color: textColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _footerLink("Privacy Policy", textColor, context),
                            const SizedBox(width: 24),
                            _footerLink("Terms", textColor, context),
                            const SizedBox(width: 24),
                            _footerLink("Cookies", textColor, context),
                          ],
                        )
                       ],
                     );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "© ${DateTime.now().year} Reliable Artisan Professional LLC. All rights reserved.",
                        style: GoogleFonts.inter(fontSize: 14, color: textColor),
                      ),
                      Row(
                        children: [
                          _footerLink("Privacy Policy", textColor, context),
                          const SizedBox(width: 24),
                          _footerLink("Terms of Service", textColor, context),
                          const SizedBox(width: 24),
                          _footerLink("Cookie Settings", textColor, context),
                        ],
                      ),
                    ],
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandColumn(Color accent, Color textColor, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset('assets/images/logo.png', height: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "RAP US",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Reliable Artisan Professional",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          "Your trusted partner for home improvement, maintenance, and construction management. Bringing transparency and quality to every project.",
          style: GoogleFonts.inter(fontSize: 14, color: textColor, height: 1.6),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _socialIcon(FontAwesomeIcons.facebookF, 'https://facebook.com/rapus'),
            const SizedBox(width: 16),
            _socialIcon(FontAwesomeIcons.twitter, 'https://twitter.com/rapus'),
            const SizedBox(width: 16),
            _socialIcon(FontAwesomeIcons.instagram, 'https://instagram.com/rapus'),
            const SizedBox(width: 16),
            _socialIcon(FontAwesomeIcons.linkedinIn, 'https://linkedin.com/company/rapus'),
          ],
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon, String url) {
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: FaIcon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildLinksColumn(String title, List<String> links, Color textColor, Color linkColor, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Navigate to $link (Coming Soon)'), duration: const Duration(seconds: 1)),
               );
            },
            child: Text(
              link,
              style: GoogleFonts.inter(fontSize: 14, color: textColor),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildContactColumn(Color textColor, Color linkColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Get in Touch",
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
         _contactRow(Icons.email_outlined, "support@coloradorap.com", "mailto:support@coloradorap.com"),
         const SizedBox(height: 16),
         _contactRow(Icons.phone_rounded, "+1 720 443 1536", "tel:+17204431536"),
         const SizedBox(height: 16),
         _contactRow(Icons.location_on_outlined, "Denver, Colorado, US", "https://maps.google.com/?q=Denver,Colorado,US"),
      ],
    );
  }

  Widget _contactRow(IconData icon, String text, String url) {
    return InkWell(
      onTap: () => _launchURL(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFE96D3B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerLink(String text, Color color, BuildContext context) {
    return InkWell(
      onTap: () {
          // Show dialog for simulated pages
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(text),
              content: Text("This is the $text page content holder."),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
            ),
          );
      },
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, color: color),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $url');
    }
  }
}
