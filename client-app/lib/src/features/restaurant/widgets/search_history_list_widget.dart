import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/restaurant/cubit/search_history_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../cubit/search_history_cubit.dart';

class SearchHistoryListWidget extends StatelessWidget {
  final Function(String) onHistoryItemTap;
  final Function(String)? onHistoryItemDelete;

  const SearchHistoryListWidget({
    Key? key,
    required this.onHistoryItemTap,
    this.onHistoryItemDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocBuilder<SearchHistoryCubit, SearchHistoryState>(
      builder: (context, state) {
        if (state is SearchHistoryLoaded) {
          if (state.history.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.recentSearches,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ColorApp.textBlack,
                                ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context
                              .read<SearchHistoryCubit>()
                              .clearSearchHistory();
                        },
                        child: Text(
                          localizations.clearHistory,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: ColorApp.primary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: state.history.map((query) {
                    return _SearchHistoryChip(
                      query: query,
                      onTap: () => onHistoryItemTap(query),
                      onDelete: onHistoryItemDelete != null
                          ? () => onHistoryItemDelete!(query)
                          : null,
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SearchHistoryChip extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _SearchHistoryChip({
    Key? key,
    required this.query,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Icons.history,
              size: 16,
              color: ColorApp.grey,
            ),
            const SizedBox(width: 6),
            Text(
              query,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: ColorApp.textBlack,
                  ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  onDelete?.call();
                },
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: ColorApp.greyIconColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
