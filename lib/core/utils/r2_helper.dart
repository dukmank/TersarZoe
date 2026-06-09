import '../constants/app_constants.dart';

class R2Helper {
  static final String _base = AppConstants.r2BaseUrl;

  static String categoryImage(String fileName) =>
      '$_base/${AppConstants.categoriesPath}/$fileName';

  static String subCategoryImage(String fileName) =>
      '$_base/${AppConstants.subCategoriesPath}/$fileName';

  static String postThumbnail(String fileName) =>
      '$_base/${AppConstants.thumbnailsPath}/$fileName';

  static String postPdf(String fileName) =>
      '$_base/${AppConstants.postsPdfPath}/$fileName';

  static String postMp3(String fileName) =>
      '$_base/${AppConstants.postsMp3Path}/$fileName';

  static String announcementImage(String fileName) =>
      '$_base/${AppConstants.announcementsPath}/$fileName';

  /// Tự detect loại file và trả URL đúng
  static String postFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return postPdf(fileName);
    if (ext == 'mp3') return postMp3(fileName);
    return '$_base/posts/$fileName';
  }
}
