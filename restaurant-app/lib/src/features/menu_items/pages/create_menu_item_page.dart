import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/categories/models/category_model.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/menu_item_cubit.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/menu_item_state.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';
import 'package:restaurant_app/src/features/menu_items/widgets/create_menu_item/add_option_show_dialog.dart';
import 'package:restaurant_app/src/features/menu_items/widgets/create_menu_item/cancel_button.dart';
import 'package:restaurant_app/src/features/menu_items/widgets/create_menu_item/delete_button.dart';
import 'package:restaurant_app/src/features/menu_items/widgets/create_menu_item/item_actif_switch.dart';
import 'package:restaurant_app/src/features/menu_items/widgets/create_menu_item/menu_item_image_picker.dart';
import 'package:restaurant_app/src/features/menu_items/widgets/create_menu_item/modern_category_dropdown.dart';
import 'package:restaurant_app/src/features/menu_items/widgets/create_menu_item/modern_text_field.dart';
import 'package:restaurant_app/src/features/menu_items/widgets/create_menu_item/option_group_card.dart';
import 'package:restaurant_app/src/features/menu_items/widgets/create_menu_item/submit_button.dart';

class CreateMenuItemPage extends StatefulWidget {
  final MenuItemModel? menuItem;
  final List<CategoryModel> categories;

  const CreateMenuItemPage({
    super.key,
    this.menuItem,
    required this.categories,
  });

  @override
  State<CreateMenuItemPage> createState() => _CreateMenuItemPageState();
}

class _CreateMenuItemPageState extends State<CreateMenuItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _preparationTimeController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _allergensController = TextEditingController();

  final _selectedCategoryIdNotifier = ValueNotifier<String?>(null);
  final _selectedImageNotifier = ValueNotifier<File?>(null);
  final _isAvailableNotifier = ValueNotifier<bool>(true);
  final _optionGroupsNotifier = ValueNotifier<List<MenuItemOptionGroup>>([]);
  String? _initialUploadedImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.menuItem != null) {
      final m = widget.menuItem!;
      _nameController.text = m.name;
      _descriptionController.text = m.description ?? '';
      _priceController.text = m.price.toString();
      _preparationTimeController.text = m.preparationTime?.toString() ?? '';
      _ingredientsController.text = m.ingredients ?? '';
      _allergensController.text = m.allergens ?? '';
      _selectedCategoryIdNotifier.value = m.categoryId;
      _initialUploadedImageUrl = m.photoUrl;
      _isAvailableNotifier.value = m.isAvailable;
      _optionGroupsNotifier.value = List.from(m.optionGroups);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _preparationTimeController.dispose();
    _ingredientsController.dispose();
    _allergensController.dispose();
    _selectedCategoryIdNotifier.dispose();
    _selectedImageNotifier.dispose();
    _isAvailableNotifier.dispose();
    _optionGroupsNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _selectedImageNotifier.value = File(pickedFile.path);
        context.read<MenuItemCubit>().reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorPickingImage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    final selectedImage = _selectedImageNotifier.value;
    if (selectedImage == null) return;
    context.read<MenuItemCubit>().uploadImage(selectedImage);
  }

  void _openAddOptionGroup() async {
    await showDialog(
      context: context,
      builder: (context) => AddOptionGroupDialog(
        onSave: (group) {
          _optionGroupsNotifier.value = [
            ..._optionGroupsNotifier.value,
            group.copyWith(
                id: 'local_${DateTime.now().millisecondsSinceEpoch}'),
          ];
        },
      ),
    );
  }

  void _openEditOptionGroup(MenuItemOptionGroup group, int index) async {
    await showDialog(
      context: context,
      builder: (context) => AddOptionGroupDialog(
        group: group,
        onSave: (updated) {
          final list =
              List<MenuItemOptionGroup>.from(_optionGroupsNotifier.value);
          list[index] = updated.copyWith(id: group.id);
          _optionGroupsNotifier.value = list;
        },
      ),
    );
  }

  void _handleSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final selectedCategoryId = _selectedCategoryIdNotifier.value;
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.categoryRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cubit = context.read<MenuItemCubit>();
    final state = cubit.state;
    String? uploadedImageUrl;
    if (state is MenuItemImageUploadSuccess) {
      uploadedImageUrl = state.imageUrl;
    } else {
      uploadedImageUrl = _initialUploadedImageUrl;
    }

    final selectedImage = _selectedImageNotifier.value;
    if (selectedImage != null && uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.uploadImageFirst),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final finalImageUrl = selectedImage != null
        ? uploadedImageUrl
        : (_initialUploadedImageUrl ?? uploadedImageUrl);

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final preparationTime =
        int.tryParse(_preparationTimeController.text.trim()) ?? 30;
    final optionGroups = _optionGroupsNotifier.value;

    if (widget.menuItem != null) {
      context.read<MenuItemCubit>().updateMenuItem(
            id: widget.menuItem!.id,
            categoryId: selectedCategoryId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            price: price,
            preparationTime: preparationTime,
            ingredients: _ingredientsController.text.trim().isEmpty
                ? null
                : _ingredientsController.text.trim(),
            allergens: _allergensController.text.trim().isEmpty
                ? null
                : _allergensController.text.trim(),
            photoUrl: finalImageUrl,
            isAvailable: _isAvailableNotifier.value,
            optionGroups: optionGroups,
          );
    } else {
      context.read<MenuItemCubit>().createMenuItem(
            categoryId: selectedCategoryId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            price: price,
            preparationTime: preparationTime,
            ingredients: _ingredientsController.text.trim().isEmpty
                ? null
                : _ingredientsController.text.trim(),
            allergens: _allergensController.text.trim().isEmpty
                ? null
                : _allergensController.text.trim(),
            photoUrl: finalImageUrl,
            isAvailable: _isAvailableNotifier.value,
            optionGroups: optionGroups,
          );
    }
  }

  void _handleDelete() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext deleteDialogContext) {
        return BlocProvider.value(
          value: context.read<MenuItemCubit>(),
          child: BlocListener<MenuItemCubit, MenuItemState>(
            listener: (context, state) {
              if (state is MenuItemActionSuccess) {
                Navigator.of(deleteDialogContext).pop();
              }
            },
            child: BlocBuilder<MenuItemCubit, MenuItemState>(
              builder: (context, state) {
                final isLoading = state is MenuItemActionLoading;
                return AlertDialog(
                  title: Text(localizations.deleteMenuItem),
                  content: isLoading
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(localizations.deleteMenuItemConfirmation),
                          ],
                        )
                      : Text(localizations.deleteMenuItemConfirmation),
                  actions: [
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(deleteDialogContext).pop(),
                      child: Text(localizations.cancel),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (widget.menuItem != null) {
                                context
                                    .read<MenuItemCubit>()
                                    .deleteMenuItem(widget.menuItem!.id);
                              }
                            },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(localizations.delete),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isEdit = widget.menuItem != null;
    final mediaQuery = MediaQuery.of(context);

    return BlocListener<MenuItemCubit, MenuItemState>(
      listener: (context, state) {
        if (state is MenuItemImageUploadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.imageUploadSuccess),
              backgroundColor: AppColors.primaryColor,
            ),
          );
        } else if (state is MenuItemImageUploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is MenuItemActionSuccess) {
          Navigator.pop(context);
        } else if (state is MenuItemActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        height: mediaQuery.size.height * 0.95,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 75,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(85),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                isEdit ? localizations.editMenuItem : localizations.addMenuItem,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ValueListenableBuilder<File?>(
                        valueListenable: _selectedImageNotifier,
                        builder: (context, selectedImage, _) {
                          return BlocSelector<MenuItemCubit, MenuItemState,
                              bool>(
                            selector: (state) =>
                                state is MenuItemImageUploading,
                            builder: (context, isUploading) {
                              return BlocSelector<MenuItemCubit, MenuItemState,
                                  String?>(
                                selector: (state) {
                                  if (state is MenuItemImageUploadSuccess) {
                                    return state.imageUrl;
                                  }
                                  return _initialUploadedImageUrl;
                                },
                                builder: (context, uploadedImageUrl) {
                                  return MenuItemImagePicker(
                                    selectedImage: selectedImage,
                                    imageUrl: uploadedImageUrl,
                                    isUploading: isUploading,
                                    onPickImage: _pickImage,
                                    onUploadImage: _uploadImage,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Nom de l'Item
                      ModernTextField(
                        controller: _nameController,
                        label: localizations.itemNameLabel,
                        hint: localizations.itemNameHint,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.itemNameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Description
                      ModernTextField(
                        controller: _descriptionController,
                        label: localizations.description,
                        hint: localizations.descriptionHint,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.descriptionRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Prix
                      ModernTextField(
                        controller: _priceController,
                        label: localizations.priceLabel,
                        hint: 'DA',
                        keyboardType: TextInputType.number,
                        suffixText: 'DA',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.priceRequired;
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return localizations.invalidPrice;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Categorie
                      ValueListenableBuilder<String?>(
                        valueListenable: _selectedCategoryIdNotifier,
                        builder: (context, selectedCategoryId, _) {
                          return ModernCategoryDropdown(
                            categories: widget.categories,
                            selectedCategoryId: selectedCategoryId,
                            onCategorySelected: (categoryId) {
                              _selectedCategoryIdNotifier.value = categoryId;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Item Actif
                      ValueListenableBuilder<bool>(
                        valueListenable: _isAvailableNotifier,
                        builder: (context, isAvailable, _) {
                          return ItemActifSwitch(
                            isActive: isAvailable,
                            onChanged: (value) {
                              _isAvailableNotifier.value = value;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Groupes D'options
                      _buildOptionGroupsSection(localizations),
                      const SizedBox(height: 24),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SubmitButton(
                              isEdit: isEdit,
                              isLoading: context.watch<MenuItemCubit>().state
                                  is MenuItemActionLoading,
                              onPressed: () => _handleSubmit(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CancelButton(
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 16),
                        DeleteButton(
                          isLoading: context.watch<MenuItemCubit>().state
                              is MenuItemActionLoading,
                          onPressed: _handleDelete,
                        ),
                      ],
                      // Bottom padding for keyboard
                      SizedBox(height: mediaQuery.viewInsets.bottom),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionGroupsSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.optionGroups,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<List<MenuItemOptionGroup>>(
          valueListenable: _optionGroupsNotifier,
          builder: (context, groups, _) {
            return Column(
              children: [
                ...List.generate(groups.length, (index) {
                  final group = groups[index];
                  return OptionGroupCard(
                    group: group,
                    onTap: () => _openEditOptionGroup(group, index),
                  );
                }),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _openAddOptionGroup,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.greyLight),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        localizations.addOptionGroup,
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
