class PostModel {
  final int id;
  final String title;
  final String? tibetanTitle;
  final String? description;
  final int subCategoryId;
  final int isVideo;
  final String? thumbnail;
  final int isYoutube;
  final String? youtubeUrl;
  final bool status;
  final DateTime? createdAt;
  // New fields from DB migration v1
  final String contentType;   // 'book' | 'audio' | 'video' | 'image'
  final String? artist;
  final int? durationSeconds;
  final String? coverImageUrl;
  final String? audioUrl;
  final String? accentColor;
  final int? pagesCount;
  final bool isFeatured;
  final int? featuredOrder;
  final DateTime? publishedAt;
  final String? translator;

  const PostModel({
    required this.id,
    required this.title,
    this.tibetanTitle,
    this.description,
    required this.subCategoryId,
    required this.isVideo,
    this.thumbnail,
    required this.isYoutube,
    this.youtubeUrl,
    required this.status,
    this.createdAt,
    this.contentType = 'book',
    this.artist,
    this.durationSeconds,
    this.coverImageUrl,
    this.audioUrl,
    this.accentColor,
    this.pagesCount,
    this.isFeatured = false,
    this.featuredOrder,
    this.publishedAt,
    this.translator,
  });

  bool get isAudio => contentType == 'audio' || isVideo == 0 && isYoutube == 0 && audioUrl != null;

  String get displayAuthor => artist ?? translator ?? '';

  /// Duration formatted as mm:ss
  String get durationFormatted {
    if (durationSeconds == null) return '';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] as int,
        title: json['title'] as String,
        tibetanTitle: json['tibetan_title'] as String?,
        description: json['description'] as String?,
        subCategoryId: json['sub_category_id'] as int,
        isVideo: (json['is_video'] ?? 0) as int,
        thumbnail: json['thumbnail'] as String?,
        isYoutube: (json['is_youtube'] ?? 0) as int,
        youtubeUrl: json['youtube_url'] as String?,
        status: json['status'] as bool? ?? true,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
        contentType: json['content_type'] as String? ?? 'book',
        artist: json['artist'] as String?,
        durationSeconds: json['duration_seconds'] as int?,
        coverImageUrl: json['cover_image_url'] as String?,
        audioUrl: json['audio_url'] as String?,
        accentColor: json['accent_color'] as String?,
        pagesCount: json['pages_count'] as int?,
        isFeatured: json['is_featured'] as bool? ?? false,
        featuredOrder: json['featured_order'] as int?,
        publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'] as String) : null,
        translator: json['translator'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'tibetan_title': tibetanTitle,
        'description': description,
        'sub_category_id': subCategoryId,
        'is_video': isVideo,
        'thumbnail': thumbnail,
        'is_youtube': isYoutube,
        'youtube_url': youtubeUrl,
        'status': status,
        'content_type': contentType,
        'artist': artist,
        'duration_seconds': durationSeconds,
        'cover_image_url': coverImageUrl,
        'audio_url': audioUrl,
        'accent_color': accentColor,
        'pages_count': pagesCount,
        'is_featured': isFeatured,
        'featured_order': featuredOrder,
        'translator': translator,
      };
}
