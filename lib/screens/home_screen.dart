import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/ai_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/services/pdf_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
  final List<String> _steps = ['Dimensions', 'Location', 'Intent', 'Quality'];
  int _currentStepIndex = -1; // -1: Upload, 0-3: Questions, 4: Result

  Map<String, String> _userInput = {
    'dimensions': '',
    'location': '',
    'repairOrBuild': '',
    'materialQuality': '',
  };

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (selected != null) {
      setState(() {
        _image = selected;
        _isLoading = true;
        _currentStepIndex = -1;
      });

      final bytes = await selected.readAsBytes();
      _imageBase64 = base64Encode(bytes);

      try {
        final analysis = await _ai.analyzeImage(_imageBase64!);
        setState(() {
          _imageAnalysis = analysis;
          _isLoading = false;
          _currentStepIndex = 0; // Start questions
        });
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
      }
    }
  }

  void _submitAnswer() async {
    if (_inputController.text.isEmpty) return;

    final stepKey = _steps[_currentStepIndex].toLowerCase().replaceAll(' ', '');
    _userInput[stepKey == 'intent' ? 'repairOrBuild' : stepKey == 'quality' ? 'materialQuality' : stepKey] = _inputController.text;
    _inputController.clear();

    if (_currentStepIndex < _steps.length - 1) {
      setState(() => _currentStepIndex++);
    } else {
      _calculateFinalEstimate();
    }
  }

  Future<void> _calculateFinalEstimate() async {
    setState(() {
      _isLoading = true;
      _currentStepIndex = 4; // Result state
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
      
      try {
        await _db.saveEstimate(estimate);
      } catch (dbError) {
        debugPrint('Firestore save failed: $dbError');
      }

      setState(() {
        _finalEstimate = estimate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estimation failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.webBg,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentStepIndex == -1 ? 'Dashboard' : _currentStepIndex < 4 ? 'Analysis' : 'Estimate Details',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              if (_currentStepIndex >= 0 && _currentStepIndex < 4)
                Text('Part of the guided estimation process', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
          if (_currentStepIndex != -1)
            TextButton.icon(
              onPressed: () => setState(() {
                _currentStepIndex = -1;
                _image = null;
                _finalEstimate = null;
              }),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancel Request'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentState() {
    if (_currentStepIndex == -1) return _buildUploadSection();
    if (_currentStepIndex >= 0 && _currentStepIndex < 4) return _buildQuestionSection();
    return _buildResultSection();
  }

  Widget _buildUploadSection() {
    return Column(
      key: const ValueKey('upload'),
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
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_a_photo_outlined, size: 48, color: AppTheme.accent),
              ),
              const SizedBox(height: 32),
              Text(
                'Start New Estimate',
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'Upload an image of what you want to build or repair.\nOur AI will handle the rest.',
                style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF64748B), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 300,
                height: 64,
                child: ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('Choose Image', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accent),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            Text(sub, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
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
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
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
              _buildStepIndicator(),
              const SizedBox(height: 32),
              Text(
                _getQuestionText(),
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _inputController,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 18),
                onSubmitted: (_) => _submitAnswer(),
                decoration: InputDecoration(
                  hintText: 'e.g. ${_getHintText()}',
                  contentPadding: const EdgeInsets.all(24),
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

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps.length, (index) {
        bool isDone = index < _currentStepIndex;
        bool isCurrent = index == _currentStepIndex;
        return Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isDone || isCurrent ? AppTheme.accent : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  String _getQuestionText() {
    switch (_currentStepIndex) {
      case 0: return 'What are the dimensions?';
      case 1: return 'Where is the object located?';
      case 2: return 'Is this a repair or a build?';
      case 3: return 'Which material quality?';
      default: return '';
    }
  }

  String _getHintText() {
    switch (_currentStepIndex) {
      case 0: return '10ft x 12ft';
      case 1: return 'Los Angeles, CA';
      case 2: return 'New custom bookshelf';
      case 3: return 'Premium oak wood';
      default: return 'Type here...';
    }
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
              _buildConfidenceBadge(data['confidence_level']),
              const SizedBox(height: 24),
              Text(data['item_summary'], style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 32),
              _buildCostHero(data),
              const SizedBox(height: 40),
              _buildDetailSection('Required Materials', data),
              const SizedBox(height: 32),
              _buildDetailSection('Special Recommendations', data),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () => _pdf.generateAndPrintEstimate(data, _imageBase64),
                        icon: const Icon(Icons.download_rounded, color: Colors.white),
                        label: const Text('Export Report (PDF)'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: Color(0xFF64748B)),
                      onPressed: () {},
                    ),
                  ),
                ],
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
