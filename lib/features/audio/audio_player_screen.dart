import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/post_model.dart';
import '../../shared/providers/app_providers.dart';

class AudioPlayerScreen extends ConsumerStatefulWidget {
  final PostModel track;
  const AudioPlayerScreen({super.key, required this.track});

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Start playing when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioProvider.notifier).play(widget.track);
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioProvider);
    final track = audioState.currentTrack ?? widget.track;
    final isFav = ref.watch(favoritesProvider).contains(track.id);

    Color accentColor = NZColors.maroon;
    if (track.accentColor != null) {
      try { accentColor = Color(int.parse(track.accentColor!.replaceFirst('#', '0xFF'))); } catch (_) {}
    }

    final position = audioState.position;
    final duration = audioState.duration;
    final progress = duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(Colors.black26, accentColor),
              NZColors.midnight,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text('Now Playing',
                        style: const TextStyle(color: Colors.white70, fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? NZColors.saffron : Colors.white70),
                      onPressed: () => ref.read(favoritesProvider.notifier).toggle(track.id),
                    ),
                  ],
                ),
              ),

              // ── Cover Art ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accentColor, Color.alphaBlend(Colors.black45, accentColor)],
                        ),
                        boxShadow: [
                          BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 20)),
                        ],
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white38, size: 80),
                    ),
                  ),
                ),
              ),

              // ── Track Info ──
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (track.tibetanTitle != null)
                                Text(track.tibetanTitle!,
                                    style: AppTheme.tibetan(size: 14, color: NZColors.gold)),
                              const SizedBox(height: 4),
                              Text(track.title,
                                  style: const TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.2,
                                  )),
                              if (track.artist != null) ...[
                                const SizedBox(height: 6),
                                Text(track.artist!,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: Colors.white60,
                                    )),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Progress ──
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white24,
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (v) {
                          final ms = (v * duration.inMilliseconds).round();
                          ref.read(audioProvider.notifier).updatePosition(Duration(milliseconds: ms));
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(position), style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Inter')),
                          Text(
                            duration.inSeconds > 0 ? _fmt(duration) : track.durationFormatted,
                            style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Controls ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shuffle, color: Colors.white54, size: 22),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 44),
                          onPressed: () {},
                        ),
                        GestureDetector(
                          onTap: () => ref.read(audioProvider.notifier).togglePlayPause(),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: Icon(
                              audioState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: NZColors.charcoal,
                              size: 40,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 44),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.repeat, color: Colors.white54, size: 22),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
