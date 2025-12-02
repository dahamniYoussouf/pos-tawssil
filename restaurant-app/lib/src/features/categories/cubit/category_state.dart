import 'package:equatable/equatable.dart';
import 'package:restaurant_app/src/features/categories/models/category_model.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;

  const CategoryLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

class CategoryError extends CategoryState {
  final String message;

  const CategoryError({required this.message});

  @override
  List<Object?> get props => [message];
}

class CategoryActionLoading extends CategoryState {
  final List<CategoryModel> categories;

  const CategoryActionLoading({required this.categories});

  @override
  List<Object?> get props => [categories];
}

class CategoryActionSuccess extends CategoryState {
  final List<CategoryModel> categories;
  final String message;

  const CategoryActionSuccess({
    required this.categories,
    required this.message,
  });

  @override
  List<Object?> get props => [categories, message];
}

class CategoryActionError extends CategoryState {
  final List<CategoryModel> categories;
  final String message;

  const CategoryActionError({
    required this.categories,
    required this.message,
  });

  @override
  List<Object?> get props => [categories, message];
}

