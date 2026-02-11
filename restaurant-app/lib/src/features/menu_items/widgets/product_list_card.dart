import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/core/widgets/confirmation_dialog.dart';
import 'package:restaurant_app/src/features/categories/models/category_model.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/menu_item_cubit.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/menu_item_state.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';
import 'package:restaurant_app/src/features/menu_items/pages/create_menu_item_page.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';

class ProductListCard extends StatelessWidget {
  final MenuModel menuItem;
  final CategoryModel category;
  final VoidCallback? onUpdated;

  const ProductListCard({
    super.key,
    required this.menuItem,
    required this.category,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = menuItem.ingredients ?? menuItem.description ?? '';

    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToEdit(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildImage(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      menuItem.nom,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      '${NumberFormat('#,###').format(menuItem.prix)} DA',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              BlocProvider(
                create: (context) => locator<MenuItemCubit>(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AvailabilitySwitch(
                      menuItem: menuItem,
                      category: category,
                      onToggled: onUpdated,
                    ),
                    const SizedBox(width: 2),
                    _MoreOptionsButton(
                      menuItem: menuItem,
                      category: category,
                      onEdit: () => _navigateToEdit(context),
                      onDelete: (ctx) => _showDeleteDialog(ctx),
                      onUpdated: onUpdated,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: menuItem.photoUrl != null && menuItem.photoUrl!.isNotEmpty
          ? Image.network(
              menuItem.photoUrl!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.greyVeryLight,
      child: const Icon(
        Icons.restaurant,
        size: 36,
        color: AppColors.greyLight,
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => BlocProvider(
          create: (context) => locator<MenuItemCubit>(),
          child: CreateMenuItemSheet(
            categories: [category],
            menuItem: menuItem,
          ),
        ),
      ),
    ).then((_) {
      onUpdated?.call();
    });
  }

  void _showDeleteDialog(
    BuildContext contextWithCubit,
  ) {
    final localizations = AppLocalizations.of(contextWithCubit)!;

    showDialog(
        context: contextWithCubit,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => BlocProvider.value(
            value: contextWithCubit.read<MenuItemCubit>(),
            child: BlocListener<MenuItemCubit, MenuItemState>(
              listener: (context, state) {
                if (state is MenuItemActionSuccess) {
                  Navigator.of(dialogContext).pop();
                  onUpdated?.call();
                }
              },
              child: ConfirmationDialog(
                  data: ConfirmationDialogData(
                title: localizations.deleteMenuItem,
                content: localizations.deleteMenuItemConfirmation,
                confirmText: localizations.delete,
                cancelText: localizations.cancel,
                confirmButtonColor: AppColors.red,
                confirmTextColor: AppColors.white,
                onConfirm: () {
                  dialogContext
                      .read<MenuItemCubit>()
                      .deleteMenuItem(menuItem.id);
                },
                onCancel: () {},
              )),
            )));
  }
}

class _AvailabilitySwitch extends StatelessWidget {
  final MenuModel menuItem;
  final CategoryModel category;
  final VoidCallback? onToggled;

  const _AvailabilitySwitch({
    required this.menuItem,
    required this.category,
    this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MenuItemCubit, MenuItemState>(
      listenWhen: (prev, curr) =>
          curr is MenuItemActionSuccess || curr is MenuItemActionError,
      listener: (context, state) {
        if (state is MenuItemActionSuccess) {
          context.read<RestaurantCubit>().fetchRestaurantDetails();
          onToggled?.call();
        } else if (state is MenuItemActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is MenuItemActionLoading;
        return Switch(
          value: menuItem.disponible,
          splashRadius: 12,
          onChanged: isLoading
              ? null
              : (value) {
                  context.read<MenuItemCubit>().updateMenuItem(
                        id: menuItem.id,
                        categoryId: menuItem.categoryId ?? category.id,
                        name: menuItem.nom,
                        description: menuItem.description ?? '',
                        price: menuItem.prix,
                        preparationTime: menuItem.tempsPreparation ?? 0,
                        ingredients: menuItem.ingredients,
                        allergens: menuItem.allergenes,
                        photoUrl: menuItem.photoUrl,
                        isAvailable: value,
                      );
                },
          activeTrackColor: AppColors.primaryColor.withValues(alpha: 0.5),
          activeThumbColor: AppColors.primaryColor,
        );
      },
    );
  }
}

class _MoreOptionsButton extends StatelessWidget {
  final MenuModel menuItem;
  final CategoryModel category;
  final VoidCallback onEdit;
  final void Function(BuildContext context) onDelete;
  final VoidCallback? onUpdated;

  const _MoreOptionsButton({
    required this.menuItem,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        size: 16,
        color: AppColors.iconMedium,
      ),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Text(localizations.editMenuItem),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Text(
            localizations.delete,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
