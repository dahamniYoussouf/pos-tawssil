import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/features/orders/pages/order_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/features/auth/cubit/auth_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<DriverCubit>().fetchDriverProfile();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<DriverCubit, DriverState>(
      builder: (context, driverState) {
        return Scaffold(
          backgroundColor: AppColors.white,
          drawer: Drawer(
            child: Column(
              children: [
                Text('Hello'),
              ],
            ),
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              localizations.orders,
              style: TextStyle(color: AppColors.primaryColor),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: AppColors.primaryColor,
                ),
                onPressed: () {
                  context.read<AuthCubit>().logout();
                },
              ),
            ],
          ),
          body: driverState is DriverError
              ? Center(child: Text(driverState.message))
              : driverState is DriverLoaded
                  ? OrderPage()
                  : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
