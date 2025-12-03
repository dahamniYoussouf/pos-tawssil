import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/categories/models/category_model.dart';
import 'package:restaurant_app/src/features/categories/pages/create_category_page.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/category_selection_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/category_selection_state.dart';
import 'package:restaurant_app/src/features/restaurant/widgets/category_card_widget.dart';
import 'package:restaurant_app/src/features/restaurant/widgets/menu_items_section_widget.dart';
import 'package:restaurant_app/src/features/restaurant/widgets/search_bar_widget.dart';

class CategoriesSectionWidget extends StatefulWidget {
  final List<CategoryModel> categories;

  const CategoriesSectionWidget({
    super.key,
    required this.categories,
  });

  @override
  State<CategoriesSectionWidget> createState() =>
      _CategoriesSectionWidgetState();
}

class _CategoriesSectionWidgetState extends State<CategoriesSectionWidget> {
  final TextEditingController searchController = TextEditingController();
  late final CategorySelectionCubit _categorySelectionCubit;

  @override
  void initState() {
    super.initState();
    _categorySelectionCubit = locator<CategorySelectionCubit>();
    _categorySelectionCubit.initializeWithCategories(widget.categories);
    searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(CategoriesSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categories != oldWidget.categories) {
      _categorySelectionCubit.initializeWithCategories(widget.categories);
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _categorySelectionCubit.updateSearchQuery(searchController.text);
  }

  void _selectCategory(CategoryModel category) {
    _categorySelectionCubit.selectCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocProvider.value(
      value: _categorySelectionCubit,
      child: BlocBuilder<CategorySelectionCubit, CategorySelectionState>(
        builder: (context, state) {
          if (state is CategorySelectionInitial) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchBarWidget(controller: searchController),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    localizations.categories,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: Text(
                        localizations.noCategories,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: widget.categories.length,
                      itemBuilder: (context, index) {
                        final category = widget.categories[index];
                        return CategoryCardWidget(
                          category: category,
                          onDoubleTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreateCategoryPage(category: category),
                              ),
                            );
                          },
                          onTap: () => _selectCategory(category),
                        );
                      },
                    ),
                  ),
                if (state.selectedCategory != null) ...[
                  const SizedBox(height: 16),
                  MenuItemsSectionWidget(
                    category: state.selectedCategory!,
                    searchQuery: state.searchQuery,
                  ),
                ],
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
