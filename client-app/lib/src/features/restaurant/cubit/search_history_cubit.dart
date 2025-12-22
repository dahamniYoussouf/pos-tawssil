import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/search_history_repository.dart';
import 'search_history_state.dart';

class SearchHistoryCubit extends Cubit<SearchHistoryState> {
  final SearchHistoryRepository _repository;

  SearchHistoryCubit({
    SearchHistoryRepository? repository,
  })  : _repository = repository ?? SearchHistoryRepository(),
        super(SearchHistoryInitial());

  Future<void> loadSearchHistory() async {
    try {
      final history = await _repository.getSearchHistory();
      if (!isClosed) {
        emit(SearchHistoryLoaded(history: history));
      }
    } catch (e) {
      if (!isClosed) {
        emit(SearchHistoryError(
          message: 'Failed to load search history: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) {
      return;
    }
    try {
      final success = await _repository.saveSearchQuery(query);
      if (success) {
        await loadSearchHistory();
      }
    } catch (e) {
      if (!isClosed && state is SearchHistoryError) {
        emit(SearchHistoryError(
          message: 'Failed to save search query: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> removeSearchQuery(String query) async {
    try {
      final success = await _repository.removeSearchQuery(query);
      if (success) {
        await loadSearchHistory();
      }
    } catch (e) {
      if (!isClosed && state is SearchHistoryError) {
        emit(SearchHistoryError(
          message: 'Failed to remove search query: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> clearSearchHistory() async {
    try {
      final success = await _repository.clearSearchHistory();
      if (success) {
        await loadSearchHistory();
      }
    } catch (e) {
      if (!isClosed && state is SearchHistoryError) {
        emit(SearchHistoryError(
          message: 'Failed to clear search history: ${e.toString()}',
        ));
      }
    }
  }
}
