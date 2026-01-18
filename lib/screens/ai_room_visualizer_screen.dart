import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/widgets/premium_background.dart';

class AiRoomVisualizerScreen extends StatefulWidget {
  const AiRoomVisualizerScreen({super.key});

  @override
  State<AiRoomVisualizerScreen> createState() => _AiRoomVisualizerScreenState();
}

class _AiRoomVisualizerScreenState extends State<AiRoomVisualizerScreen> {
  File? _originalImage;
  File? _generatedImage;
  bool _isGenerating = false;
  double _sliderValue = 0.5;
  String _selectedStyle = 'Modern Minimalist';

  final List<Map<String, String>> _roomStyles = [
    {'name': 'Modern Minimalist', 'desc': 'Clean lines, neutral colors, open space'},
    {'name': 'Rustic Farmhouse', 'desc': 'Warm wood tones, vintage accents, cozy'},
    {'name': 'Industrial Chic', 'desc': 'Exposed brick, metal accents, raw textures'},
    {'name': 'Scandanavian', 'desc': 'Light wood, white walls, functional simplicity'},
    {'name': 'Cyberpunk', 'desc': 'Neon lights, futuristic tech, bold contrasts'},
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera); // Or gallery
    if (pickedFile != null) {
      setState(() {
        _originalImage = File(pickedFile.path);
        _generatedImage = null; // Reset previous generation
      });
    }
  }

  Future<void> _generateDesign() async {
    if (_originalImage == null) return;
    
    setState(() => _isGenerating = true);
    
    // Simulate AI Processing time
    await Future.delayed(const Duration(seconds: 4));
    
    // MOCK: For now, we will just use the same image but assume the "generated" one 
    // would be returned from an API. In a real app, this would be the URL or bytes.
    // To make the visualizer work for demo, we'll just use the same image but maybe filter it or 
    // ideally use a placeholder "after" image if available, or just demonstrate the UI flow.
    // For this demo, let's pretend the 'original' is the 'generated' one for UI logic, 
    // but in reality we'd swap them.
    
    setState(() {
      _generatedImage = _originalImage; // In real app: File(path_to_generated_image)
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('AI Room Reimaginer', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background
          Container(color: Colors.black),
          
          if (_originalImage == null)
            _buildIntroUI()
          else if (_isGenerating)
            _buildLoadingUI()
          else if (_generatedImage != null)
            _buildComparisonUI() // The "After" state
          else
            _buildStyleSelectionUI(), // The "Before" state logic
            
        ],
      ),
    );
  }

  Widget _buildIntroUI() {
    return Stack(
      children: [
        const PremiumBackground(),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_fix_high_rounded, size: 80, color: AppTheme.accent).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1,1.1)),
                const SizedBox(height: 32),
                Text(
                  'Reimagine Your Room',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ).animate().fadeIn().slideY(),
                const SizedBox(height: 16),
                Text(
                  'Take a photo of your room and let our AI redesign it in seconds.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Capture Room'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyleSelectionUI() {
    return Stack(
      children: [
        // Background Image (The captured photo)
        Positioned.fill(
          child: Image.file(_originalImage!, fit: BoxFit.cover),
        ),
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        
        // UI Controls
        SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Text('Select a Style', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _roomStyles.length,
                  itemBuilder: (context, index) {
                    final style = _roomStyles[index];
                    final isSelected = _selectedStyle == style['name'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedStyle = style['name']!),
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.accent : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? AppTheme.accent : Colors.white.withOpacity(0.2)),
                          boxShadow: isSelected ? [BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 16)] : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: Icon(Icons.palette_outlined, color: Colors.white, size: 20),
                            ),
                            const Spacer(),
                            Text(style['name']!, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(style['desc']!, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: SizedBox(
                   width: double.infinity,
                   height: 56,
                   child: ElevatedButton(
                     onPressed: _generateDesign,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.white,
                       foregroundColor: Colors.black,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     ),
                     child: const Text('Generate Design ✨', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingUI() {
    return Stack(
      children: [
        Positioned.fill(child: Image.file(_originalImage!, fit: BoxFit.cover)),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.7))),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 6),
              ),
              const SizedBox(height: 32),
              Text('Dreaming up your new $_selectedStyle room...', 
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms),
              const SizedBox(height: 16),
              const Text('Identifying furniture structures...\nApplying lighting models...', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonUI() {
    return Stack(
      children: [
        // Base Layer: Original Image
        Positioned.fill(child: Image.file(_originalImage!, fit: BoxFit.cover)),
        
        // Top Layer: Generated Image (Clipped by slider)
        Positioned.fill(
          child: ClipRect(
            clipper: _SliderClipper(_sliderValue),
            child: ColorFiltered( // MOCK EFFECT: Just invert/sepia to show "diff" since we don't have real AI yet
               colorFilter: const ColorFilter.mode(Colors.deepOrange, BlendMode.hue), // Dramatic tint to simulate change
               child: Image.file(_generatedImage!, fit: BoxFit.cover),
            ),
          ),
        ),
        
        // Slider Handle
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  Positioned(
                    left: width * _sliderValue - 2, // Center line
                    top: 0, bottom: 0,
                    child: Container(width: 4, color: Colors.white),
                  ),
                  Positioned(
                    left: width * _sliderValue - 24, // Handle
                    top: constraints.maxHeight / 2 - 24,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _sliderValue += details.delta.dx / width;
                          _sliderValue = _sliderValue.clamp(0.0, 1.0);
                        });
                      },
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                        ),
                        child: const Icon(Icons.compare_arrows_rounded, color: Colors.black),
                      ),
                    ),
                  ),
                  // Labels
                  Positioned(bottom: 40, left: 20, child: _labelBadge('BEFORE')),
                  Positioned(bottom: 40, right: 20, child: _labelBadge('AFTER ($_selectedStyle)')),
                  
                  // Reset / Save Buttons
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton.filled(
                              onPressed: () => setState(() { _generatedImage = null; }),
                              icon: const Icon(Icons.refresh),
                              style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                               onPressed: (){}, // TODO: Save to gallery
                               icon: const Icon(Icons.download_rounded),
                               label: const Text('Save'),
                               style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _labelBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double value;
  _SliderClipper(this.value);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(size.width * value, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => true;
}
