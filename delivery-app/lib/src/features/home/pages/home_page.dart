import 'package:delivery_app/src/features/home/widgets/custom_bottom_navigation_bar.dart';
import 'package:delivery_app/src/features/orders/pages/order_history_page.dart';
import 'package:delivery_app/src/features/orders/pages/track_orders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_app/src/features/notifications/cubit/notifications_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_state.dart';
import 'package:delivery_app/src/features/profile/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<DriverCubit>().fetchDriverProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsCubit>().connect();
    });
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  late final List<Widget> _pages = [
    const TrackOrdersPage(),
    const _PlaceholderView(title: 'Mes Commandes'),
    const OrderHistoryPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverCubit, DriverState>(
      builder: (context, driverState) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
          ),
        );
      },
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  final String title;
  const _PlaceholderView({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
