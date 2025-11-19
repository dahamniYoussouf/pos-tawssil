import 'package:equatable/equatable.dart';

class ClientModel extends Equatable {
  const ClientModel({
    this.name,
    this.phoneNumber,
    this.address,
    this.email,
  });

  final String? name;
  final String? phoneNumber;
  final String? address;
  final String? email;

  @override
  List<Object?> get props => [name, phoneNumber, address, email];

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      name: json['name'],
      phoneNumber: json['phone'],
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
