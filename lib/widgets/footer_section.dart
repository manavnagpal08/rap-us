import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors extracted from Image
    const Color darkBlue = Color(0xFF152642); 
    const Color orange = Color(0xFFE96D3B); 
    const Color orangeText = Color(0xFFE96D3B);

    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    
    return Container(
      width: double.infinity,
      color: darkBlue,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          children: [
            // --- TOP HEADER SECTION ---
            LayoutBuilder(
              builder: (context, constraints) {
                if (!isDesktop) {
                  return Column(
                    children: [
                      // Logo & Titles
                      Image.asset('assets/images/logo.png', height: 100),
                      const SizedBox(height: 16),
                      Text(
                        'RELIABLE ARTISAN PROFESSIONAL LLC',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'YOUR TRUSTED GENERAL CONTRACTOR', // Fixed typo
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: orangeText,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Contact Info
                      _buildContactInfo(orangeText, isCentered: true),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      // Logo
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(4),
                        child: Image.asset('assets/images/logo.png', height: 100),
                      ),
                      const SizedBox(width: 24),
                      // Texts
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RELIABLE ARTISAN PROFESSIONAL LLC',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'YOUR TRUSTED GENERAL CONTRACTOR',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: orangeText,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Contact
                      _buildContactInfo(orangeText),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: 60),

            // --- BOTTOM CONTENT SECTION ---
            LayoutBuilder(
              builder: (context, constraints) {
                if (!isDesktop) {
                   return Column(
                     children: [
                       _buildServicesCard(orange),
                       const SizedBox(height: 32),
                       _buildIconsRow(),
                        const SizedBox(height: 32),
                       _buildValuesCard('RELIABLE', 'We are the dependable partner you can trust to deliver quality results on time and within budget, every single time', orange),
                       const SizedBox(height: 16),
                       _buildValuesCard('ARTISAN', 'We apply skilled craftsmanship and meticulous attention to detail to create beautiful, lasting improvements in your home', orange),
                        const SizedBox(height: 16),
                       _buildValuesCard('PROFESSIONAL', 'We handle every project with the highest standards of integrity, clear communication, and industry expertise', orange),
                     ],
                   );
                } else {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Services Column
                        SizedBox(
                          width: 320,
                          child: _buildServicesCard(orange),
                        ),
                        const SizedBox(width: 40),
                        // Right Side
                        Expanded(
                          child: Column(
                            children: [
                              // Icons Row
                              _buildIconsRow(),
                              const Spacer(),
                              // 3 Value Cards
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildValuesCard('RELIABLE', 'We are the dependable partner you can trust to deliver quality results on time and within budget, every single time', orange)),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildValuesCard('ARTISAN', 'We apply skilled craftsmanship and meticulous attention to detail to create beautiful, lasting improvements in your home', orange)),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildValuesCard('PROFESSIONAL', 'We handle every project with the highest standards of integrity, clear communication, and industry expertise', orange)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(Color orangeText, {bool isCentered = false}) {
    return Column(
      crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
         Text(
          'CONTACT US:',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: orangeText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Phone: +1 720 443 1536',
          style: GoogleFonts.inter(fontSize: 15, color: Colors.white, height: 1.5),
        ),
        Text(
          'Email: support@coloradorap.com',
          style: GoogleFonts.inter(fontSize: 15, color: Colors.white, height: 1.5),
        ),
         Text(
          'Visit Us: www.coloradorap.com',
          style: GoogleFonts.inter(fontSize: 15, color: Colors.white, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildServicesCard(Color color) {
    final services = [
      'Landscaping',
      'HVAC Installation',
      'Roof Replacement',
      'Handyman Services',
      'Basement Finishing',
      'Electrical & Plumbing',
      'Exterior & Interior Painting',
      'Flooring Refinish & Installation',
      'Kitchen & Bathroom Remodeling'
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
         color: color,
         borderRadius: BorderRadius.circular(40),
         boxShadow: [
           BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: Offset(0, 5))
         ]
      ),
      child: Column(
        children: [
          Text(
            'SERVICES',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF152642), // Dark Blue text on Orange
            ),
          ),
          const SizedBox(height: 24),
          ...services.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              s,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildIconsRow() {
    final icons = [
      FontAwesomeIcons.screwdriverWrench, 
      FontAwesomeIcons.tableCells, 
      FontAwesomeIcons.paintRoller,
      FontAwesomeIcons.trowelBricks,
      FontAwesomeIcons.helmetSafety,
      FontAwesomeIcons.hammer,
      FontAwesomeIcons.rulerCombined,
      FontAwesomeIcons.triangleExclamation,
      FontAwesomeIcons.seedling,
    ];

    return Wrap(
      spacing: 32,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: icons.map((icon) => FaIcon(icon, size: 40, color: Colors.white)).toList(),
    );
  }

  Widget _buildValuesCard(String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
           BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: Offset(0, 5))
         ]
      ),
      child: Column(
        children: [
          Text(
            title,
             style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF152642), // Dark Blue text
            ),
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
