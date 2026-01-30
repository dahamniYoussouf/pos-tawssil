import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/auth/cubit/user_cubit.dart';
import 'package:client_app/src/features/auth/cubit/user_state.dart';
import 'package:client_app/src/features/order/widgets/current_order_card_widget.dart';
import '../cubit/homepage_cubit.dart';
import '../cubit/homepage_state.dart';
import '../widgets/restaurant_suggestion_header.dart';
import 'home_page.dart';
import '../widgets/restaurant_suggestion_widgets.dart';

class RestaurantSuggestionPage extends StatefulWidget {
  const RestaurantSuggestionPage({Key? key}) : super(key: key);

  @override
  State<RestaurantSuggestionPage> createState() =>
      _RestaurantSuggestionPageState();
}

class _RestaurantSuggestionPageState extends State<RestaurantSuggestionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserCubit>().fetchProfile();
      context.read<LocationCubit>().loadSavedLocation();
      final homepageCubit = context.read<HomepageCubit>();
      if (homepageCubit.state is! HomepageLoaded) {
        homepageCubit.loadHomepage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.white,
      body: SafeArea(
        child: BlocBuilder<UserCubit, UserState>(
          builder: (context, userState) {
            if (userState is UserLoading) {
              return const LoadingStateWidget();
            }
            if (userState is UserError) {
              return ErrorStateWidget(
                message: userState.message,
                onRetry: () => context.read<UserCubit>().fetchProfile(),
              );
            }
            if (userState is UserLoaded) {
              return BlocBuilder<HomepageCubit, HomepageState>(
                builder: (context, homepageState) {
                  if (homepageState is HomepageLoading) {
                    return const LoadingStateWidget();
                  }
                  if (homepageState is HomepageError) {
                    return ErrorStateWidget(
                      message: homepageState.message,
                      onRetry: () =>
                          context.read<HomepageCubit>().loadHomepage(),
                    );
                  }
                  if (homepageState is HomepageLoaded) {
                    return RefreshIndicator(
                      color: ColorApp.primary,
                      backgroundColor: ColorApp.white,
                      strokeWidth: 3.0,
                      displacement: 40.0,
                      edgeOffset: 0.0,
                      triggerMode: RefreshIndicatorTriggerMode.onEdge,
                      onRefresh: () async {
                        await context.read<HomepageCubit>().loadHomepage();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            const RestaurantSuggestionHeader(),
                            HomePage(
                              homepageData: homepageState.homepageData,
                              allRestaurants: homepageState.restaurants,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const LoadingStateWidget();
                },
              );
            }
            return const LoadingStateWidget();
          },
        ),
      ),
      floatingActionButton: CurrentOrderCardWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
