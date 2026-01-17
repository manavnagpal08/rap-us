import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:rap_app/theme/app_theme.dart';


class EmergencySOSDialog extends StatefulWidget {
  const EmergencySOSDialog({super.key});

  @override
  State<EmergencySOSDialog> createState() => _EmergencySOSDialogState();
}

class _EmergencySOSDialogState extends State<EmergencySOSDialog> {
  int _state = 0; // 0: Select Type, 1: Broadcasting, 2: Success
  String _selectedType = '';
  Timer? _timer;

  final List<Map<String, dynamic>> _types = [
    {'name': 'Water Leak', 'icon': Icons.water_drop_rounded, 'color': Colors.blue},
    {'name': 'Gas Leak', 'icon': Icons.cloud_circle_rounded, 'color': Colors.orange},
    {'name': 'Electrical', 'icon': Icons.bolt_rounded, 'color': Colors.yellow},
    {'name': 'Structural', 'icon': Icons.house_rounded, 'color': Colors.brown},
    {'name': 'Fire Risk', 'icon': Icons.local_fire_department_rounded, 'color': Colors.red},
  ];

  void _startBroadcast() {
    if (_selectedType.isEmpty) return;
    setState(() => _state = 1);
    
    // Simulate finding a pro
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _state = 2);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine height based on state to ensure smooth transition if possible, 
    // but Dialog size usually adapts.
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.darkTheme.cardColor, // Always dark for dramatic effect
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 5),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_state == 0) return _buildSelection();
    if (_state == 1) return _buildBroadcasting();
    return _buildSuccess();
  }

  Widget _buildSelection() {
    return Column(
      key: const ValueKey('selection'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2)),
        const SizedBox(height: 16),
        Text(
          'EMERGENCY DISPATCH',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        Text(
          'Select the nature of your emergency.',
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _types.map((type) {
            final isSelected = _selectedType == type['name'];
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type['name']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? type['color'] : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type['icon'], color: isSelected ? Colors.white : type['color'], size: 28),
                    const SizedBox(height: 4),
                    Text(
                      type['name'],
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _selectedType.isEmpty ? null : _startBroadcast,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: Colors.white12,
            ),
            child: Text('BROADCAST SOS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildBroadcasting() {
    return Column(
      key: const ValueKey('broadcasting'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SpinKitRipple(color: Colors.red, size: 100),
        const SizedBox(height: 24),
        Text(
          'BROADCASTING URGENT',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Alerting verified pros within 5 miles...',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 24),
        // Simulated "Pro Found" cards appearing can be cool, but keep it simple for now
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
             color: Colors.white.withValues(alpha: 0.05),
             borderRadius: BorderRadius.circular(12)
          ),
          child: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
                const Icon(Icons.radar, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text('Scan active...', style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.bold)),
             ],
          ),
        )
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 40),
        ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
        const SizedBox(height: 24),
        Text(
          'REQUEST SENT!',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Alert sent to all nearby verified pros.\nYou will be notified when someone accepts.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 24),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: GoogleFonts.inter(color: Colors.white54)),
        )
      ],
    );
  }
}
