import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/post_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/nz_components.dart';
import '../books/book_detail_screen.dart';
import '../audio/audio_player_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search books, audio, teachers…',
                prefixIcon: const Icon(Icons.search, color: NZColors.stone),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
        ),
      ),
      body: query.isEmpty
          ? const _SearchPlaceholder()
          : resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (results) => results.isEmpty
                  ? NZEmptyState(
                      icon: Icons.search_off,
                      title: 'No results for "$query"',
                      subtitle: 'Try a different search term',
                    )
                  : _SearchResults(results: results),
            ),
    );
  }
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: NZColors.goldDim, shape: BoxShape.circle),
              child: const Icon(Icons.search, size: 36, color: NZColors.gold),
            ),
            const SizedBox(height: 20),
            Text('Search the Treasury', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Find books, audio teachings, and sacred texts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NZColors.stone),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final List<PostModel> results;
  const _SearchResults({required this.results});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final favIds = ref.watch(favoritesProvider);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox.shrink(),
      itemBuilder: (context, i) {
        final item = results[i];
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AudioPlayerScreen(track: item)),
              );
            },
            isFav: favIds.contains(item.id),
            onFav: () => ref.read(favoritesProvider.notifier).toggle(item.id),
          );
        }

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailScreen(post: item)),
          ),
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
                      Text(item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (item.tibetanTitle != null)
                        Text(item.tibetanTitle!,
                            style: const TextStyle(
                              fontFamily: 'NotoSerifTibetan',
                              fontSize: 12,
                              color: NZColors.stone,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      if (item.displayAuthor.isNotEmpty)
                        Text(item.displayAuthor, style: Theme.of(context).textTheme.labelSmall),
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
