import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/categories/cubit/category_cubit.dart';
import 'package:restaurant_app/src/features/categories/cubit/category_state.dart';
import 'package:restaurant_app/src/features/categories/models/category_model.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';

class CreateCategoryPage extends StatefulWidget {
  final CategoryModel? category;

  const CreateCategoryPage({super.key, this.category});

  @override
  State<CreateCategoryPage> createState() => _CreateCategoryPageState();
}

class _CreateCategoryPageState extends State<CreateCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _showOrderController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.category?.nom ?? '');
    _showOrderController = TextEditingController(
      text: widget.category?.ordreAffichage.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _showOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Title
              Text(
                l10n.createCategory,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              /// Label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${l10n.categoryName} *',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              /// Input
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  hintText: l10n.categoryNameHint,
                  filled: true,
                  fillColor: const Color(0xFFF4F6F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.categoryNameRequired;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _showOrderController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF4F6F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  labelText: l10n.displayOrder,
                  hintText: l10n.displayOrderHint,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.displayOrderRequired;
                  }
                  final order = int.tryParse(value);
                  if (order == null || order < 0) {
                    return l10n.invalidDisplayOrder;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              /// Buttons

              Row(
                children: [
                  Expanded(
                    child: BlocSelector<CategoryCubit, CategoryState, bool>(
                      selector: (state) => state is CategoryLoading,
                      builder: (context, isLoading) {
                        return ElevatedButton(
                          onPressed: isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.create,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BlocSelector<CategoryCubit, CategoryState, bool>(
                      selector: (state) => state is CategoryLoading,
                      builder: (context, isLoading) {
                        return ElevatedButton(
                          onPressed:
                              isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: AppColors.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.cancel,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (widget.category != null) ...[
                const SizedBox(height: 16),
                BlocSelector<CategoryCubit, CategoryState, bool>(
                  selector: (state) => state is CategoryLoading,
                  builder: (context, isLoading) {
                    return Row(
                      children: [
                        Expanded(
                            child: ElevatedButton(
                          onPressed: isLoading ? null : _handleDelete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: .7),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white),
                                  ),
                                )
                              : Text(
                                  l10n.delete,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ))
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final nom = _nomController.text.trim();
    final showOrder = int.parse(_showOrderController.text.trim());

    if (widget.category != null) {
      context.read<CategoryCubit>().updateCategory(
            id: widget.category!.id,
            nom: nom,
            description: '',
            ordreAffichage: showOrder,
            iconeUrl: null,
          );
    } else {
      context
          .read<CategoryCubit>()
          .createCategory(
            nom: nom,
            description: '',
            ordreAffichage: showOrder,
            iconeUrl: null,
          )
          .whenComplete(
        () {
          if (context.mounted) {
            Navigator.pop(context);
            context.read<RestaurantCubit>().fetchRestaurantDetails();
          }
        },
      );
    }
  }

  void _handleDelete() {
    if (widget.category != null) {
      context
          .read<CategoryCubit>()
          .deleteCategory(
            widget.category!.id,
          )
          .whenComplete(() {
        if (context.mounted) {
          Navigator.pop(context);
          context.read<RestaurantCubit>().fetchRestaurantDetails();
        }
      });
    }
  }
}
