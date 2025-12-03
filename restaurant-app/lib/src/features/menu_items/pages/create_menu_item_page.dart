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
  String? _initialUploadedImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.menuItem != null) {
      _nameController.text = widget.menuItem!.name;
      _descriptionController.text = widget.menuItem!.description ?? '';
      _priceController.text = widget.menuItem!.price.toString();
      _preparationTimeController.text =
          widget.menuItem!.preparationTime?.toString() ?? '';
      _ingredientsController.text = widget.menuItem!.ingredients ?? '';
      _allergensController.text = widget.menuItem!.allergens ?? '';
      _selectedCategoryIdNotifier.value = widget.menuItem!.categoryId;
      _initialUploadedImageUrl = widget.menuItem!.photoUrl;
      _isAvailableNotifier.value = widget.menuItem!.isAvailable;
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
        const SnackBar(
          content: Text('Please upload the image first'),
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
      child: Scaffold(
        backgroundColor: AppColors.white,
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
                Row(
                  children: [
                    Expanded(
                      child: _MenuItemTextField(
                        controller: _priceController,
                        label: localizations.price,
                        hint: localizations.priceHint,
                        keyboardType: TextInputType.number,
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MenuItemTextField(
                        controller: _preparationTimeController,
                        label: localizations.preparationTime,
                        hint: localizations.preparationTimeHint,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.preparationTimeRequired;
                          }
                          final time = int.tryParse(value);
                          if (time == null || time <= 0) {
                            return localizations.invalidPreparationTime;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MenuItemTextField(
                  controller: _ingredientsController,
                  label: localizations.ingredients,
                  hint: localizations.ingredientsHint,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _MenuItemTextField(
                  controller: _allergensController,
                  label: localizations.allergens,
                  hint: localizations.allergensHint,
                  maxLines: 2,
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
              border: Border.all(color: AppColors.greyLight, width: 2),
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
        const Icon(Icons.add_photo_alternate, size: 48, color: AppColors.grey),
        const SizedBox(height: 8),
        Text(
          localizations.selectImage,
          style: const TextStyle(color: AppColors.grey),
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
      initialValue: selectedCategoryId,
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
  final String? Function(String?)? validator;

  const _MenuItemTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
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

class _AvailabilitySwitch extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const _AvailabilitySwitch({
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Text(
            localizations.available,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Switch(
          value: isAvailable,
          onChanged: onChanged,
          activeThumbColor: AppColors.primaryColor,
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
              isEdit ? localizations.update : localizations.create,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
