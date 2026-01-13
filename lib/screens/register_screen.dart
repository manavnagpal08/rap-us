import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/screens/main_screen.dart';
import 'package:rap_app/screens/contractor_register_screen.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isContractor = false;

  void _register() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fillAllFields)));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.register(
        _emailController.text.trim(), 
        _passwordController.text.trim(),
        _nameController.text.trim(),
        role: _isContractor ? 'contractor' : 'user',
      );
      if (mounted) {
        if (_isContractor) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ContractorRegisterScreen()));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // Left Side: Visual/Branding (Only on wide screens)
          if (MediaQuery.of(context).size.width > 1000)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 80),
                      ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 40),
                      Text(
                        'JOIN THE FUTURE',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 16),
                      Text(
                        'PRECISION ESTIMATES IN SECONDS',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          
          // Right Side: Form
          Expanded(
            flex: 2,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMobileLogo(),
                      const SizedBox(height: 48),
                      Text(
                        l10n.signUp,
                        style: GoogleFonts.outfit(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        l10n.signUpSubtitle,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Theme.of(context).hintColor,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),
                      const SizedBox(height: 40),
                      
                      // Name Field
                      _inputLabel(l10n.fullName),
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.inter(),
                        decoration: _inputDecoration('John Doe', Icons.person_outline_rounded),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 20),

                      // Email Field
                      _inputLabel(l10n.emailAddress),
                      TextField(
                        controller: _emailController,
                        style: GoogleFonts.inter(),
                        decoration: _inputDecoration('name@company.com', Icons.alternate_email_rounded),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 20),
                      
                      // Password Field
                      _inputLabel(l10n.password),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: GoogleFonts.inter(),
                        decoration: _inputDecoration('At least 6 characters', Icons.lock_outline_rounded).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: Theme.of(context).hintColor,
                            ),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 20),

                      // Role Selection
                      _inputLabel('I am a...'),
                      Row(
                        children: [
                          _roleChip('Customer', !_isContractor, Icons.person_outline),
                          const SizedBox(width: 12),
                          _roleChip('Contractor', _isContractor, Icons.engineering_outlined),
                        ],
                      ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 32),
                      
                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : Text(l10n.signUp, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        ),
                      ).animate().fadeIn(delay: 800.ms).scale(),
                      
                      const SizedBox(height: 32),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.alreadyHaveAccount,
                            style: GoogleFonts.inter(color: Theme.of(context).hintColor),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              l10n.signIn,
                              style: GoogleFonts.inter(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 900.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLogo() {
    if (MediaQuery.of(context).size.width > 1000) return const SizedBox();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          'RAP',
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }

  Widget _inputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Theme.of(context).hintColor, size: 20),
    );
  }

  Widget _roleChip(String label, bool isSelected, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _isContractor = label == 'Contractor'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Theme.of(context).hintColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
