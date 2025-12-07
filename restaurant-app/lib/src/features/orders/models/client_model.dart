class ClientModel {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? address;
  final String? email;

  ClientModel({
    this.id,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.address,
    this.email,
  });

  String get name {
    if (firstName == null && lastName == null) return '';
    if (firstName == null || firstName!.isEmpty) return lastName ?? '';
    if (lastName == null || lastName!.isEmpty) return firstName ?? '';
    return '$firstName $lastName';
  }

  factory ClientModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ClientModel();
    }

    return ClientModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      firstName: json['first_name'] ??
          json['firstName'] ??
          json['name'] ??
          json['nom'],
      lastName: json['last_name'] ?? json['lastName'],
      phoneNumber: json['phone'] ??
          json['phoneNumber'] ??
          json['phone_number'] ??
          json['tel'],
      address: json['address'] ?? json['adresse'] ?? json['location'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'address': address,
      'email': email,
    };
  }
}
