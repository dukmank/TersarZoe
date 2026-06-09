import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/post_model.dart';
import '../services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());

// ── Categories ──
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.read(supabaseServiceProvider).getCategories();
});

// ── Featured posts (is_featured = true) ──
final featuredPostsProvider = FutureProvider<List<PostModel>>((ref) async {
  return ref.read(supabaseServiceProvider).getFeaturedPosts();
});

// ── Featured audio ──
final featuredAudioProvider = FutureProvider<List<PostModel>>((ref) async {
  return ref.read(supabaseServiceProvider).getFeaturedAudio();
});

// ── Announcements ──
final announcementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(supabaseServiceProvider).getAnnouncements();
});

// ── Search query ──
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  final q = ref.watch(searchQueryProvider);
  if (q.trim().isEmpty) return [];
  return ref.read(supabaseServiceProvider).searchPosts(q);
});

// ── Current audio playback state ──
class AudioState {
  final PostModel? currentTrack;
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  const AudioState({
    this.currentTrack,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  AudioState copyWith({PostModel? currentTrack, bool? isPlaying, Duration? position, Duration? duration}) =>
      AudioState(
        currentTrack: currentTrack ?? this.currentTrack,
        isPlaying: isPlaying ?? this.isPlaying,
        position: position ?? this.position,
        duration: duration ?? this.duration,
      );
}

class AudioNotifier extends StateNotifier<AudioState> {
  AudioNotifier() : super(const AudioState());

  void play(PostModel track) => state = state.copyWith(currentTrack: track, isPlaying: true);
  void pause() => state = state.copyWith(isPlaying: false);
  void resume() => state = state.copyWith(isPlaying: true);
  void togglePlayPause() => state = state.copyWith(isPlaying: !state.isPlaying);
  void updatePosition(Duration pos) => state = state.copyWith(position: pos);
  void updateDuration(Duration dur) => state = state.copyWith(duration: dur);
  void stop() => state = const AudioState();
}

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) => AudioNotifier());

// ── Reading progress: postId → percent 0.0-1.0 ──
class ReadingProgressNotifier extends StateNotifier<Map<int, double>> {
  ReadingProgressNotifier() : super({});

  void update(int postId, double percent) => state = {...state, postId: percent};
}

final readingProgressProvider = StateNotifierProvider<ReadingProgressNotifier, Map<int, double>>(
  (ref) => ReadingProgressNotifier(),
);

// ── Favorites set ──
class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier() : super({});

  void toggle(int id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }

  bool contains(int id) => state.contains(id);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>(
  (ref) => FavoritesNotifier(),
);
