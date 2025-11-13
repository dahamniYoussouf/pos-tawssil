class WilayaModel {
  final int code;
  final String name;

  WilayaModel({
    required this.code,
    required this.name,
  });

  factory WilayaModel.fromJson(Map<String, dynamic> json) {
    return WilayaModel(
      code: json['code'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }
}
