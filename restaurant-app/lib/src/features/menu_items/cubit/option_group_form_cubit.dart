import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/option_group_form_state.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';

class OptionGroupFormCubit extends Cubit<OptionGroupFormState> {
  OptionGroupFormCubit([MenuItemOptionGroup? initialGroup])
      : super(_initialFromGroup(initialGroup));

  static OptionGroupFormState _initialFromGroup(MenuItemOptionGroup? g) {
    final options = (g?.options ?? [])
        .map((o) => OptionRowFormData(
              id: o.id,
              nom: o.nom,
              prix: o.prix.toStringAsFixed(2),
            ))
        .toList();
    if (options.isEmpty) {
      options.add(OptionRowFormData(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        nom: '',
        prix: '0.00',
      ));
    }
    return OptionGroupFormState(
      groupName: g?.nom ?? '',
      isRequired: g?.isRequired ?? false,
      multipleChoice: g?.multipleChoice ?? false,
      options: options,
    );
  }

  void updateGroupName(String value) {
    emit(state.copyWith(groupName: value));
  }

  void setRequired(bool value) {
    emit(state.copyWith(isRequired: value));
  }

  void setMultipleChoice(bool value) {
    emit(state.copyWith(multipleChoice: value));
  }

  void addOption() {
    final options = List<OptionRowFormData>.from(state.options)
      ..add(OptionRowFormData(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        nom: '',
        prix: '0.00',
      ));
    emit(state.copyWith(options: options));
  }

  void removeOptionAt(int index) {
    if (state.options.length <= 1) return;
    final options = List<OptionRowFormData>.from(state.options)..removeAt(index);
    emit(state.copyWith(options: options));
  }

  void updateOptionNom(int index, String value) {
    if (index < 0 || index >= state.options.length) return;
    final options = List<OptionRowFormData>.from(state.options);
    options[index] = options[index].copyWith(nom: value);
    emit(state.copyWith(options: options));
  }

  void updateOptionPrix(int index, String value) {
    if (index < 0 || index >= state.options.length) return;
    final options = List<OptionRowFormData>.from(state.options);
    options[index] = options[index].copyWith(prix: value);
    emit(state.copyWith(options: options));
  }

  void setSaving(bool value) {
    emit(state.copyWith(isSaving: value));
  }

  static double _parsePrice(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(trimmed) ?? 0.0;
  }

  /// Builds [MenuItemOptionGroup] from current form state. Caller must pass
  /// [existingId] and [ordreAffichage] when editing.
  MenuItemOptionGroup buildGroup({
    required String existingId,
    required int ordreAffichage,
  }) {
    final options = state.options
        .where((r) => r.nom.trim().isNotEmpty)
        .map((row) => MenuItemOption(
              id: row.id.startsWith('new_') ? '' : row.id,
              nom: row.nom.trim(),
              prix: _parsePrice(row.prix),
              isAvailable: true,
            ))
        .toList();

    return MenuItemOptionGroup(
      id: existingId,
      nom: state.groupName.trim(),
      isRequired: state.isRequired,
      multipleChoice: state.multipleChoice,
      ordreAffichage: ordreAffichage,
      options: options,
    );
  }
}
