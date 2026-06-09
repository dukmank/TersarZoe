import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // ── Profile section ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NZColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: NZColors.maroon,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guest', style: Theme.of(context).textTheme.headlineSmall),
                    Text('Sign in for personalized experience',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Section: Content ──
          _SectionLabel(label: 'Content'),
          _MenuItem(
            icon: Icons.announcement_outlined,
            label: 'Announcements',
            tibetan: 'གསར་འགྱུར།',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            tibetan: 'རི་མོ།',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.search,
            label: 'Search',
            onTap: () {},
          ),
          const SizedBox(height: 20),

          // ── Section: App ──
          _SectionLabel(label: 'App'),
          _MenuItem(
            icon: Icons.dark_mode_outlined,
            label: 'Appearance',
            trailing: const Text('Light', style: TextStyle(color: NZColors.stone, fontSize: 13, fontFamily: 'Inter')),
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.language,
            label: 'Language',
            trailing: const Text('English', style: TextStyle(color: NZColors.stone, fontSize: 13, fontFamily: 'Inter')),
            onTap: () {},
          ),
          const SizedBox(height: 20),

          // ── Section: About ──
          _SectionLabel(label: 'About'),
          _MenuItem(
            icon: Icons.info_outline,
            label: 'About NamkhaZoe',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.mail_outline,
            label: 'Contact Us',
            onTap: () {},
          ),
          const SizedBox(height: 32),

          // ── App version ──
          Center(
            child: Column(
              children: [
                Text('༈ ནམ་མཁའ་མཛོད །',
                    style: AppTheme.tibetan(size: 14, color: NZColors.gold)),
                const SizedBox(height: 4),
                Text('NamkhaZoe v1.0.0',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: NZColors.stone,
            letterSpacing: 1.2,
          )),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? tibetan;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({required this.icon, required this.label, this.tibetan, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: NZColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: NZColors.goldDim,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: NZColors.maroon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  if (tibetan != null)
                    Text(tibetan!, style: AppTheme.tibetan(size: 12, color: NZColors.stone)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: NZColors.stoneLight, size: 20),
          ],
        ),
      ),
    );
  }
}
