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
import 'package:restaurant_app/src/features/menu_items/pages/option_group_bottom_sheet.dart';

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
            content: Text('Error picking image: ${e.toString()}'),
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
    await OptionGroupBottomSheet.show(
      context,
      onSave: (group) {
        _optionGroupsNotifier.value = [
          ..._optionGroupsNotifier.value,
          group.copyWith(id: 'local_${DateTime.now().millisecondsSinceEpoch}'),
        ];
      },
    );
  }

  void _openEditOptionGroup(MenuItemOptionGroup group, int index) async {
    await OptionGroupBottomSheet.show(
      context,
      group: group,
      onSave: (updated) {
        final list = List<MenuItemOptionGroup>.from(_optionGroupsNotifier.value);
        list[index] = updated.copyWith(id: group.id);
        _optionGroupsNotifier.value = list;
      },
      onDelete: (_) {
        final list = List<MenuItemOptionGroup>.from(_optionGroupsNotifier.value);
        list.removeAt(index);
        _optionGroupsNotifier.value = list;
      },
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
        const SnackBar(
          content: Text('Please upload the image first'),
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
        int.tryParse(_preparationTimeController.text.trim()) ?? 0;
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
      child: Scaffold(
        backgroundColor: AppColors.greyVeryLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            isEdit ? localizations.editMenuItem : localizations.createMenuItem,
            style: const TextStyle(color: AppColors.primaryColor),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueListenableBuilder<File?>(
                  valueListenable: _selectedImageNotifier,
                  builder: (context, selectedImage, _) {
                    return BlocSelector<MenuItemCubit, MenuItemState, bool>(
                      selector: (state) => state is MenuItemImageUploading,
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
                            return _MenuItemImagePicker(
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
                const SizedBox(height: 24),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ValueListenableBuilder<String?>(
                        valueListenable: _selectedCategoryIdNotifier,
                        builder: (context, selectedCategoryId, _) {
                          return _CategoryDropdown(
                            categories: widget.categories,
                            selectedCategoryId: selectedCategoryId,
                            onCategorySelected: (categoryId) {
                              _selectedCategoryIdNotifier.value = categoryId;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _MenuItemTextField(
                        controller: _nameController,
                        label: localizations.itemName,
                        hint: localizations.itemNameHint,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.itemNameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _MenuItemTextField(
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
                      _MenuItemTextField(
                        controller: _priceController,
                        label: localizations.price,
                        hint: localizations.priceHint,
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
                      ValueListenableBuilder<bool>(
                        valueListenable: _isAvailableNotifier,
                        builder: (context, isAvailable, _) {
                          return _ItemActifSwitch(
                            isActive: isAvailable,
                            onChanged: (value) {
                              _isAvailableNotifier.value = value;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildOptionGroupsSection(localizations),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _SubmitButton(
                        isEdit: isEdit,
                        isLoading: context.watch<MenuItemCubit>().state
                            is MenuItemActionLoading,
                        onPressed: () => _handleSubmit(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CancelButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                if (isEdit) ...[
                  const SizedBox(height: 16),
                  _DeleteButton(
                    isLoading: context.watch<MenuItemCubit>().state
                        is MenuItemActionLoading,
                    onPressed: _handleDelete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildOptionGroupsSection(AppLocalizations localizations) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Groupes D\'options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
                    return _OptionGroupCard(
                      group: group,
                      onTap: () => _openEditOptionGroup(group, index),
                    );
                  }),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _openAddOptionGroup,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('+ Ajouter option group'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OptionGroupCard extends StatelessWidget {
  final MenuItemOptionGroup group;
  final VoidCallback onTap;

  const _OptionGroupCard({
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final optionCount = group.optionsCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.greyVeryLight,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$optionCount option${optionCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Pill(
                      label: 'Obligatoire',
                      isSelected: group.isRequired,
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      label: 'Simple',
                      isSelected: !group.multipleChoice,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _Pill({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : AppColors.greyLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? AppColors.white : AppColors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MenuItemImagePicker extends StatelessWidget {
  final File? selectedImage;
  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onPickImage;
  final VoidCallback onUploadImage;

  const _MenuItemImagePicker({
    required this.selectedImage,
    this.imageUrl,
    required this.isUploading,
    required this.onPickImage,
    required this.onUploadImage,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.greyVeryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.greyLight,
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: selectedImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (isUploading)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white),
                            ),
                          ),
                        ),
                    ],
                  )
                : imageUrl != null && imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder(localizations);
                          },
                        ),
                      )
                    : _buildPlaceholder(localizations),
          ),
        ),
        if (selectedImage != null && imageUrl == null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isUploading ? null : onUploadImage,
              icon: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Icon(Icons.cloud_upload, color: AppColors.white),
              label: Text(
                isUploading
                    ? localizations.imageUploading
                    : localizations.uploadImage,
                style: const TextStyle(color: AppColors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholder(AppLocalizations localizations) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_a_photo, size: 48, color: AppColors.primaryColor),
        const SizedBox(height: 8),
        Text(
          'Ajouter Une Photo',
          style: const TextStyle(
            color: AppColors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Depuis la galerie du l\'appareil photo',
          style: const TextStyle(color: AppColors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;

  const _CategoryDropdown({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return DropdownButtonFormField<String>(
      value: selectedCategoryId,
      decoration: InputDecoration(
        labelText: localizations.category,
        hintText: localizations.categoryHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Text(category.nom),
        );
      }).toList(),
      onChanged: onCategorySelected,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return localizations.categoryRequired;
        }
        return null;
      },
    );
  }
}

class _MenuItemTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? suffixText;
  final String? Function(String?)? validator;

  const _MenuItemTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.suffixText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
      ),
      validator: validator,
    );
  }
}

class _ItemActifSwitch extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const _ItemActifSwitch({
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text('Item Actif', style: TextStyle(fontSize: 16)),
        ),
        Switch(
          value: isActive,
          onChanged: onChanged,
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isEdit;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isEdit,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            )
          : Text(
              isEdit ? localizations.update : 'Ajouter',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CancelButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        side: const BorderSide(color: AppColors.primaryColor),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text('Annuler'),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _DeleteButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            )
          : Text(
              localizations.delete,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
