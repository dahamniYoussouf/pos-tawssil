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

class CreateMenuItemSheet extends StatefulWidget {
  final MenuModel? menuItem;
  final List<CategoryModel> categories;

  const CreateMenuItemSheet({
    super.key,
    this.menuItem,
    required this.categories,
  });

  @override
  State<CreateMenuItemSheet> createState() => _CreateMenuItemSheetState();
}

class _CreateMenuItemSheetState extends State<CreateMenuItemSheet> {
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
  String? _initialUploadedImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.menuItem != null) {
      _nameController.text = widget.menuItem!.nom;
      _descriptionController.text = widget.menuItem!.description ?? '';
      _priceController.text = widget.menuItem!.prix.toString();
      _preparationTimeController.text =
          widget.menuItem!.tempsPreparation?.toString() ?? '';
      _ingredientsController.text = widget.menuItem!.ingredients ?? '';
      _allergensController.text = widget.menuItem!.allergenes ?? '';
      _selectedCategoryIdNotifier.value = widget.menuItem!.categoryId;
      _initialUploadedImageUrl = widget.menuItem!.photoUrl;
      _isAvailableNotifier.value = widget.menuItem!.disponible;
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
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _selectedImageNotifier.value = File(pickedFile.path);
        // Reset uploaded image URL when new image is selected
        context.read<MenuItemCubit>().reset();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImage() async {
    final selectedImage = _selectedImageNotifier.value;
    if (selectedImage == null) return;

    context.read<MenuItemCubit>().uploadImage(selectedImage);
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

    // Get the uploaded image URL from cubit state or use initial value
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

    // Use uploaded URL if available, otherwise keep initial URL
    final finalImageUrl = selectedImage != null
        ? uploadedImageUrl
        : (_initialUploadedImageUrl ?? uploadedImageUrl);

    final price = double.parse(_priceController.text.trim());
    final preparationTime = int.parse(_preparationTimeController.text.trim());

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

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.7,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: mediaQuery.viewInsets.bottom + 20,
                  ),
                  child: _buildFormContent(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormContent(BuildContext context) {
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
          // Close the page (delete dialog closes itself)
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
                hint: "0.00",
                keyboardType: TextInputType.number,
                suffixText: "DA",
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
                  return _AvailabilitySwitch(
                    isAvailable: isAvailable,
                    onChanged: (value) {
                      _isAvailableNotifier.value = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              _SubmitButton(
                isEdit: isEdit,
                isLoading: context.watch<MenuItemCubit>().state
                    is MenuItemActionLoading,
                onPressed: () => _handleSubmit(context),
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
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            child: selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : imageUrl != null && imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined,
                              size: 40, color: AppColors.primaryColor),
                          const SizedBox(height: 12),
                          Text(
                            l10n.selectImage,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.selectImage,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
        if (selectedImage != null && imageUrl == null) ...[
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: isUploading ? null : onUploadImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(l10n.uploadImage),
          )
        ]
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
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.category,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: selectedCategoryId,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F3F3),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
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
              return l10n.categoryRequired;
            }
            return null;
          },
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            filled: true,
            fillColor: const Color(0xFFF3F3F3),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvailabilitySwitch extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const _AvailabilitySwitch({
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.available,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryColor,
          ),
        ],
      ),
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
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                isEdit ? l10n.update : l10n.create,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
      ),
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
