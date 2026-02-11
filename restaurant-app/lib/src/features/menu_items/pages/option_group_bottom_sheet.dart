import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/option_group_form_cubit.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/option_group_form_state.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';

/// Bottom sheet / modal for adding or editing an option group.
/// Uses [OptionGroupFormCubit] for state; all strings use [AppLocalizations].
class OptionGroupBottomSheet extends StatefulWidget {
  final MenuItemOptionGroup? group;
  final void Function(MenuItemOptionGroup group) onSave;
  final void Function(MenuItemOptionGroup group)? onDelete;

  const OptionGroupBottomSheet({
    super.key,
    this.group,
    required this.onSave,
    this.onDelete,
  });

  static Future<MenuItemOptionGroup?> show(
    BuildContext context, {
    MenuItemOptionGroup? group,
    required void Function(MenuItemOptionGroup) onSave,
    void Function(MenuItemOptionGroup)? onDelete,
  }) {
    return showModalBottomSheet<MenuItemOptionGroup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OptionGroupBottomSheet(
        group: group,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<OptionGroupBottomSheet> createState() => _OptionGroupBottomSheetState();
}

class _OptionGroupBottomSheetState extends State<OptionGroupBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _groupNameController;

  bool get isEdit => widget.group != null;

  @override
  void initState() {
    super.initState();
    _groupNameController =
        TextEditingController(text: widget.group?.nom ?? '');
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (_) => OptionGroupFormCubit(widget.group),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: BlocBuilder<OptionGroupFormCubit,
                              OptionGroupFormState>(
                            builder: (context, state) {
                              return Text(
                                isEdit
                                    ? l10n.optionGroupTitleEdit
                                    : l10n.optionGroupTitleAdd,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        if (isEdit && widget.onDelete != null)
                          BlocBuilder<OptionGroupFormCubit,
                              OptionGroupFormState>(
                            buildWhen: (a, b) => a.isSaving != b.isSaving,
                            builder: (context, state) {
                              return IconButton(
                                onPressed:
                                    state.isSaving ? null : _handleDelete,
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                tooltip: l10n.optionGroupDeleteGroup,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<OptionGroupFormCubit,
                        OptionGroupFormState>(
                      builder: (context, state) {
                        return ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          children: [
                            TextFormField(
                              controller: _groupNameController,
                              decoration: InputDecoration(
                                labelText: l10n.optionGroupNameLabel,
                                hintText: l10n.optionGroupNameHint,
                                border: const OutlineInputBorder(),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor),
                                ),
                              ),
                              onChanged: (v) => context
                                  .read<OptionGroupFormCubit>()
                                  .updateGroupName(v),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return l10n.optionGroupNameRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Text(l10n.optionGroupRequired),
                                const SizedBox(width: 8),
                                BlocBuilder<OptionGroupFormCubit,
                                    OptionGroupFormState>(
                                  buildWhen: (a, b) =>
                                      a.isRequired != b.isRequired,
                                  builder: (context, state) {
                                    return Switch(
                                      value: state.isRequired,
                                      onChanged: (v) => context
                                          .read<OptionGroupFormCubit>()
                                          .setRequired(v),
                                      activeColor: AppColors.primaryColor,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(l10n.optionGroupMultipleChoice),
                                const SizedBox(width: 8),
                                BlocBuilder<OptionGroupFormCubit,
                                    OptionGroupFormState>(
                                  buildWhen: (a, b) =>
                                      a.multipleChoice != b.multipleChoice,
                                  builder: (context, state) {
                                    return Switch(
                                      value: state.multipleChoice,
                                      onChanged: (v) => context
                                          .read<OptionGroupFormCubit>()
                                          .setMultipleChoice(v),
                                      activeColor: AppColors.primaryColor,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l10n.optionGroupOptions,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(state.options.length, (index) {
                              final row = state.options[index];
                              return _OptionRow(
                                key: ValueKey(row.id),
                                nom: row.nom,
                                prix: row.prix,
                                optionNameLabel: l10n.optionOptionNameLabel,
                                canDelete: state.options.length > 1,
                                onNomChanged: (v) => context
                                    .read<OptionGroupFormCubit>()
                                    .updateOptionNom(index, v),
                                onPrixChanged: (v) => context
                                    .read<OptionGroupFormCubit>()
                                    .updateOptionPrix(index, v),
                                onDelete: () => context
                                    .read<OptionGroupFormCubit>()
                                    .removeOptionAt(index),
                                deleteTooltip: l10n.optionGroupDeleteOptionTooltip,
                              );
                            }),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => context
                                  .read<OptionGroupFormCubit>()
                                  .addOption(),
                              icon: const Icon(Icons.add, size: 20),
                              label: Text(l10n.optionAdd),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: BlocBuilder<OptionGroupFormCubit,
                                      OptionGroupFormState>(
                                    buildWhen: (a, b) =>
                                        a.isSaving != b.isSaving,
                                    builder: (context, state) {
                                      return ElevatedButton(
                                        onPressed: state.isSaving
                                            ? null
                                            : () => _handleSave(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: state.isSaving
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(AppColors
                                                          .white),
                                                ),
                                              )
                                            : Text(
                                                isEdit
                                                    ? l10n
                                                        .optionGroupButtonSave
                                                    : l10n
                                                        .optionGroupButtonAdd,
                                                style: const TextStyle(
                                                    color: AppColors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: BlocBuilder<OptionGroupFormCubit,
                                      OptionGroupFormState>(
                                    buildWhen: (a, b) =>
                                        a.isSaving != b.isSaving,
                                    builder: (context, state) {
                                      return OutlinedButton(
                                        onPressed: state.isSaving
                                            ? null
                                            : () =>
                                                Navigator.of(context).pop(),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              AppColors.primaryColor,
                                          side: const BorderSide(
                                              color: AppColors.primaryColor),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(l10n.cancel),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Future<void> _handleSave(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<OptionGroupFormCubit>();
    final state = cubit.state;
    final nom = state.groupName.trim();
    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.optionGroupNameRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final validOptions = state.options
        .where((r) => r.nom.trim().isNotEmpty)
        .toList();
    if (validOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.errorOptionGroupAddOne),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    cubit.setSaving(true);
    final group = cubit.buildGroup(
      existingId: widget.group?.id ?? '',
      ordreAffichage: widget.group?.ordreAffichage ?? 0,
    );
    widget.onSave(group);
    cubit.setSaving(false);
    if (mounted) Navigator.of(context).pop(group);
  }

  void _handleDelete() {
    if (widget.group == null) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.optionGroupDeleteGroup),
          content: Text(l10n.optionGroupDeleteConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final cubit = context.read<OptionGroupFormCubit>();
                final group = cubit.buildGroup(
                  existingId: widget.group!.id,
                  ordreAffichage: widget.group!.ordreAffichage,
                );
                widget.onDelete?.call(group);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }
}

class _OptionRow extends StatefulWidget {
  final String nom;
  final String prix;
  final String optionNameLabel;
  final bool canDelete;
  final ValueChanged<String> onNomChanged;
  final ValueChanged<String> onPrixChanged;
  final VoidCallback onDelete;
  final String deleteTooltip;

  const _OptionRow({
    super.key,
    required this.nom,
    required this.prix,
    required this.optionNameLabel,
    required this.canDelete,
    required this.onNomChanged,
    required this.onPrixChanged,
    required this.onDelete,
    required this.deleteTooltip,
  });

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  late final TextEditingController _nomController;
  late final TextEditingController _prixController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.nom);
    _prixController = TextEditingController(text: widget.prix);
  }

  @override
  void didUpdateWidget(_OptionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nom != widget.nom && _nomController.text != widget.nom) {
      _nomController.text = widget.nom;
    }
    if (oldWidget.prix != widget.prix && _prixController.text != widget.prix) {
      _prixController.text = widget.prix;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _nomController,
              decoration: InputDecoration(
                labelText: widget.optionNameLabel,
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: widget.onNomChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _prixController,
              decoration: const InputDecoration(
                suffixText: 'DA',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: widget.onPrixChanged,
            ),
          ),
          if (widget.canDelete)
            IconButton(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              tooltip: widget.deleteTooltip,
            ),
        ],
      ),
    );
  }
}
