import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentationScreen extends StatelessWidget {
  const DocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Documentation', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Markdown(
        data: """
# Welcome to RAP Documentation

RAP (Repair & Assembly Platform) is an AI-powered marketplace for home repairs and construction projects.

## Getting Started

### 1. Create an Estimate
Go to the **New Estimate** tab and upload a clear photo of your project. Our AI will analyze the dimensions, materials, and complexity to provide a cost range.

### 2. Hire a Pro
Browse the **Marketplace** to find verified local contractors. You can view their profiles, view past projects, and message them directly.

### 3. Track your Project
Once a job starts, use the **Project Hub** to see real-time logic logs, photos, and estimated completion dates.

## Cost Estimation
Our costs are calculated using US-based averages.
- **Labor Discount**: We automatically apply a 20% discount to all labor estimates.
- **ROI Insight**: We estimate how much value a project adds to your property.
- **Green Advantage**: We suggest sustainable material alternatives.

## Security
- **Biometrics**: Secure your account with FaceID or TouchID.
- **2FA**: Enable Two-Factor Authentication for sensitive actions.
- **Verification**: Contractors undergo document review before receiving the 'Verified' badge.

---
© 2026 RAP US Technologies.
""",
      ),
    );
  }
}
