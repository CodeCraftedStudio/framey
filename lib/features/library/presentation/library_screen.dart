import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../videos/presentation/video_screen.dart';
import '../../recycle_bin/presentation/recycle_bin_screen.dart';
import '../../hidden/presentation/hidden_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Library',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildLibraryItem(
            context,
            'Videos',
            'All your movie moments',
            Icons.play_circle_fill_rounded,
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const VideoScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildLibraryItem(
            context,
            'Recycle Bin',
            'Deleted in last 30 days',
            Icons.delete_rounded,
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const RecycleBinScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildLibraryItem(
            context,
            'Hidden Locker',
            'Private and secure',
            Icons.lock_rounded,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const HiddenScreen()),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildLibraryItem(
            context,
            'App Settings',
            'Preferences and storage',
            Icons.settings_suggest_rounded,
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const SettingsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildLibraryItem(
            context,
            'About Framey',
            'Version 1.0.0',
            Icons.info_rounded,
            Colors.grey,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const AboutScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildLibraryItem(
            context,
            'About Developer',
            'Principal Engineering Team',
            Icons.terminal_rounded,
            Colors.blueGrey,
            () => Navigator.pushNamed(context, '/developer'),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
