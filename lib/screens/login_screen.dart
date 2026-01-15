import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/screens/main_screen.dart';
import 'package:rap_app/screens/register_screen.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/security_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  final SecurityService _security = SecurityService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fillAllFields)));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final credential = await _auth.login(email, password);
      if (credential != null && mounted) {
        // Securely store for biometrics
        await _storage.write(key: 'email', value: email);
        await _storage.write(key: 'password', value: password);
        
        final profile = await _db.getUserProfile(credential.user!.uid);
        if (profile != null && profile['is2FAEnabled'] == true) {
          _showOtpDialog(profile['totpSecret']);
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

  void _showOtpDialog(String secret) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 6-digit code from your authenticator app.'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: const InputDecoration(counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () async {
            await _auth.signOut();
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_security.verifyTotp(secret, otpController.text)) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP code'), backgroundColor: AppTheme.error));
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _biometricLogin() async {
    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');

    if (email == null || password == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login with password once to enable biometrics.')));
      }
      return;
    }

    final authenticated = await _security.authenticateBiometrics();
    if (authenticated) {
      if (mounted) setState(() => _isLoading = true);
      try {
        await _auth.login(email, password);
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Biometric Login Failed: $e'), backgroundColor: AppTheme.error));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
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
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 80),
                      ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 40),
                      Text(
                        'RAP PRECISION',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 16),
                      Text(
                        l10n.newStandard,
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
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMobileLogo(),
                      const SizedBox(height: 48),
                      Text(
                        l10n.signIn,
                        style: GoogleFonts.outfit(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.signInSubtitle,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Email Field
                      _inputLabel(l10n.emailAddress),
                      TextField(
                        controller: _emailController,
                        style: GoogleFonts.inter(),
                        decoration: _inputDecoration('name@company.com', Icons.alternate_email_rounded),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Password Field
                      _inputLabel(l10n.password),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: GoogleFonts.inter(),
                        decoration: _inputDecoration('••••••••', Icons.lock_outline_rounded).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: Theme.of(context).hintColor,
                            ),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            l10n.forgotPassword,
                            style: GoogleFonts.inter(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                      
                      const SizedBox(height: 32),
                      
                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading 
                            ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                            : Text(l10n.signIn, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        ),
                      ).animate().fadeIn(delay: 700.ms).scale(),
                      
                      const SizedBox(height: 24),
                      
                      // Google Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _googleSignIn,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).dividerColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.g_mobiledata, size: 30, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              Text(
                                l10n.continueWithGoogle,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 800.ms).scale(),
                      
                      const SizedBox(height: 16),
                      
                      // Biometric Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _biometricLogin,
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: const Text('Login with Biometrics'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).dividerColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ).animate().fadeIn(delay: 850.ms).scale(),
                      
                      const SizedBox(height: 48),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.dontHaveAccount,
                            style: GoogleFonts.inter(color: Theme.of(context).hintColor),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: Text(
                              l10n.createAccount,
                              style: GoogleFonts.inter(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 900.ms),
                    ].animate(interval: 50.ms).fadeIn().slideY(begin: 0.1, end: 0),
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
}
