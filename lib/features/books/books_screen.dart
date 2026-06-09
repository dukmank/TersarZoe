import '../../core/utils/r2_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/category_model.dart';
import '../../shared/models/post_model.dart';
import '../../shared/models/sub_category_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/services/supabase_service.dart';
import '../../shared/widgets/nz_components.dart';
import 'book_detail_screen.dart';

// ── Providers ──
final _selectedCatProvider = StateProvider<int?>((ref) => null);

final _subCatsProvider = FutureProvider.autoDispose.family<List<SubCategoryModel>, int>((ref, catId) async {
  return ref.read(supabaseServiceProvider).getSubCategories(catId);
});

final _selectedSubCatProvider = StateProvider<int?>((ref) => null);

final _postsProvider = FutureProvider.autoDispose.family<List<PostModel>, int>((ref, subCatId) async {
  return ref.read(supabaseServiceProvider).getPosts(subCatId);
});

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCat = ref.watch(_selectedCatProvider);
    final selectedSubCat = ref.watch(_selectedSubCatProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Books'),
            Text('དཔེ་ཆ།', style: AppTheme.tibetan(size: 12, color: NZColors.gold.withOpacity(0.8))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cats) {
          // Auto-select first category
          if (selectedCat == null && cats.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(_selectedCatProvider.notifier).state = cats.first.id;
            });
          }

          return Column(
            children: [
              // ── Category pills ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: NZCategoryPills(
                  labels: cats.map((c) => c.name).toList(),
                  selected: cats.indexWhere((c) => c.id == selectedCat),
                  onSelect: (i) {
                    ref.read(_selectedCatProvider.notifier).state = cats[i].id;
                    ref.read(_selectedSubCatProvider.notifier).state = null;
                  },
                ),
              ),
              // ── Sub-category tabs + posts ──
              Expanded(
                child: selectedCat == null
                    ? const NZEmptyState(icon: Icons.category_outlined, title: 'Select a category')
                    : _CategoryContent(catId: selectedCat),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryContent extends ConsumerWidget {
  final int catId;
  const _CategoryContent({required this.catId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subCatsAsync = ref.watch(_subCatsProvider(catId));

    return subCatsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (subCats) {
        if (subCats.isEmpty) {
          return const NZEmptyState(icon: Icons.folder_open_outlined, title: 'No sub-categories');
        }
        return DefaultTabController(
          length: subCats.length,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: subCats.map((s) => Tab(text: s.name)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: subCats.map((s) => _PostsGrid(subCatId: s.id)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PostsGrid extends ConsumerWidget {
  final int subCatId;
  const _PostsGrid({required this.subCatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(_postsProvider(subCatId));

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (posts) {
        if (posts.isEmpty) {
          return const NZEmptyState(icon: Icons.menu_book_outlined, title: 'No books yet');
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.62,
            crossAxisSpacing: 12,
            mainAxisSpacing: 20,
          ),
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final p = posts[i];
            return NZBookCard(
              title: p.title,
              tibetan: p.tibetanTitle,
              author: p.displayAuthor,
              thumbnailUrl: p.thumbnail != null ? R2Helper.postThumbnail(p.thumbnail!) : null,
              accentHex: p.accentColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookDetailScreen(post: p)),
              ),
            );
          },
        );
      },
    );
  }
}
