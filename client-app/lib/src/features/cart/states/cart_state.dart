import 'package:equatable/equatable.dart';
import '../cubit/cart_cubit.dart';

// Cart States
abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartUpdated extends CartState {
  final Map<String, CartItem> items;
  final int totalItems;
  final double totalPrice;
  final bool isEmpty;

  const CartUpdated({
    required this.items,
    required this.totalItems,
    required this.totalPrice,
    required this.isEmpty,
  });

  @override
  List<Object?> get props => [items, totalItems, totalPrice, isEmpty];
}

class CartError extends CartState {
  final String message;

  const CartError({required this.message});

  @override
  List<Object?> get props => [message];
}
