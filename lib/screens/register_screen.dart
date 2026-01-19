import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/screens/main_screen.dart';
import 'package:rap_app/screens/contractor_register_screen.dart';
import 'package:rap_app/screens/legal_screen.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

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
  File? _selectedImage;

  String? _base64Image;
  bool _acceptedTerms = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compress to avoid huge strings
      maxWidth: 800,
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      setState(() {
        _selectedImage = File(image.path);
        _base64Image = base64String;
      });
    }
  }

  void _register() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fillAllFields)));
      return;
    }
    
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the Terms & Conditions and Privacy Policy to continue.'), backgroundColor: AppTheme.error));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.register(
        _emailController.text.trim(), 
        _passwordController.text.trim(),
        _nameController.text.trim(),
        role: _isContractor ? 'contractor' : 'user',
        photoBase64: _base64Image,
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
    final isWide = MediaQuery.of(context).size.width > 1000;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // Left Side: Visual/Branding (Only on wide screens)
          if (isWide)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Stack(
                  children: [
                    // Abstract shapes
                    Positioned(
                      top: -100, right: -100,
                      child: Container(
                        width: 400, height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50, left: -50,
                      child: Container(
                        width: 300, height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10)),
                              ],
                            ),
                            child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 80),
                          ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
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
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4,
                            ),
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
                        ],
                      ),
                    ),
                  ],
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
                      if (!isWide) _buildMobileLogo(),
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
                      
                      // Profile Picture Upload
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 120, height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                                  image: _selectedImage != null 
                                    ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                                    : null,
                                ),
                                child: _selectedImage == null 
                                  ? Icon(Icons.add_a_photo_rounded, size: 40, color: Theme.of(context).primaryColor)
                                  : null,
                              ).animate().scale(delay: 350.ms),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

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
                      

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _acceptedTerms,
                              onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                              activeColor: Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              children: [
                                Text('I agree to the ', style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => LegalScreen.show(context, title: 'Terms & Conditions', type: 'terms_conditions'),
                                  child: Text('Terms & Conditions', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                                Text(' and ', style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => LegalScreen.show(context, title: 'Privacy Policy', type: 'privacy_policy'),
                                  child: Text('Privacy Policy', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                                Text('.', style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 750.ms),
                      const SizedBox(height: 32),
                      
                      // Sign Up Button
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                             BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
          color: Colors.transparent, // Removed background color for image
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset('assets/images/logo.png', width: 50, height: 50),
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
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }

  Widget _roleChip(String label, bool isSelected, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _isContractor = label == 'Contractor'),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
            ),
            boxShadow: isSelected ? [
              BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Theme.of(context).hintColor, size: 20),
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
