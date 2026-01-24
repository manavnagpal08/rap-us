import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/widgets/premium_background.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/screens/login_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  final String message;
  final bool allowFeedback;

  const MaintenanceScreen({
    super.key,
    required this.message,
    this.allowFeedback = true,
  });

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;

  void _submitFeedback() async {
    if (_feedbackController.text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await DatabaseService().submitMaintenanceFeedback({
        'message': _feedbackController.text.trim(),
        'email': _emailController.text.trim(),
        'type': 'maintenance_mode',
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you! Your feedback has been received.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Submit Feedback', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (Optional)',
                hintText: 'Enter your email for updates',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Feedback',
                hintText: 'Tell us your thoughts or report an issue...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitFeedback,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  int _secretTapCount = 0;

  void _handleSecretTap() {
    setState(() => _secretTapCount++);
    if (_secretTapCount >= 7) {
      _secretTapCount = 0;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const PremiumBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _handleSecretTap,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.engineering_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2000.ms),
                    const SizedBox(height: 48),
                    Text(
                      'Systems Update',
                      style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 18, color: Theme.of(context).hintColor, height: 1.5),
                    ),
                    const SizedBox(height: 48),
                    if (widget.allowFeedback)
                      ElevatedButton.icon(
                        onPressed: _showFeedbackDialog,
                        icon: const Icon(Icons.feedback_outlined),
                        label: const Text('Leave Feedback'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                    const SizedBox(height: 48),
                    Text(
                      'RAP Precision © 2026',
                      style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
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
}
