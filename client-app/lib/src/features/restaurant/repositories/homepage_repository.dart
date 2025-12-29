import '../../../core/utils/either.dart';
import '../models/restaurant_model.dart';
import '../models/category_model.dart';
import '../models/homepage_models.dart';
import '../data/datasources/homepage_remote_datasource.dart';

class HomepageData {
  final List<RestaurantModel> restaurants;
  final List<CategoryModel> categories;
  final HomepageDataModel homepageData;

  HomepageData({
    required this.restaurants,
    required this.categories,
    required this.homepageData,
  });
}

class HomepageRepository {
  final HomepageRemoteDataSource _remoteDataSource;

  HomepageRepository({
    HomepageRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? HomepageRemoteDataSource();

  Future<Either<String, HomepageData>> getHomepage({
    String? address,
    double? lat,
    double? lng,
    int radius = 2500,
    String? q,
    List<String>? categories,
    List<String>? homeCategories,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _remoteDataSource.getHomepage(
        address: address,
        lat: lat,
        lng: lng,
        radius: radius,
        q: q,
        categories: categories,
        homeCategories: homeCategories,
        page: page,
        pageSize: pageSize,
      );
      if (response['success'] == true || response.containsKey('data')) {
        final data = response['data'] ?? response;
        if (data is Map<String, dynamic>) {
          final List<RestaurantModel> restaurants = [];
          final List<CategoryModel> categories = [];
          if (data.containsKey('restaurants') && data['restaurants'] is List) {
            final restaurantsList = data['restaurants'] as List;
            restaurants.addAll(
              restaurantsList
                  .map((e) {
                    try {
                      if (e is Map<String, dynamic>) {
                        return RestaurantModel.fromJson(e);
                      }
                      return null;
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<RestaurantModel>()
                  .toList(),
            );
          }
          if (data.containsKey('categories') && data['categories'] is List) {
            final categoriesList = data['categories'] as List;
            categories.addAll(
              categoriesList
                  .map((e) {
                    try {
                      if (e is Map<String, dynamic>) {
                        return CategoryModel.fromJson(e);
                      }
                      return null;
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<CategoryModel>()
                  .toList(),
            );
          }
          final homepageDataModel = HomepageDataModel.fromJson(data);
          final allRestaurants = <RestaurantModel>[];
          allRestaurants.addAll(restaurants);
          allRestaurants.addAll(homepageDataModel.featuredRestaurants);
          if (homepageDataModel.nearby != null) {
            allRestaurants.addAll(homepageDataModel.nearby!.data);
          }
          for (final selection in homepageDataModel.thematicSelections) {
            allRestaurants.addAll(selection.restaurants);
          }
          final uniqueRestaurants = <String, RestaurantModel>{};
          for (final restaurant in allRestaurants) {
            if (!uniqueRestaurants.containsKey(restaurant.id)) {
              uniqueRestaurants[restaurant.id] = restaurant;
            }
          }
          return Right(HomepageData(
            restaurants: uniqueRestaurants.values.toList(),
            categories: categories,
            homepageData: homepageDataModel,
          ));
        }
        return const Left('Invalid response format: data is not a map');
      }
      return Left(
        response['message']?.toString() ?? 'Failed to fetch homepage data',
      );
    } catch (e) {
      return Left('An unexpected error occurred: ${e.toString()}');
    }
  }
}
