import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/features/auth/cubit/location_search_cubit.dart';
import 'package:restaurant_app/src/features/auth/cubit/location_search_state.dart';
import 'package:restaurant_app/src/features/auth/models/location_selection.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';

typedef LocationSelectionCallback = void Function(LocationSelection selection);

class LocationSearchField extends StatelessWidget {
  final TextEditingController controller;
  final LocationSelectionCallback onLocationSelected;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocationSearchCubit>(
      create: (_) => LocationSearchCubit(),
      child: _LocationSearchFieldBody(
        controller: controller,
        onLocationSelected: onLocationSelected,
      ),
    );
  }
}

class _LocationSearchFieldBody extends StatefulWidget {
  final TextEditingController controller;
  final LocationSelectionCallback onLocationSelected;

  const _LocationSearchFieldBody({
    required this.controller,
    required this.onLocationSelected,
  });

  @override
  State<_LocationSearchFieldBody> createState() => _LocationSearchFieldBodyState();
}

class _LocationSearchFieldBodyState extends State<_LocationSearchFieldBody> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    context.read<LocationSearchCubit>().searchLocation(
          query: widget.controller.text,
          emptyQueryMessage: localizations.errorLocationRequired,
          notFoundMessage: localizations.errorLocationNotFound,
          genericErrorMessage: localizations.errorLocationLookupFailed,
        );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return BlocConsumer<LocationSearchCubit, LocationSearchState>(
      listener: (context, state) {
        if (state is LocationSearchSuccess) {
          widget.onLocationSelected(state.selection);
          _focusNode.unfocus();
        } else if (state is LocationSearchError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final bool isLoading = state is LocationSearchLoading;
        final LocationSelection? selection = state is LocationSearchSuccess ? state.selection : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.locationSearchLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                  hintText: localizations.locationSearchHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primaryColor,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primaryColor),
                    onPressed: _handleSearch,
                  ),
                  suffixIcon: selection != null
                      ? const Icon(Icons.check, color: AppColors.primaryColor)
                      : isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryColor,
                              ),
                            )
                          : const Icon(Icons.location_on, color: AppColors.primaryColor)),
            ),
          ],
        );
      },
    );
  }
}
