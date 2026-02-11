import 'package:equatable/equatable.dart';

/// Form row for a single option (nom + prix as strings for editing).
class OptionRowFormData extends Equatable {
  final String id;
  final String nom;
  final String prix;

  const OptionRowFormData({
    required this.id,
    required this.nom,
    required this.prix,
  });

  OptionRowFormData copyWith({String? id, String? nom, String? prix}) {
    return OptionRowFormData(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prix: prix ?? this.prix,
    );
  }

  @override
  List<Object?> get props => [id, nom, prix];
}

/// Form state for the option group bottom sheet.
class OptionGroupFormState extends Equatable {
  final String groupName;
  final bool isRequired;
  final bool multipleChoice;
  final List<OptionRowFormData> options;
  final bool isSaving;

  const OptionGroupFormState({
    this.groupName = '',
    this.isRequired = false,
    this.multipleChoice = false,
    this.options = const [],
    this.isSaving = false,
  });

  OptionGroupFormState copyWith({
    String? groupName,
    bool? isRequired,
    bool? multipleChoice,
    List<OptionRowFormData>? options,
    bool? isSaving,
  }) {
    return OptionGroupFormState(
      groupName: groupName ?? this.groupName,
      isRequired: isRequired ?? this.isRequired,
      multipleChoice: multipleChoice ?? this.multipleChoice,
      options: options ?? this.options,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [groupName, isRequired, multipleChoice, options, isSaving];
}
