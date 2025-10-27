class UserLocation {
  final String area;
  final String city;

  UserLocation({required this.area, required this.city});
  
 
  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'city': city,
    };
  }
  
  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      area: json['area'] ?? '',
      city: json['city'] ?? '',
    );
  }
  
  @override
  String toString() => '$area, $city';
}