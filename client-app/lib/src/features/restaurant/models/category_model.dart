class CategoryModel {
  final String id;
  final String name;
  final String iconPath;
  final String? description;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconPath,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      iconPath: json['iconPath'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconPath': iconPath,
      'description': description,
    };
  }
}
