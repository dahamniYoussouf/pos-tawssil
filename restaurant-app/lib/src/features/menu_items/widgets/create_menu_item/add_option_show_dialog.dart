import 'package:flutter/material.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';

class AddOptionGroupDialog extends StatefulWidget {
  final void Function(MenuItemOptionGroup group) onSave;
  final MenuItemOptionGroup? group;

  const AddOptionGroupDialog({
    super.key,
    required this.onSave,
    this.group,
  });

  @override
  State<AddOptionGroupDialog> createState() => _AddOptionGroupDialogState();
}

class _AddOptionGroupDialogState extends State<AddOptionGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _groupNameController;
  late bool _isRequired;
  late bool _isMultipleChoice;
  late List<_OptionItem> _options;

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController(text: widget.group?.nom ?? '');
    _isRequired = widget.group?.isRequired ?? false;
    _isMultipleChoice = widget.group?.multipleChoice ?? false;
    _options = widget.group?.options.map((opt) {
          return _OptionItem(
            nameController: TextEditingController(text: opt.nom),
            priceController:
                TextEditingController(text: opt.prix.toStringAsFixed(2)),
          );
        }).toList() ??
        [
          _OptionItem(
            nameController: TextEditingController(),
            priceController: TextEditingController(text: '0.00'),
          ),
          _OptionItem(
            nameController: TextEditingController(),
            priceController: TextEditingController(text: '0.00'),
          ),
        ];
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (var option in _options) {
      option.nameController.dispose();
      option.priceController.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add(_OptionItem(
        nameController: TextEditingController(),
        priceController: TextEditingController(text: '0.00'),
      ));
    });
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final groupName = _groupNameController.text.trim();
    final localizations = AppLocalizations.of(context)!;

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.optionGroupNameRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final validOptions = _options
        .where((opt) => opt.nameController.text.trim().isNotEmpty)
        .map((opt) {
      return MenuItemOption(
        id: '',
        nom: opt.nameController.text.trim(),
        prix: double.tryParse(opt.priceController.text.trim()) ?? 0.0,
      );
    }).toList();

    if (validOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez ajouter au moins une option'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final group = MenuItemOptionGroup(
      id: widget.group?.id ?? '',
      nom: groupName,
      isRequired: _isRequired,
      multipleChoice: _isMultipleChoice,
      options: validOptions,
    );

    widget.onSave(group);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  localizations.addOptionGroup,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Group Name Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.optionGroupNameLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _groupNameController,
                      decoration: InputDecoration(
                        hintText: localizations.optionGroupNameHint,
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF2F4F7),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.greyLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.greyLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primaryColor, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.optionGroupNameRequired;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Obligatoire Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.optionGroupRequired,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Switch(
                      value: _isRequired,
                      onChanged: (value) {
                        setState(() {
                          _isRequired = value;
                        });
                      },
                      activeThumbColor: AppColors.primaryColor,
                      inactiveThumbColor: AppColors.greyLight,
                      inactiveTrackColor:
                          AppColors.greyLight.withValues(alpha: 0.5),
                      trackOutlineColor: WidgetStateProperty.resolveWith(
                        (states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.transparent;
                          }
                          return AppColors.greyLight;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Choix Multiple Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.optionGroupMultipleChoice,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Switch(
                      value: _isMultipleChoice,
                      onChanged: (value) {
                        setState(() {
                          _isMultipleChoice = value;
                        });
                      },
                      activeThumbColor: AppColors.primaryColor,
                      inactiveThumbColor: AppColors.greyLight,
                      inactiveTrackColor:
                          AppColors.greyLight.withValues(alpha: 0.5),
                      trackOutlineColor: WidgetStateProperty.resolveWith(
                        (states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.transparent;
                          }
                          return AppColors.greyLight;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Options Section
                Text(
                  localizations.optionGroupOptions,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Option Rows
                ..._options.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: option.nameController,
                            decoration: InputDecoration(
                              hintText: localizations.optionOptionNameLabel,
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF2F4F7),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: AppColors.greyLight),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: AppColors.greyLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.primaryColor, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: option.priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              suffixText: 'DZ',
                              suffixStyle: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF2F4F7),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: AppColors.greyLight),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: AppColors.greyLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.primaryColor, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Add Option Button
                InkWell(
                  onTap: _addOption,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.greyLight),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: AppColors.primaryColor,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          localizations.optionAdd,
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          localizations.optionGroupButtonAdd,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          side: const BorderSide(
                            color: AppColors.primaryColor,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          localizations.cancel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

class _OptionItem {
  final TextEditingController nameController;
  final TextEditingController priceController;

  _OptionItem({
    required this.nameController,
    required this.priceController,
  });
}
