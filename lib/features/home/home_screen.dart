import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/post_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/nz_components.dart';
import '../books/book_detail_screen.dart';
import '../audio/audio_player_screen.dart';
import '../../core/utils/r2_helper.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredBooks = ref.watch(featuredPostsProvider);
    final featuredAudio = ref.watch(featuredAudioProvider);
    final audioState = ref.watch(audioProvider);

    return CustomScrollView(
      slivers: [
        // ── Hero ──
        const SliverToBoxAdapter(child: _HeroHeader()),
        // ── Continue Listening ──
        if (audioState.currentTrack != null)
          SliverToBoxAdapter(
            child: _ContinueListening(state: audioState),
          ),
        // ── Featured Books ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: NZSectionHeader(
              title: 'Featured Books',
              tibetan: 'དཔེ་ཆ།',
              action: 'See All',
              onAction: () {},
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: featuredBooks.when(
            data: (books) => _FeaturedBooksRow(books: books),
            loading: () => _booksShimmer(),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error: $e', style: TextStyle(color: Colors.red.shade300)),
            ),
          ),
        ),
        // ── Featured Audio ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: NZSectionHeader(
              title: 'Featured Audio',
              tibetan: 'སྒྲ་དབྱངས།',
              action: 'See All',
              onAction: () {},
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: featuredAudio.when(
            data: (tracks) => _FeaturedAudioList(tracks: tracks),
            loading: () => _audioShimmer(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _booksShimmer() => SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) => const NZShimmer(width: 120, height: 200, radius: 12),
        ),
      );

  Widget _audioShimmer() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(children: [
                NZShimmer(width: 52, height: 52, radius: 10),
                SizedBox(width: 14),
                Expanded(
                  child: Column(children: [
                    NZShimmer(width: double.infinity, height: 14, radius: 4),
                    SizedBox(height: 6),
                    NZShimmer(width: double.infinity, height: 11, radius: 4),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}

// ── Hero Header ──
class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [NZColors.goldDim, Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NZColors.maroon,
              boxShadow: [
                BoxShadow(color: NZColors.maroon.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))
              ],
            ),
            child: const Icon(Icons.menu_book, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 10),
          Text('NamkhaZoe',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(letterSpacing: -0.5, color: NZColors.charcoal)),
          const SizedBox(height: 4),
          Text('༈ ནམ་མཁའ་མཛོད །', style: AppTheme.tibetan(size: 16, color: NZColors.gold)),
          const SizedBox(height: 4),
          Text('Treasury of Vast Wisdom',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: NZColors.stone)),
        ],
      ),
    );
  }
}

// ── Continue Listening ──
class _ContinueListening extends ConsumerWidget {
  final AudioState state;
  const _ContinueListening({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = state.currentTrack!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NZSectionHeader(title: 'Continue Listening'),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AudioPlayerScreen(track: track)),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NZColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: NZColors.maroon,
                    ),
                    child: state.isPlaying
                        ? const Icon(Icons.equalizer, color: Colors.white)
                        : const Icon(Icons.music_note, color: Colors.white70),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (track.tibetanTitle != null)
                          Text(track.tibetanTitle!,
                              style: AppTheme.tibetan(size: 12, color: NZColors.stone),
                              maxLines: 1),
                        if (track.artist != null)
                          Text(track.artist!,
                              style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.read(audioProvider.notifier).togglePlayPause(),
                    icon: Icon(
                      state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: NZColors.saffron,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Featured Books ──
class _FeaturedBooksRow extends StatelessWidget {
  final List<PostModel> books;
  const _FeaturedBooksRow({required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: NZEmptyState(
          icon: Icons.menu_book_outlined,
          title: 'No featured books yet',
          subtitle: 'Mark posts as featured in the admin panel',
        ),
      );
    }
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final b = books[i];
          return NZBookCard(
            title: b.title,
            tibetan: b.tibetanTitle,
            author: b.displayAuthor,
            thumbnailUrl: b.thumbnail != null ? R2Helper.postThumbnail(b.thumbnail!) : null,
            accentHex: b.accentColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookDetailScreen(post: b)),
            ),
          );
        },
      ),
    );
  }
}

// ── Featured Audio ──
class _FeaturedAudioList extends ConsumerWidget {
  final List<PostModel> tracks;
  const _FeaturedAudioList({required this.tracks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tracks.isEmpty) return const SizedBox.shrink();
    final audioState = ref.watch(audioProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: tracks
            .map((t) => NZAudioRow(
                  title: t.title,
                  tibetan: t.tibetanTitle,
                  artist: t.artist,
                  duration: t.durationFormatted,
                  accentHex: t.accentColor,
                  isCurrent: audioState.currentTrack?.id == t.id,
                  isPlaying: audioState.currentTrack?.id == t.id && audioState.isPlaying,
                  onTap: () {
                    ref.read(audioProvider.notifier).play(t);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AudioPlayerScreen(track: t)),
                    );
                  },
                  isFav: ref.watch(favoritesProvider).contains(t.id),
                  onFav: () => ref.read(favoritesProvider.notifier).toggle(t.id),
                ))
            .toList(),
      ),
    );
  }
}
