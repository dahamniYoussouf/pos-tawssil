import 'package:flutter/material.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_suggestion_page.dart';
import 'package:client_app/src/features/restaurant/widgets/custom_bottom_navigation_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const RestaurantSuggestionPage(),
    const _PlaceholderView(
      icon: Icons.favorite_border,
      title: 'Favorites',
      subtitle: 'Your saved restaurants will appear here soon.',
    ),
    const _PlaceholderView(
      icon: Icons.history,
      title: 'Order History',
      subtitle: 'Track past orders once this feature is ready.',
    ),
    const _PlaceholderView(
      icon: Icons.shopping_cart_outlined,
      title: 'Cart',
      subtitle: 'Items you add will be available here.',
    ),
    const _PlaceholderView(
      icon: Icons.person_outline,
      title: 'Profile',
      subtitle: 'Manage your account details shortly.',
    ),
  ];

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
