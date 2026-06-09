import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────
// NZSection Header  (title + optional tibetan + "See All")
// ─────────────────────────────────────────────
class NZSectionHeader extends StatelessWidget {
  final String title;
  final String? tibetan;
  final String? action;
  final VoidCallback? onAction;

  const NZSectionHeader({
    super.key,
    required this.title,
    this.tibetan,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: NZColors.charcoal,
                  )),
          if (tibetan != null) ...[
            const SizedBox(width: 8),
            Text(tibetan!, style: AppTheme.tibetan(size: 13, color: NZColors.gold)),
          ],
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: NZColors.saffron,
                  )),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NZProgress bar
// ─────────────────────────────────────────────
class NZProgress extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final double height;

  const NZProgress({super.key, required this.value, this.height = 3});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: NZColors.creamDark,
        valueColor: const AlwaysStoppedAnimation(NZColors.saffron),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BookCover  — solid-color spine with title
// ─────────────────────────────────────────────
class NZBookCover extends StatelessWidget {
  final String title;
  final String? tibetan;
  final String? thumbnailUrl;
  final String? accentHex;
  final double width;
  final double height;
  final double radius;

  const NZBookCover({
    super.key,
    required this.title,
    this.tibetan,
    this.thumbnailUrl,
    this.accentHex,
    this.width = 80,
    this.height = 112,
    this.radius = 10,
  });

  Color get _accent {
    if (accentHex == null) return NZColors.maroon;
    try {
      return Color(int.parse(accentHex!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return NZColors.maroon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accent, Color.alphaBlend(Colors.black26, _accent)],
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tibetan != null)
            Text(tibetan!,
                style: AppTheme.tibetan(size: 11, color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(title,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BookCard  — vertical card for horizontal scroll
// ─────────────────────────────────────────────
class NZBookCard extends StatelessWidget {
  final String title;
  final String? tibetan;
  final String? author;
  final String? thumbnailUrl;
  final String? accentHex;
  final VoidCallback? onTap;

  const NZBookCard({
    super.key,
    required this.title,
    this.tibetan,
    this.author,
    this.thumbnailUrl,
    this.accentHex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NZBookCover(
              title: title,
              tibetan: tibetan,
              thumbnailUrl: thumbnailUrl,
              accentHex: accentHex,
              width: 120,
              height: 168,
              radius: 12,
            ),
            const SizedBox(height: 8),
            Text(title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (author != null)
              Text(author!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AudioRow  — single track list item
// ─────────────────────────────────────────────
class NZAudioRow extends StatelessWidget {
  final String title;
  final String? tibetan;
  final String? artist;
  final String? duration;
  final String? accentHex;
  final bool isCurrent;
  final bool isPlaying;
  final bool isFav;
  final VoidCallback? onTap;
  final VoidCallback? onFav;

  const NZAudioRow({
    super.key,
    required this.title,
    this.tibetan,
    this.artist,
    this.duration,
    this.accentHex,
    this.isCurrent = false,
    this.isPlaying = false,
    this.isFav = false,
    this.onTap,
    this.onFav,
  });

  Color get _accent {
    if (accentHex == null) return NZColors.maroon;
    try {
      return Color(int.parse(accentHex!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return NZColors.maroon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: NZColors.border)),
        ),
        child: Row(
          children: [
            // Cover circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_accent, Color.alphaBlend(Colors.black38, _accent)],
                ),
              ),
              child: isCurrent && isPlaying
                  ? const _PlayingBars()
                  : const Icon(Icons.music_note, color: Colors.white70, size: 22),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (tibetan != null)
                    Text(tibetan!,
                        style: AppTheme.tibetan(size: 12, color: NZColors.stone),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      if (artist != null)
                        Expanded(
                          child: Text(artist!,
                              style: Theme.of(context).textTheme.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      if (duration != null)
                        Text(duration!,
                            style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
            // Fav
            if (onFav != null)
              IconButton(
                onPressed: onFav,
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isFav ? NZColors.saffron : NZColors.stoneLight,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            // Play
            if (!isCurrent)
              const Icon(Icons.play_circle_outline, color: NZColors.saffron, size: 28)
            else
              Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: NZColors.saffron,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

// Animated bars for currently playing track
class _PlayingBars extends StatefulWidget {
  const _PlayingBars();
  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [14.0, 20.0, 12.0, 18.0].asMap().entries.map((e) {
          final phase = e.key * 0.25;
          final h = 6.0 + (e.value - 6) * (((_ctrl.value + phase) % 1.0));
          return Container(
            width: 3,
            height: h.clamp(4.0, 18.0),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NZCategoryPill — horizontal scrollable chips
// ─────────────────────────────────────────────
class NZCategoryPills extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  const NZCategoryPills({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? NZColors.maroon : NZColors.creamDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? NZColors.white : NZColors.stone,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NZMiniPlayer  — bottom persistent player
// ─────────────────────────────────────────────
class NZMiniPlayer extends StatelessWidget {
  final String title;
  final String? artist;
  final String? accentHex;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onTap;

  const NZMiniPlayer({
    super.key,
    required this.title,
    this.artist,
    this.accentHex,
    this.isPlaying = false,
    this.onPlayPause,
    this.onTap,
  });

  Color get _accent {
    if (accentHex == null) return NZColors.maroon;
    try {
      return Color(int.parse(accentHex!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return NZColors.maroon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: NZColors.charcoal,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Cover
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_accent, Color.alphaBlend(Colors.black38, _accent)],
                ),
              ),
              child: isPlaying
                  ? const _PlayingBars()
                  : const Icon(Icons.music_note, color: Colors.white70, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (artist != null)
                    Text(artist!,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              onPressed: onPlayPause,
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: NZColors.saffron,
                size: 28,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NZEmptyState
// ─────────────────────────────────────────────
class NZEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const NZEmptyState({super.key, required this.icon, required this.title, this.subtitle});

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
              decoration: BoxDecoration(
                color: NZColors.goldDim,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: NZColors.gold),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NZColors.stone),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NZShimmer — loading placeholder
// ─────────────────────────────────────────────
class NZShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const NZShimmer({super.key, required this.width, required this.height, this.radius = 8});

  @override
  State<NZShimmer> createState() => _NZShimmerState();
}

class _NZShimmerState extends State<NZShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [NZColors.creamDark, NZColors.cream, NZColors.creamDark],
          ),
        ),
      ),
    );
  }
}
