import 'package:client_app/src/features/restaurant/cubit/restaurant_search_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_state.dart';
import '../cubit/restaurant_search_cubit.dart';
import '../cubit/search_history_cubit.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/search_history_list_widget.dart';
import '../widgets/search_loading_widget.dart';
import '../widgets/search_error_widget.dart';
import '../widgets/search_empty_widget.dart';
import '../widgets/search_initial_widget.dart';
import '../widgets/search_results_list_widget.dart';

class RestaurantSearchPage extends StatefulWidget {
  final String? initialQuery;

  const RestaurantSearchPage({
    Key? key,
    this.initialQuery,
  }) : super(key: key);

  @override
  State<RestaurantSearchPage> createState() => _RestaurantSearchPageState();
}

class _RestaurantSearchPageState extends State<RestaurantSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  static const int _maxResults = 50;

  @override
  void initState() {
    super.initState();
    _initializeSearch();
    _loadUserLocation();
    _loadSearchHistory();
  }

  void _initializeSearch() {
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
    _searchController.addListener(_onSearchChanged);
  }

  void _loadUserLocation() {
    context.read<LocationCubit>().loadSavedLocation();
  }

  void _loadSearchHistory() {
    context.read<SearchHistoryCubit>().loadSearchHistory();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      context.read<RestaurantSearchCubit>().clearSearch();
      return;
    }

    // Debounce search to avoid too many API calls
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      context.read<RestaurantSearchCubit>().clearSearch();
      return;
    }

    final trimmedQuery = query.trim();
    context.read<SearchHistoryCubit>().addSearchQuery(trimmedQuery);

    final locationState = context.read<LocationCubit>().state;
    double? lat;
    double? lng;

    if (locationState is LocationSuccess) {
      if (locationState.latitude != null && locationState.longitude != null) {
        lat = locationState.latitude;
        lng = locationState.longitude;
      }
    }

    context.read<RestaurantSearchCubit>().searchRestaurants(
          query: trimmedQuery,
          lat: lat,
          lng: lng,
          pageSize: _maxResults,
        );
  }

  void _onHistoryItemTap(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _onHistoryItemDelete(String query) {
    context.read<SearchHistoryCubit>().removeSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SearchBarWidget(controller: _searchController),
            BlocBuilder<RestaurantSearchCubit, RestaurantSearchState>(
              builder: (context, searchState) {
                if (searchState is RestaurantSearchInitial) {
                  return SearchHistoryListWidget(
                    onHistoryItemTap: _onHistoryItemTap,
                    onHistoryItemDelete: _onHistoryItemDelete,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: BlocBuilder<RestaurantSearchCubit, RestaurantSearchState>(
                builder: (context, state) {
                  if (state is RestaurantSearchLoading) {
                    return SearchLoadingWidget(state: state);
                  }
                  if (state is RestaurantSearchError) {
                    return SearchErrorWidget(
                      state: state,
                      currentQuery: _searchController.text.trim(),
                    );
                  }
                  if (state is RestaurantSearchResults) {
                    if (state.restaurants.isEmpty) {
                      return SearchEmptyWidget(state: state);
                    }
                    return SearchResultsListWidget(state: state);
                  }
                  return const SearchInitialWidget();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
