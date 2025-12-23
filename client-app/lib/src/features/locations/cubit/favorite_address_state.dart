import 'package:equatable/equatable.dart';
import '../models/favorite_address_model.dart';

abstract class FavoriteAddressState extends Equatable {
  const FavoriteAddressState();

  @override
  List<Object?> get props => [];
}

class FavoriteAddressInitial extends FavoriteAddressState {}

class FavoriteAddressLoading extends FavoriteAddressState {}

class FavoriteAddressLoaded extends FavoriteAddressState {
  final List<FavoriteAddressModel> addresses;

  const FavoriteAddressLoaded({required this.addresses});

  @override
  List<Object?> get props => [addresses];
}

class FavoriteAddressError extends FavoriteAddressState {
  final String message;

  const FavoriteAddressError({required this.message});

  @override
  List<Object?> get props => [message];
}

class FavoriteAddressCreated extends FavoriteAddressState {
  final FavoriteAddressModel address;

  const FavoriteAddressCreated({required this.address});

  @override
  List<Object?> get props => [address];
}

class FavoriteAddressUpdated extends FavoriteAddressState {
  final FavoriteAddressModel address;

  const FavoriteAddressUpdated({required this.address});

  @override
  List<Object?> get props => [address];
}

class FavoriteAddressDeleted extends FavoriteAddressState {
  final String addressId;

  const FavoriteAddressDeleted({required this.addressId});

  @override
  List<Object?> get props => [addressId];
}

