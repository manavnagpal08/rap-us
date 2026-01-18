import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/screens/main_screen.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContractorRegisterScreen extends StatefulWidget {
  const ContractorRegisterScreen({super.key});

  @override
  State<ContractorRegisterScreen> createState() => _ContractorRegisterScreenState();
}

class _ContractorRegisterScreenState extends State<ContractorRegisterScreen> {
  final _businessNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _bioController = TextEditingController();
  
  final DatabaseService _db = DatabaseService();
  bool _isLoading = false;

  void _submit() async {
    if (_businessNameController.text.isEmpty || _categoryController.text.isEmpty || _cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all mandatory fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _db.registerContractor({
        'name': _businessNameController.text.trim(),
        'category': _categoryController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'bio': _bioController.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Become a Pro',
                  style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
                Text(
                  'Complete your business profile to start receiving leads.',
                  style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 48),
                
                  _buildCard([
                    _inputLabel('Business Name'),
                    TextField(controller: _businessNameController, decoration: _inputDecoration('e.g. Precision Carpentry Inc.')),
                    const SizedBox(height: 24),
                    
                    _inputLabel('Trade Category'),
                    TextField(controller: _categoryController, decoration: _inputDecoration('e.g. Plumber, Electrician, General Contractor')),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _inputLabel('City'),
                              TextField(controller: _cityController, decoration: _inputDecoration('e.g. Austin')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _inputLabel('State'),
                              TextField(controller: _stateController, decoration: _inputDecoration('e.g. TX')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _inputLabel('Short Bio / Expertise'),
                    TextField(
                      controller: _bioController, 
                      maxLines: 4,
                      decoration: _inputDecoration('Tell customers about your experience...'),
                    ),
                  ]).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading 
                      ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                      : Text('Complete Registration', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
