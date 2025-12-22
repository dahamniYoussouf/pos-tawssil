import 'package:flutter/material.dart';
import '../cubit/restaurant_search_state.dart';
import '../widgets/restaurant_search_card.dart';
import '../pages/restaurant_details_page.dart';

class SearchResultsListWidget extends StatelessWidget {
  final RestaurantSearchResults state;

  const SearchResultsListWidget({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = state.restaurants[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RestaurantDetailsPage(restaurant: restaurant),
              ),
            );
          },
          child: RestaurantCard(restaurant: restaurant),
        );
      },
    );
  }
}

