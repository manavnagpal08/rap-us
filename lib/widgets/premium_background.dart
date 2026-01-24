import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Modern Mesh Gradient Configuration
    // subtle moving blobs
    return Stack(
      children: [
        // Base Color
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        
        // Blob 1 - Top Left (Brand Blue)
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0055FF).withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(1,1), end: const Offset(1.5,1.5), duration: 5.seconds)
           .moveX(begin: 0, end: 50, duration: 4.seconds),
        ),

        // Blob 2 - Center Right (Sky Blue)
        Positioned(
          top: 200,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.1 : 0.05),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 7.seconds)
           .moveY(begin: 0, end: -100, duration: 6.seconds),
        ),

        // Blob 3 - Bottom Left (Deep Indigo / Neutral)
        Positioned(
          bottom: -50,
          left: 0,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.12 : 0.05),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: 50, duration: 8.seconds),
        ),

        // Global Blur to mesh them together
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
        
        // Noise Texture Overlay (Optional, for texture) 
        // Showing subtle static can reduce color banding, but simpler to skip for Flutter Web perf.
      ],
    );
  }
}
