class AppConstants {
  // Supabase
  static const supabaseUrl = 'https://arbaychxmbbewogyverv.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFyYmF5Y2h4bWJiZXdvZ3l2ZXJ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4OTI5MDcsImV4cCI6MjA5NjQ2ODkwN30.ioEn3vuLzoXEND3_ZJ_crf_HPUNSOL0tjdhJ6HQL7EE';

  // Cloudflare R2 public URL (sau khi enable Public Development URL)
  static const r2BaseUrl =
      'REPLACE_WITH_R2_PUBLIC_URL'; // dạng https://pub-xxxx.r2.dev

  // File paths trên R2
  static const postsPdfPath = 'posts/pdf';
  static const postsMp3Path = 'posts/mp3';
  static const postsImagePath = 'posts';
  static const categoriesPath = 'categories';
  static const subCategoriesPath = 'sub_categories';
  static const announcementsPath = 'announcements';
  static const thumbnailsPath = 'posts/thumbnail';

  // App info
  static const appName = 'TersarZoe';
  static const appVersion = '1.0.0';
}
