import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../shared/providers/app_providers.dart';
import '../shared/widgets/nz_components.dart';
import 'home/home_screen.dart';
import 'books/books_screen.dart';
import 'library/library_screen.dart';
import 'more/more_screen.dart';

// ── Tab index provider ──
final _tabIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _tabs = [
    _TabDef(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _TabDef(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Books'),
    _TabDef(icon: Icons.bookmarks_outlined, activeIcon: Icons.bookmarks, label: 'Library'),
    _TabDef(icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'More'),
  ];

  static const _screens = [
    HomeScreen(),
    BooksScreen(),
    LibraryScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(_tabIndexProvider);
    final audioState = ref.watch(audioProvider);

    return Scaffold(
      // Each screen is a scrollable body — no AppBar at shell level
      body: IndexedStack(index: idx, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini Player (persists above tab bar)
          if (audioState.currentTrack != null)
            NZMiniPlayer(
              title: audioState.currentTrack!.title,
              artist: audioState.currentTrack!.artist,
              accentHex: audioState.currentTrack!.accentColor,
              isPlaying: audioState.isPlaying,
              onPlayPause: () => ref.read(audioProvider.notifier).togglePlayPause(),
            ),
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: const Border(top: BorderSide(color: NZColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: _tabs.asMap().entries.map((e) {
                    final i = e.key;
                    final tab = e.value;
                    final active = idx == i;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => ref.read(_tabIndexProvider.notifier).state = i,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  active ? tab.activeIcon : tab.icon,
                                  key: ValueKey(active),
                                  size: 24,
                                  color: active ? NZColors.maroon : NZColors.stone,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tab.label,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                  color: active ? NZColors.maroon : NZColors.stone,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabDef({required this.icon, required this.activeIcon, required this.label});
}
