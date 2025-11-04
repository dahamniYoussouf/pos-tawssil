import 'package:flutter/material.dart';
import '../../auth/services/user_service.dart';
import 'restaurant_search_bar.dart';

class RestaurantSuggestionHeader extends StatelessWidget {
  final String? username;
  final UserLocation? userLocation;
  final VoidCallback onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMessageTap;

  const RestaurantSuggestionHeader({
    Key? key,
    this.username,
    this.userLocation,
    required this.onSearchTap,
    this.onNotificationTap,
    this.onMessageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${userService.getGreetingMessage()}, ${username ?? 'khouloud'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (userLocation != null)
                    Text(
                      '${userLocation!.area}, ${userLocation!.city}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: IconButton(
                        icon: Icon(Icons.notifications, size: 22, color: Colors.black),
                        onPressed: onNotificationTap,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: IconButton(
                        icon: Icon(Icons.message, size: 22, color: Colors.black),
                        onPressed: onMessageTap,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 18),
          GestureDetector(
            onTap: onSearchTap,
            child: RestaurantSearchBar(
              readOnly: true,
              onTap: onSearchTap,
            ),
          ),
        ],
      ),
    );
  }
}
