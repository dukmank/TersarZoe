class CategoryModel {
  final int id;
  final String name;
  final String? tibetanName;
  final String? description;
  final String? image;
  final bool status;
  final String? contentType;
  final int? displayOrder;
  final String? iconName;

  const CategoryModel({
    required this.id,
    required this.name,
    this.tibetanName,
    this.description,
    this.image,
    this.status = true,
    this.contentType,
    this.displayOrder,
    this.iconName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        tibetanName: json['tibetan_name'] as String?,
        description: json['description'] as String?,
        image: json['image'] as String?,
        status: json['status'] as bool? ?? true,
        contentType: json['content_type'] as String?,
        displayOrder: json['display_order'] as int?,
        iconName: json['icon_name'] as String?,
      );
}
