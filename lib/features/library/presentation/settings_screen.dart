import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Appearance'),
          _buildSwitchTile(
            'Dark Mode',
            'Use dark theme across the app',
            true,
            (v) {},
          ),
          _buildListTile(
            'Theme Color',
            'Deep Purple (Default)',
            Icons.palette_outlined,
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Storage & Data'),
          _buildListTile(
            'Clear Cache',
            'Free up space used by thumbnails',
            Icons.storage_rounded,
          ),
          _buildSwitchTile(
            'Save Metadata',
            'Keep location and date in exported files',
            true,
            (v) {},
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Security'),
          _buildListTile(
            'App Lock',
            'Biometric / PIN',
            Icons.lock_outline_rounded,
          ),
          _buildListTile(
            'Hidden Vault',
            'Managed hidden items',
            Icons.visibility_off_outlined,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildListTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () {},
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
