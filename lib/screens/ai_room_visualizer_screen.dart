import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:rap_app/theme/app_theme.dart';
import 'package:rap_app/widgets/premium_background.dart';

class AiRoomVisualizerScreen extends StatefulWidget {
  const AiRoomVisualizerScreen({super.key});

  @override
  State<AiRoomVisualizerScreen> createState() => _AiRoomVisualizerScreenState();
}

class _AiRoomVisualizerScreenState extends State<AiRoomVisualizerScreen> {
  Uint8List? _originalImage;
  Uint8List? _generatedImage;
  bool _isGenerating = false;
  
  // Configuration State
  String _selectedStyle = 'Modern Minimalist';
  String _selectedRoomType = 'Living Room';
  double _creativityLevel = 0.5;
  
  final List<Map<String, dynamic>> _roomStyles = [
    {'name': 'Modern Minimalist', 'icon': Icons.crop_square_rounded, 'color': Color(0xFFE0E0E0)},
    {'name': 'Rustic Farmhouse', 'icon': Icons.cabin_rounded, 'color': Color(0xFF8D6E63)},
    {'name': 'Industrial Chic', 'icon': Icons.factory_rounded, 'color': Color(0xFF607D8B)},
    {'name': 'Scandanavian', 'icon': Icons.ac_unit_rounded, 'color': Color(0xFFB2DFDB)},
    {'name': 'Cyberpunk', 'icon': Icons.games_rounded, 'color': Color(0xFFE040FB)},
    {'name': 'Bohemian', 'icon': Icons.nature_people_rounded, 'color': Color(0xFFFFAB40)},
  ];

  final List<String> _roomTypes = [
    'Living Room', 'Bedroom', 'Kitchen', 'Bathroom', 'Office', 'Dining Room', 'Outdoor'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Source', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(Icons.camera_alt_rounded, 'Camera', () async {
                  Navigator.pop(ctx);
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) _setImage(await pickedFile.readAsBytes());
                }),
                _buildSourceOption(Icons.photo_library_rounded, 'Gallery', () async {
                  Navigator.pop(ctx);
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) _setImage(await pickedFile.readAsBytes());
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _setImage(Uint8List image) {
    setState(() {
      _originalImage = image;
      _generatedImage = null;
    });
  }

  Widget _buildSourceOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.accent),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _generateDesign() async {
    if (_originalImage == null) return;
    
    setState(() => _isGenerating = true);
    
    // Simulate AI Processing
    await Future.delayed(const Duration(seconds: 4));
    
    setState(() {
      _generatedImage = _originalImage; 
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('AI Room Reimaginer', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          if (_generatedImage != null)
             IconButton(
               onPressed: () => setState(() => _generatedImage = null),
               icon: const Icon(Icons.refresh_rounded, color: Colors.white),
             ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          if (_originalImage == null)
            _buildEmptyState()
          else if (_isGenerating)
            _buildLoadingState()
          else if (_generatedImage != null)
            _buildResultState()
          else
            _buildEditorState(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Stack(
      children: [
        const PremiumBackground(),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Icon(Icons.auto_fix_high_rounded, size: 48, color: AppTheme.accent).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1,1.1)),
                ),
                const SizedBox(height: 32),
                Text(
                  'Reimagine Your Room',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                ).animate().fadeIn().slideY(),
                const SizedBox(height: 16),
                Text(
                  'Take a photo of your room and let our AI redesign it in seconds.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).hintColor),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Capture Room'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppTheme.accent.withValues(alpha: 0.5),
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

  Widget _buildEditorState() {
    return Stack(
      children: [
        // Image Preview
        Positioned.fill(
          bottom: 300, 
          child: Image.memory(_originalImage!, fit: BoxFit.cover),
        ),
        
        // Gradient overlay for better UI visibility
        Positioned(
          top: 0, left: 0, right: 0, height: 120,
          child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
        ),

        // Controls Bottom Sheet
        Positioned(
          left: 0, right: 0, bottom: 0,
          height: 450,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40)],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('Customize Redesign', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                
                // Room Type Selector
                Text('Room Type', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _roomTypes.length,
                    itemBuilder: (context, index) {
                      final type = _roomTypes[index];
                      final isSelected = type == _selectedRoomType;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(type),
                          onSelected: (v) => setState(() => _selectedRoomType = type),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          selectedColor: AppTheme.accent,
                          checkmarkColor: Colors.white,
                          labelStyle: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.white70),
                          side: const BorderSide(color: Colors.transparent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Style Selector
                Text('Design Style', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _roomStyles.length,
                    itemBuilder: (context, index) {
                      final style = _roomStyles[index];
                      final isSelected = style['name'] == _selectedStyle;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedStyle = style['name']),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? style['color'] : (style['color'] as Color).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(style['icon'], color: isSelected ? Colors.black : Colors.white),
                              const SizedBox(height: 8),
                              Text(
                                style['name'].toString().split(' ')[0], 
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
                
                // Creativity Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('AI Creativity', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                    Text('${(_creativityLevel * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                  ],
                ),
                Slider(
                  value: _creativityLevel,
                  onChanged: (v) => setState(() => _creativityLevel = v),
                  activeColor: AppTheme.accent,
                  inactiveColor: Colors.white.withValues(alpha: 0.1),
                ),
                
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _generateDesign,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Generate Preview', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOutQuint),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Stack(
      children: [
        Positioned.fill(child: Image.memory(_originalImage!, fit: BoxFit.cover)),
        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.8))),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100, height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(width: 100, height: 100, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.accent), strokeWidth: 2)),
                    Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 40).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: Offset(1,1), end: Offset(1.2,1.2)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Reimagining your room...', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Applying $_selectedStyle style\nOptimizing for $_selectedRoomType layout', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultState() {
    return _AdvancedComparisonView(
      original: _originalImage!,
      generated: _generatedImage!, // In a real app, this would be the AI output
      style: _selectedStyle,
    );
  }
}

class _AdvancedComparisonView extends StatefulWidget {
  final Uint8List original;
  final Uint8List generated;
  final String style;
  
  const _AdvancedComparisonView({required this.original, required this.generated, required this.style});

  @override
  State<_AdvancedComparisonView> createState() => _AdvancedComparisonViewState();
}

class _AdvancedComparisonViewState extends State<_AdvancedComparisonView> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Image.memory(widget.original, fit: BoxFit.cover)),
        Positioned.fill(
          child: ClipRect(
            clipper: _SliderClipper(_sliderValue),
            child: ColorFiltered( // MOCK EFFECT for demo
              colorFilter: const ColorFilter.mode(Colors.purpleAccent, BlendMode.hue), 
              child: Image.memory(widget.generated, fit: BoxFit.cover),
            ),
          ),
        ),
        _buildSliderHandle(),
        
        // Bottom Tools
        Positioned(
          bottom: 40, left: 24, right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
               _actionButton(Icons.share_rounded, 'Share', () {}),
               _actionButton(Icons.download_rounded, 'Save', () {}),
               _actionButton(Icons.shopping_bag_outlined, 'Shop Items', () {}),
            ],
          ).animate().slideY(begin: 1, curve: Curves.easeOutBack),
        ),
      ],
    );
  }
  
  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
            child: Icon(icon, color: Colors.black),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
      ],
    );
  }

  Widget _buildSliderHandle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              left: constraints.maxWidth * _sliderValue - 2,
              top: 0, bottom: 0,
              child: Container(width: 4, color: Colors.white),
            ),
            Positioned(
              left: constraints.maxWidth * _sliderValue - 24,
              top: constraints.maxHeight / 2 - 24,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() => _sliderValue = (_sliderValue + d.delta.dx / constraints.maxWidth).clamp(0.0, 1.0)),
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8)],
                  ),
                  child: const Icon(Icons.compare_arrows_rounded),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double value;
  _SliderClipper(this.value);

  @override
  Rect getClip(Size size) => Rect.fromLTRB(size.width * value, 0, size.width, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => true;
}
