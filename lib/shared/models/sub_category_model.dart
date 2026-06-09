class SubCategoryModel {
  final int id;
  final String name;
  final String? tibetanName;
  final String? description;
  final int categoryId;
  final String? bannerImage;
  final bool status;

  const SubCategoryModel({
    required this.id,
    required this.name,
    this.tibetanName,
    this.description,
    required this.categoryId,
    this.bannerImage,
    this.status = true,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) => SubCategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        tibetanName: json['tibetan_name'] as String?,
        description: json['description'] as String?,
        categoryId: json['category_id'] as int,
        bannerImage: json['banner_image'] as String?,
        status: json['status'] as bool? ?? true,
      );
}
