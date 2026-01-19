import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String type; // 'privacy_policy' or 'terms_conditions'

  const LegalScreen({
    super.key, 
    required this.title, 
    required this.type
  }); // type: privacy_policy, terms_conditions

  static void show(BuildContext context, {required String title, required String type}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        final db = DatabaseService();
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            width: 800,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 20)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<String?>(
                      future: db.getLegalText(type),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final content = snapshot.data ?? "Content not yet available. Please check back later.";
                        return Markdown(
                          data: content,
                          styleSheet: MarkdownStyleSheet(
                            h1: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                            h2: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            p: GoogleFonts.inter(fontSize: 15, height: 1.6),
                          ),
                          padding: const EdgeInsets.all(24),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('I Understand'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: FutureBuilder<String?>(
        future: db.getLegalText(type),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final content = snapshot.data ?? "Content not yet available. Please check back later.";

          return Markdown(
            data: content,
            styleSheet: MarkdownStyleSheet(
              h1: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              h2: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              p: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            padding: const EdgeInsets.all(24),
          );
        },
      ),
    );
  }
}
