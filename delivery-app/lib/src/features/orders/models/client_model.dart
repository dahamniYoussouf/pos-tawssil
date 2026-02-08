import 'package:equatable/equatable.dart';

class ClientModel extends Equatable {
  const ClientModel({
    this.id,
    this.name,
    this.phoneNumber,
    this.address,
    this.email,
  });

  final String? id;
  final String? name;
  final String? phoneNumber;
  final String? address;
  final String? email;

  @override
  List<Object?> get props => [id, name, phoneNumber, address, email];

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    String? name = json['full_name'] ?? json['name'];
    if (name == null && json['first_name'] != null) {
      name = '${json['first_name']} ${json['last_name'] ?? ''}'.trim();
    }

    return ClientModel(
      id: (json['id'] ?? json['_id'])?.toString(),
      name: name,
      phoneNumber: json['phone_number'] ?? json['phone'],
      address: json['address'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }
}
