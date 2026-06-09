import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/sub_category_model.dart';
import '../models/post_model.dart';

class SupabaseService {
  final _db = Supabase.instance.client;

  // ── Categories ──
  Future<List<CategoryModel>> getCategories() async {
    final res = await _db.from('categories').select().eq('status', true).order('display_order', nullsFirst: false).order('id');
    return (res as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  // ── Sub-categories ──
  Future<List<SubCategoryModel>> getSubCategories(int categoryId) async {
    final res = await _db.from('sub_categories').select().eq('category_id', categoryId).eq('status', true).order('id');
    return (res as List).map((e) => SubCategoryModel.fromJson(e)).toList();
  }

  // ── Posts by sub-category (paginated) ──
  Future<List<PostModel>> getPosts(int subCategoryId, {int page = 0}) async {
    final res = await _db
        .from('posts')
        .select()
        .eq('sub_category_id', subCategoryId)
        .eq('status', true)
        .order('id')
        .range(page * 20, (page + 1) * 20 - 1);
    return (res as List).map((e) => PostModel.fromJson(e)).toList();
  }

  // ── Featured books ──
  Future<List<PostModel>> getFeaturedPosts({int limit = 10}) async {
    final res = await _db
        .from('posts')
        .select()
        .eq('status', true)
        .eq('is_featured', true)
        .inFilter('content_type', ['book', 'pdf'])
        .order('featured_order', nullsFirst: false)
        .limit(limit);
    return (res as List).map((e) => PostModel.fromJson(e)).toList();
  }

  // ── Featured audio ──
  Future<List<PostModel>> getFeaturedAudio({int limit = 8}) async {
    final res = await _db
        .from('posts')
        .select()
        .eq('status', true)
        .eq('content_type', 'audio')
        .order('created_at', ascending: false)
        .limit(limit);
    return (res as List).map((e) => PostModel.fromJson(e)).toList();
  }

  // ── Files of a post ──
  Future<List<Map<String, dynamic>>> getPostFiles(int postId) async {
    final res = await _db.from('files').select().eq('post_id', postId).eq('status', true);
    return List<Map<String, dynamic>>.from(res);
  }

  // ── Announcements ──
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final res = await _db.from('announcements').select().eq('status', true).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ── Search ──
  Future<List<PostModel>> searchPosts(String query) async {
    final res = await _db
        .from('posts')
        .select()
        .or('title.ilike.%$query%,description.ilike.%$query%,tibetan_title.ilike.%$query%')
        .eq('status', true)
        .limit(40);
    return (res as List).map((e) => PostModel.fromJson(e)).toList();
  }

  // ── Gallery items ──
  Future<List<Map<String, dynamic>>> getGalleryItems({String? category}) async {
    var query = _db.from('gallery_items').select().eq('is_published', true);
    if (category != null) query = query.eq('category', category);
    final res = await query.order('sort_order', nullsFirst: false).order('id');
    return List<Map<String, dynamic>>.from(res);
  }
}
