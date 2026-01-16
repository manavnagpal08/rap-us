import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/ai_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/services/pdf_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:rap_app/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final AiService _ai = AiService();
  final DatabaseService _db = DatabaseService();
  final PdfService _pdf = PdfService();

  XFile? _image;
  String? _imageBase64;
  bool _isLoading = false;
  Map<String, dynamic>? _imageAnalysis;
  Map<String, dynamic>? _finalEstimate;

  final TextEditingController _inputController = TextEditingController();
  List<String> _dynamicQuestions = [];
  List<String> _dynamicAnswers = [];
  
  // Stores answers mapped to keys for the AI prompt
  final Map<String, String> _userInput = {
    'dimensions': '',
    'location': '',
    'repairOrBuild': '', // Intent
    'materialQuality': '',
  };

  int _currentStepIndex = -1; // -1: Upload, 0-N: Questions, 99: Result

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selected = await _picker.pickImage(source: source, imageQuality: 50, maxWidth: 800);
    if (selected != null) {
      if (mounted) {
        setState(() {
          _image = selected;
          _isLoading = true;
          _currentStepIndex = -1;
          _dynamicQuestions = [];
          _dynamicAnswers = [];
        });
      }

      final bytes = await selected.readAsBytes();
      _imageBase64 = base64Encode(bytes);

      try {
        final analysis = await _ai.analyzeImage(_imageBase64!);
        
        List<dynamic> questions = analysis['questions'] ?? [];
        String dimensions = analysis['estimated_dimensions'] ?? '';
        
        // If dimensions detected, use them. If not, add question.
        if (dimensions.isNotEmpty && dimensions.toLowerCase() != 'unknown') {
            _userInput['dimensions'] = dimensions;
        } else {
            questions.insert(0, "What are the approximate dimensions?");
        }
        
        // Ensure we have basics if not auto-detected
        if (analysis['object_type'] == null) questions.add("What is this object?");

        if (mounted) {
          setState(() {
            _imageAnalysis = analysis;
            _dynamicQuestions = List<String>.from(questions);
            
            // Standard questions if AI returns none (failsafe)
            if (_dynamicQuestions.isEmpty) {
              _dynamicQuestions = ['What do you want to do (Repair/Build)?', 'Where is this located?', 'Preferred material quality?'];
            }
            
            _isLoading = false;
            _currentStepIndex = 0; 
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
        }
      }
    }
  }

  void _submitAnswer() async {
    if (_inputController.text.isEmpty) return;

    // Save answer
    _dynamicAnswers.add(_inputController.text);
    
    // Manual mapping for core fields if they were asked
    // This is a simplified heuristic since questions are dynamic now
    String currentQ = _dynamicQuestions[_currentStepIndex].toLowerCase();
    String ans = _inputController.text;
    
    if (currentQ.contains('dimension')) _userInput['dimensions'] = ans;
    else if (currentQ.contains('where') || currentQ.contains('location')) _userInput['location'] = ans;
    else if (currentQ.contains('repair') || currentQ.contains('build')) _userInput['repairOrBuild'] = ans;
    else if (currentQ.contains('quality') || currentQ.contains('material')) _userInput['materialQuality'] = ans;

    _inputController.clear();

    if (_currentStepIndex < _dynamicQuestions.length - 1) {
      setState(() => _currentStepIndex++);
    } else {
      // Finalize defaults if missed
      if (_userInput['location']!.isEmpty) _userInput['location'] = 'US';
      if (_userInput['repairOrBuild']!.isEmpty) _userInput['repairOrBuild'] = 'Repair';
      if (_userInput['materialQuality']!.isEmpty) _userInput['materialQuality'] = 'Standard';
      
      _calculateFinalEstimate();
    }
  }

  Future<void> _calculateFinalEstimate() async {
    setState(() {
      _isLoading = true;
      _currentStepIndex = 99; // Result state
    });

    try {
      final estimate = await _ai.getFinalEstimate(
        imageAnalysis: _imageAnalysis!,
        dimensions: _userInput['dimensions']!,
        location: _userInput['location']!,
        repairOrBuild: _userInput['repairOrBuild']!,
        materialQuality: _userInput['materialQuality']!,
      );

      if (_imageBase64 != null) {
        estimate['imageBase64'] = _imageBase64;
      }
      
      // Save only if user is logged in, otherwise just show
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await _db.saveEstimate(estimate);
        } catch (dbError) {
           debugPrint('Firestore save failed: $dbError');
        }
      }

      if (mounted) {
        setState(() {
          _finalEstimate = estimate;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estimation failed: $e')));
      }
    }
  }
  
  void _requireAuth(VoidCallback onSuccess) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      onSuccess();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign in Required'),
          content: const Text('You need to sign in to export or save your estimate.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width > 600 ? 24 : 16, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _buildCurrentState(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCurrentState() {
    if (_currentStepIndex == -1) return _buildUploadSection();
    if (_currentStepIndex >= 0 && _currentStepIndex < 99) return _buildQuestionSection();
    return _buildResultSection();
  }

  Widget _buildUploadSection() {
    return Column(
      key: const ValueKey('upload'),
      children: [
        Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 40 : 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 15)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_a_photo_outlined, size: 40, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 32),
              Text(
                'Start New Estimate',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'Upload an image of what you want to build or repair.\nOur AI will handle the rest.',
                style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).hintColor, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        _buildBenefitGrid(),
      ],
    );
  }

  Widget _buildBenefitGrid() {
    return Row(
      children: [
        _benefitItem(Icons.bolt, 'Instant', 'AI-driven analysis'),
        const SizedBox(width: 24),
        _benefitItem(Icons.verified_outlined, 'Accurate', 'Market price data'),
        const SizedBox(width: 24),
        _benefitItem(Icons.picture_as_pdf_outlined, 'Export', 'PDF ready format'),
      ],
    );
  }

  Widget _benefitItem(IconData icon, String title, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accent, size: 24),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
            Text(sub, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSection() {
    return Column(
      key: const ValueKey('questions'),
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 32 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 15)),
            ],
          ),
          child: Column(
            children: [
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: kIsWeb
                      ? Image.network(_image!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                      : Image.file(File(_image!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 40),
              // Progress Bar
              Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: List.generate(_dynamicQuestions.length, (index) {
                   return Container(
                     width: 40,
                     height: 4,
                     margin: const EdgeInsets.symmetric(horizontal: 4),
                     decoration: BoxDecoration(
                       color: index <= _currentStepIndex ? AppTheme.accent : const Color(0xFFE2E8F0),
                       borderRadius: BorderRadius.circular(2),
                     ),
                   );
                 }),
              ),
              const SizedBox(height: 32),
              Text(
                _dynamicQuestions[_currentStepIndex],
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _inputController,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 18),
                onSubmitted: (_) => _submitAnswer(),
                decoration: const InputDecoration(
                  hintText: 'Type your answer...',
                  contentPadding: EdgeInsets.all(24),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _submitAnswer,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: Text('Continue', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    if (_isLoading) {
      return Column(
        key: const ValueKey('loading'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SpinKitDoubleBounce(color: AppTheme.accent, size: 80),
          const SizedBox(height: 40),
          Text('Generating Estimate...', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const SizedBox(height: 12),
          Text('Our AI is scanning market rates and labor costs...', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
        ],
      );
    }

    if (_finalEstimate == null) return const Text('Error generating estimate.');

    final data = _finalEstimate!;
    return Column(
      key: const ValueKey('result'),
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 15)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show Image 
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: kIsWeb
                        ? Image.network(_image!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                        : Image.file(File(_image!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              Row(
                children: [
                  _buildConfidenceBadge(data['confidence_level']),
                  const SizedBox(width: 12),
                  _buildRiskBadge(data['risk_level'] ?? 'Low'),
                ],
              ),
              const SizedBox(height: 24),
              Text(data['item_summary'], style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 32),
              _buildCostHero(data),
              const SizedBox(height: 40),
              _buildDetailSection('Required Materials', data),
              const SizedBox(height: 32),
              _buildDetailSection('Special Recommendations', data),
              const SizedBox(height: 32),
              _buildGreenAdvantage(data),
              const SizedBox(height: 32),
              _buildRoiInsight(data),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () => _requireAuth(() => _pdf.generateAndPrintEstimate(data, _imageBase64, AppTheme.currencySymbolNotifier.value)),
                        icon: const Icon(Icons.download_rounded, color: Colors.white),
                        label: const Text('Export Report (PDF)'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: OutlinedButton.icon(
                        onPressed: () => _requireAuth(() async {
                          final user = FirebaseAuth.instance.currentUser!;
                          await _db.createJob({
                            'title': data['item_summary'],
                            'customerName': user.displayName ?? 'Customer',
                            'customerId': user.uid,
                            'location': _userInput['location'],
                            'amount': data['total_estimate_range_usd']['likely'],
                            'status': 'pending',
                            'contractorId': null, // Public job
                          });

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posted to Public Job Board!')));
                          }
                        }),
                        icon: const Icon(Icons.rocket_launch_outlined),
                        label: const Text('Post to Board'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: TextButton.icon(
                  onPressed: () {
                    final shareUrl = 'https://rap-us.web.app/estimate/${DateTime.now().millisecondsSinceEpoch}';
                    Share.share('Check out my project estimate from RAP: $shareUrl');
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share Estimate'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostHero(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text('ESTIMATED INVESTMENT', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(
            '\$${data['total_estimate_range_usd']['likely']}',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Expected range: \$${data['total_estimate_range_usd']['low']} — \$${data['total_estimate_range_usd']['high']}',
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
                _costHeroItem('Materials', '\$${data['material_cost_total_usd']}'),
                Container(width: 1, height: 40, color: Colors.white12),
                _costHeroItem('Labor', '\$${data['labor_cost_final_usd']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _costHeroItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildGreenAdvantage(Map<String, dynamic> data) {
    if (data['green_advantage'] == null) return const SizedBox.shrink();
    final green = data['green_advantage'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade500, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.teal.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Green Advantage',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('SAVE \$${green['estimated_annual_savings_usd']}/yr', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            green['sustainable_model'] ?? 'Eco-friendly alternative',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            green['impact_description'] ?? 'Helps reduce environmental footprint.',
            style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRoiInsight(Map<String, dynamic> data) {
    if (data['roi_insight'] == null) return const SizedBox.shrink();
    final roi = data['roi_insight'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.trending_up_rounded, color: AppTheme.accent, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Property Value ROI', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
                const SizedBox(height: 4),
                Text(
                  '+\$${roi['estimated_value_increase_usd']}',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                ),
                Text(
                  'Est. ${roi['roi_percentage']}% recoup cost',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.success, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, Map<String, dynamic> data) {
    Widget content;
    if (title == 'Required Materials') {
        final materials = data['materials'] as List;

        content = Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            columns: [
              DataColumn(label: Text('Item', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Est. Cost', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
            ],
            rows: materials.map<DataRow>((m) => DataRow(
              cells: [
                DataCell(Text(m['name'], style: GoogleFonts.inter(color: const Color(0xFF1E293B)))),
                DataCell(Text('\$${m['estimated_cost_usd']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)))),
              ],
            )).toList(),
          ),
        );
    } else {
        content = Text(data['repair_vs_replace_note'], style: GoogleFonts.inter(color: const Color(0xFF64748B), height: 1.6));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildRiskBadge(String level) {
    Color color = AppTheme.success;
    if (level.toLowerCase() == 'medium') color = AppTheme.warning;
    if (level.toLowerCase() == 'high') color = AppTheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            '${level.toUpperCase()} RISK',
            style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(String level) {
    Color color = AppTheme.success;
    if (level.toLowerCase() == 'medium') color = AppTheme.warning;
    if (level.toLowerCase() == 'low') color = AppTheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(
            '${level.toUpperCase()} CONFIDENCE',
            style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}
