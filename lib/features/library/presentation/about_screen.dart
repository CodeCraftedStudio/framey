import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'About Framey',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.photo_library_rounded,
                size: 80,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Framey',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'v1.0.0 (Stable)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 48),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'A premium, on-device media gallery built with Flutter and Native Android. Your moments, beautifully organized.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5),
              ),
            ),
            const Spacer(),
            Text(
              'Made with ❤️ by DeepMind Team',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
