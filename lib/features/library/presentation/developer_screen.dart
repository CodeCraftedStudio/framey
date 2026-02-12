import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (!await launchUrl(uri)) throw Exception('Could not launch $uri');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Profile Summary', colorScheme),
                  _buildProfileCard(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Education', colorScheme),
                  _buildEducationTimeline(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Skills & Interests', colorScheme),
                  _buildSkillsGrid(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Personal Traits', colorScheme),
                  _buildTraitsList(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Notable Practices', colorScheme),
                  _buildPracticesList(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Connect', colorScheme),
                  _buildConnectSection(context),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      centerTitle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Text(
        'Developer',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Hero(
            tag: 'dev_avatar',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://api.dicebear.com/7.x/avataaars/svg?seed=Abir',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Abir Hasan Siam',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Flutter & Android Developer',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Detail-oriented Developer passionate about creating beautiful & efficient mobile experiences.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            Icons.cake_rounded,
            'Date of Birth',
            '17 November 2002',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            context,
            Icons.hourglass_empty_rounded,
            'Age',
            '22 Years',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            context,
            Icons.location_on_rounded,
            'Location',
            'Gazipur, Dhaka, BD',
          ),
          const Divider(height: 24),
          _buildInfoRow(context, Icons.home_work_rounded, 'Origin', 'Tangail'),
          const Divider(height: 24),
          _buildInfoRow(context, Icons.bloodtype_rounded, 'Blood Group', 'B+'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEducationTimeline(BuildContext context) {
    return Column(
      children: [
        _buildEduItem(
          context,
          'Independent University of Bangladesh',
          'BSc in Computer Science',
          '2021 - Present',
          true,
        ),
        _buildEduItem(
          context,
          'Misir Ali Khan Memorial School & College',
          'Higher Secondary Certificate (HSC)',
          '2019 - 2020',
          true,
        ),
        _buildEduItem(
          context,
          'Professor MEH Arif Secondary School',
          'Secondary School Certificate (SSC)',
          '2017 - 2018',
          false,
        ),
      ],
    );
  }

  Widget _buildEduItem(
    BuildContext context,
    String school,
    String degree,
    String year,
    bool hasNext,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    width: 4,
                  ),
                ),
              ),
              if (hasNext)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  degree,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  year,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsGrid(BuildContext context) {
    final skills = [
      {'name': 'Dart (Flutter)', 'icon': Icons.bolt_rounded},
      {'name': 'React', 'icon': Icons.code_rounded},
      {'name': 'Python', 'icon': Icons.terminal_rounded},
      {'name': 'Android APK', 'icon': Icons.android_rounded},
      {'name': 'Web Dev', 'icon': Icons.web_rounded},
      {'name': 'Git/GitHub', 'icon': Icons.hub_rounded},
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                skill['icon'] as IconData,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                skill['name'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTraitsList(BuildContext context) {
    final traits = [
      'Detail-oriented and curious',
      'Enjoys experimenting with cross-platform solutions',
      'Likes to keep projects clean, optimized, and professional',
    ];
    return Column(
      children: traits.map((trait) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trait,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPracticesList(BuildContext context) {
    final practices = [
      'Maintains clean Flutter project structure',
      'Prefers step-by-step technical clarity',
      'Strong focus on first-time app launch experience',
      'Considers multi-OS compatibility in development',
    ];
    return Column(
      children: practices.map((practice) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_outline_rounded, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  practice,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConnectSection(BuildContext context) {
    return Column(
      children: [
        _buildSocialTile(
          context,
          'GitHub',
          'github.com/abir2afridi',
          Icons.code_rounded,
          () => _launchUrl('https://github.com/abir2afridi'),
        ),
        _buildSocialTile(
          context,
          'Portfolio',
          'abir2afridi.vercel.app',
          Icons.language_rounded,
          () => _launchUrl('https://abir2afridi.vercel.app/'),
        ),
        _buildSocialTile(
          context,
          'Email',
          'abir2afridi@gmail.com',
          Icons.mail_outline_rounded,
          () => _launchUrl('mailto:abir2afridi@gmail.com'),
        ),
      ],
    );
  }

  Widget _buildSocialTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        trailing: const Icon(Icons.open_in_new_rounded, size: 16),
      ),
    );
  }
}
