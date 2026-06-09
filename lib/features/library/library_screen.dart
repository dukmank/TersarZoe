import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/post_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/nz_components.dart';
import '../books/book_detail_screen.dart';
import '../audio/audio_player_screen.dart';

enum _LibTab { recent, favorites, downloads, bookmarks }

final _libTabProvider = StateProvider<_LibTab>((ref) => _LibTab.recent);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_libTabProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Library'),
            Text('མཛོད།', style: AppTheme.tibetan(size: 12, color: NZColors.gold.withOpacity(0.8))),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _LibTabBar(current: tab, onSelect: (t) => ref.read(_libTabProvider.notifier).state = t),
        ),
      ),
      body: _LibContent(tab: tab),
    );
  }
}

class _LibTabBar extends StatelessWidget {
  final _LibTab current;
  final ValueChanged<_LibTab> onSelect;

  const _LibTabBar({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (_LibTab.recent, Icons.history, 'Recent'),
      (_LibTab.favorites, Icons.favorite_border, 'Favorites'),
      (_LibTab.downloads, Icons.download_outlined, 'Downloads'),
      (_LibTab.bookmarks, Icons.bookmark_border, 'Bookmarks'),
    ];
    return Row(
      children: tabs.map((t) {
        final active = current == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(t.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? NZColors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.$2, size: 18, color: active ? NZColors.white : NZColors.white.withOpacity(0.5)),
                  const SizedBox(height: 2),
                  Text(t.$3,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? NZColors.white : NZColors.white.withOpacity(0.5),
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LibContent extends ConsumerWidget {
  final _LibTab tab;
  const _LibContent({required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritesProvider);
    final featuredBooksAsync = ref.watch(featuredPostsProvider);
    final featuredAudioAsync = ref.watch(featuredAudioProvider);

    switch (tab) {
      case _LibTab.recent:
        return _RecentTab(
          booksAsync: featuredBooksAsync,
          audioAsync: featuredAudioAsync,
        );

      case _LibTab.favorites:
        if (favIds.isEmpty) {
          return const NZEmptyState(
            icon: Icons.favorite_border,
            title: 'No favorites yet',
            subtitle: 'Tap the heart icon on any book or audio to save it here',
          );
        }
        return featuredBooksAsync.when(
          data: (books) {
            final favBooks = books.where((b) => favIds.contains(b.id)).toList();
            return featuredAudioAsync.when(
              data: (audios) {
                final favAudios = audios.where((a) => favIds.contains(a.id)).toList();
                final all = [...favBooks, ...favAudios];
                return _ItemList(items: all);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _ItemList(items: favBooks),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const NZEmptyState(icon: Icons.error_outline, title: 'Error loading favorites'),
        );

      case _LibTab.downloads:
        return const NZEmptyState(
          icon: Icons.download_outlined,
          title: 'No downloads',
          subtitle: 'Download books and audio for offline access',
        );

      case _LibTab.bookmarks:
        return const NZEmptyState(
          icon: Icons.bookmark_border,
          title: 'No bookmarks',
          subtitle: 'Bookmark pages while reading',
        );
    }
  }
}

class _RecentTab extends ConsumerWidget {
  final AsyncValue<List<PostModel>> booksAsync;
  final AsyncValue<List<PostModel>> audioAsync;

  const _RecentTab({required this.booksAsync, required this.audioAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = booksAsync.asData?.value ?? [];
    final audios = audioAsync.asData?.value ?? [];
    final all = [...books.take(3), ...audios.take(3)];

    if (all.isEmpty) {
      return const NZEmptyState(
        icon: Icons.history,
        title: 'No recent activity',
        subtitle: 'Start reading or listening to see history here',
      );
    }
    return _ItemList(items: all);
  }
}

class _ItemList extends ConsumerWidget {
  final List<PostModel> items;
  const _ItemList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final favIds = ref.watch(favoritesProvider);
    final readingProgress = ref.watch(readingProgressProvider);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      itemBuilder: (context, i) {
        final item = items[i];
        final isAudio = item.contentType == 'audio';

        if (isAudio) {
          return NZAudioRow(
            title: item.title,
            tibetan: item.tibetanTitle,
            artist: item.artist,
            duration: item.durationFormatted,
            accentHex: item.accentColor,
            isCurrent: audioState.currentTrack?.id == item.id,
            isPlaying: audioState.currentTrack?.id == item.id && audioState.isPlaying,
            onTap: () {
              ref.read(audioProvider.notifier).play(item);
              Navigator.push(context, MaterialPageRoute(builder: (_) => AudioPlayerScreen(track: item)));
            },
            isFav: favIds.contains(item.id),
            onFav: () => ref.read(favoritesProvider.notifier).toggle(item.id),
          );
        }

        // Book row
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(post: item))),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: NZColors.border))),
            child: Row(
              children: [
                NZBookCover(
                  title: item.title,
                  tibetan: item.tibetanTitle,
                  thumbnailUrl: item.thumbnail,
                  accentHex: item.accentColor,
                  width: 50,
                  height: 70,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (item.displayAuthor.isNotEmpty)
                        Text(item.displayAuthor, style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 6),
                      if (readingProgress[item.id] != null)
                        NZProgress(value: readingProgress[item.id]!),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: NZColors.stoneLight),
              ],
            ),
          ),
        );
      },
    );
  }
}
