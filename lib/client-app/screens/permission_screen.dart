import 'package:flutter/material.dart';
import 'package:frontend/client-app/screens/restaurant_suggestion_page.dart';
import 'package:frontend/client-app/screens/sharing_screen.dart';
import 'package:frontend/client-app/screens/first_page.dart';

class PermissionScreen extends StatelessWidget {
  final VoidCallback onAuthorized;
  final VoidCallback onDenied;

  const PermissionScreen({
    Key? key,
    required this.onAuthorized,
    required this.onDenied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF006C4A),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Text(
                    'Autoriser « tawsil » à utiliser votre position ?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Afin de détecter les partenaires autour de vous, nous devons utiliser votre localisation',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  Container(
                    height: 155,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/permission_map.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Column(
                    children: [
                      _buildPermissionButton(context, 'Autoriser une fois', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SharingScreen(
                              onShareLocation: () {},
                              onAddAddress: () {},
                              onGpsDisabled: () {},
                            ),
                          ),
                        );
                      }),
                      _buildPermissionButton(context,
                          'Autoriser lorsque l\'app est active', onAuthorized),
                      _buildPermissionButton(
                          context, 'Ne pas autoriser', onDenied,
                          isLast: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionButton(
      BuildContext context, String text, VoidCallback onPressed,
      {bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => SharingScreen(onShareLocation: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => RestaurantSuggestionPage()),
                );
              }, onAddAddress: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => RestaurantSuggestionPage()),
                );
              }, onGpsDisabled: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => RestaurantSuggestionPage()),
                );
              }),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.only(left: 10)),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF87CEEB),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
