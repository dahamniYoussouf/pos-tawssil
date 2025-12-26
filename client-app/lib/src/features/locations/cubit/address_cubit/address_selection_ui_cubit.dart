import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AddressSelectionUiState extends Equatable {
  const AddressSelectionUiState();

  @override
  List<Object?> get props => [];
}

class AddressSelectionUiInitial extends AddressSelectionUiState {
  final bool isExpanded;
  final String searchQuery;

  const AddressSelectionUiInitial({
    this.isExpanded = true,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [isExpanded, searchQuery];
}

class AddressSelectionUiCubit extends Cubit<AddressSelectionUiState> {
  AddressSelectionUiCubit() : super(const AddressSelectionUiInitial());

  void toggleExpanded() {
    final currentState = state;
    if (currentState is AddressSelectionUiInitial) {
      emit(AddressSelectionUiInitial(
        isExpanded: !currentState.isExpanded,
        searchQuery: currentState.searchQuery,
      ));
    }
  }

  void updateSearchQuery(String query) {
    final currentState = state;
    if (currentState is AddressSelectionUiInitial) {
      emit(AddressSelectionUiInitial(
        isExpanded: currentState.isExpanded,
        searchQuery: query,
      ));
    }
  }

  void clearSearchQuery() {
    final currentState = state;
    if (currentState is AddressSelectionUiInitial) {
      emit(AddressSelectionUiInitial(
        isExpanded: currentState.isExpanded,
        searchQuery: '',
      ));
    }
  }
}
