import 'package:equatable/equatable.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';

abstract class MenuItemState extends Equatable {
  const MenuItemState();

  @override
  List<Object?> get props => [];
}

class MenuItemInitial extends MenuItemState {}

class MenuItemLoading extends MenuItemState {}

class MenuItemImageUploading extends MenuItemState {}

class MenuItemImageUploadSuccess extends MenuItemState {
  final String imageUrl;

  const MenuItemImageUploadSuccess({required this.imageUrl});

  @override
  List<Object?> get props => [imageUrl];
}

class MenuItemImageUploadError extends MenuItemState {
  final String message;

  const MenuItemImageUploadError({required this.message});

  @override
  List<Object?> get props => [message];
}

class MenuItemActionLoading extends MenuItemState {}

class MenuItemActionSuccess extends MenuItemState {
  final MenuItemModel menuItem;
  final String message;

  const MenuItemActionSuccess({
    required this.menuItem,
    required this.message,
  });

  @override
  List<Object?> get props => [menuItem, message];
}

class MenuItemActionError extends MenuItemState {
  final String message;

  const MenuItemActionError({required this.message});

  @override
  List<Object?> get props => [message];
}
