import 'package:equatable/equatable.dart';

class ProfileModel extends Equatable {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? address;
  final String? location;
  final String? profileImageUrl;
  final int loyaltyPoints;
  final bool isVerified;
  final bool isActive;
  final String status;
  final String createdAt;
  final String updatedAt;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.address,
    this.location,
    this.profileImageUrl,
    required this.loyaltyPoints,
    required this.isVerified,
    required this.isActive,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        firstName,
        lastName,
        email,
        phoneNumber,
        address,
        location,
        profileImageUrl,
        loyaltyPoints,
        isVerified,
        isActive,
        status,
        createdAt,
        updatedAt,
      ];

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      address: json['address'] as String?,
      location: json['location'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      loyaltyPoints: json['loyalty_points'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'location': location,
      'profile_image_url': profileImageUrl,
      'loyalty_points': loyaltyPoints,
      'is_verified': isVerified,
      'is_active': isActive,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  bool get isEmpty => firstName.trim().isEmpty && lastName.trim().isEmpty;
}
