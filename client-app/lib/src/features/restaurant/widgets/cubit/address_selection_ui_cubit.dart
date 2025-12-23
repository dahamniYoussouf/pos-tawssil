import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AddressSelectionUiState extends Equatable {
  const AddressSelectionUiState();

  @override
  List<Object?> get props => [];
}

class AddressSelectionUiInitial extends AddressSelectionUiState {
  final bool isExpanded;

  const AddressSelectionUiInitial({this.isExpanded = true});

  @override
  List<Object?> get props => [isExpanded];
}

class AddressSelectionUiCubit extends Cubit<AddressSelectionUiState> {
  AddressSelectionUiCubit() : super(const AddressSelectionUiInitial());

  void toggleExpanded() {
    final currentState = state;
    if (currentState is AddressSelectionUiInitial) {
      emit(AddressSelectionUiInitial(isExpanded: !currentState.isExpanded));
    }
  }
}

