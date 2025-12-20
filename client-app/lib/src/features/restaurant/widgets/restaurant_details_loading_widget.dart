import 'package:flutter/material.dart';

class RestaurantDetailsLoadingWidget extends StatelessWidget {
  const RestaurantDetailsLoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

