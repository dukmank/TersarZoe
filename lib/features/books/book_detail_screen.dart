import '../../core/utils/r2_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/post_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/nz_components.dart';
import 'pdf_reader_screen.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final PostModel post;
  const BookDetailScreen({super.key, required this.post});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  List<Map<String, dynamic>>? _files;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final files = await ref.read(supabaseServiceProvider).getPostFiles(widget.post.id);
    if (mounted) setState(() { _files = files; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isFav = ref.watch(favoritesProvider).contains(post.id);

    Color accentColor = NZColors.maroon;
    if (post.accentColor != null) {
      try { accentColor = Color(int.parse(post.accentColor!.replaceFirst('#', '0xFF'))); } catch (_) {}
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar with book cover ──
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                onPressed: () => ref.read(favoritesProvider.notifier).toggle(post.id),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor, Color.alphaBlend(Colors.black45, accentColor)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      NZBookCover(
                        title: post.title,
                        tibetan: post.tibetanTitle,
                        thumbnailUrl: post.thumbnail != null ? R2Helper.postThumbnail(post.thumbnail!) : null,
                        accentHex: post.accentColor,
                        width: 120,
                        height: 168,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Book Info ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.tibetanTitle != null)
                    Text(post.tibetanTitle!, style: AppTheme.tibetan(size: 18, color: NZColors.gold)),
                  const SizedBox(height: 6),
                  Text(post.title,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(color: NZColors.charcoal)),
                  const SizedBox(height: 8),
                  // Author / translator
                  if (post.displayAuthor.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: NZColors.stone),
                        const SizedBox(width: 6),
                        Text(post.displayAuthor, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NZColors.stone)),
                      ],
                    ),
                  const SizedBox(height: 4),
                  if (post.pagesCount != null)
                    Row(
                      children: [
                        const Icon(Icons.menu_book_outlined, size: 16, color: NZColors.stone),
                        const SizedBox(width: 6),
                        Text('${post.pagesCount} pages', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Description
                  if (post.description != null && post.description!.isNotEmpty) ...[
                    Text('About', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    Text(post.description!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7, color: NZColors.charcoal)),
                    const SizedBox(height: 24),
                  ],
                  // Reading progress
                  Consumer(builder: (_, r, __) {
                    final progress = r.watch(readingProgressProvider)[post.id];
                    if (progress == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reading Progress', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        NZProgress(value: progress),
                        const SizedBox(height: 4),
                        Text('${(progress * 100).round()}% complete', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                  // Files section
                  Text('Files', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── File List ──
          if (_loading)
            const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            )
          else if (_files != null && _files!.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final file = _files![i];
                  final name = file['file_name'] ?? file['file_path'] ?? 'File ${i + 1}';
                  final type = (file['file_type'] ?? '').toString().toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _FileCard(
                      name: name,
                      type: type,
                      onTap: () => _openFile(context, file, post),
                    ),
                  );
                },
                childCount: _files!.length,
              ),
            )
          else
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: NZEmptyState(
                  icon: Icons.insert_drive_file_outlined,
                  title: 'No files available',
                  subtitle: 'Files will appear here when uploaded',
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),

      // ── Read button ──
      bottomNavigationBar: _files != null && _files!.any((f) => (f['file_type'] ?? '').toString().toLowerCase() == 'pdf')
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    final pdfFile = _files!.firstWhere(
                        (f) => (f['file_type'] ?? '').toString().toLowerCase() == 'pdf');
                    _openFile(context, pdfFile, post);
                  },
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Read Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NZColors.maroon,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _openFile(BuildContext context, Map<String, dynamic> file, PostModel post) {
    final type = (file['file_type'] ?? '').toString().toLowerCase();
    final path = file['file_path'] as String? ?? '';
    if (type == 'pdf' || path.endsWith('.pdf')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PdfReaderScreen(post: post, filePath: path)));
    }
  }
}

class _FileCard extends StatelessWidget {
  final String name;
  final String type;
  final VoidCallback? onTap;

  const _FileCard({required this.name, required this.type, this.onTap});

  IconData get _icon {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'mp3': case 'audio': return Icons.audiotrack;
      case 'epub': return Icons.book;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Color get _iconColor {
    switch (type) {
      case 'pdf': return const Color(0xFFE53935);
      case 'mp3': case 'audio': return NZColors.saffron;
      case 'epub': return NZColors.turquoise;
      default: return NZColors.stone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NZColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.split('/').last, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(type.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: NZColors.stoneLight),
          ],
        ),
      ),
    );
  }
}
