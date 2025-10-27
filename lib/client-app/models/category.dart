class Category {
  final String id;
  final String name;
  final String iconPath;
  final String? description;  

  Category({
    required this.id,
    required this.name,
    required this.iconPath,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
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