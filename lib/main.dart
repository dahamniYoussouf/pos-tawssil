import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

// BLoC Imports
import 'client-app/blocs/auth/auth_cubit.dart';
import 'client-app/blocs/location/location_cubit.dart';
import 'client-app/blocs/cart/cart_cubit.dart';
import 'client-app/blocs/restaurant/restaurant_cubit.dart';

// Screen Imports
import 'client-app/screens/phone_num.dart';
import 'client-app/screens/location_screen.dart';
import 'client-app/screens/Consulter_le_panier.dart';
import 'client-app/screens/Valider_la_commande.dart';

// Service Imports
import 'client-app/screens/auth_service.dart';
import 'client-app/services/location_service.dart';
import 'client-app/services/cart_service.dart';
import 'client-app/services/restaurant_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authService: AuthService()),
        ),
        BlocProvider<LocationCubit>(
          create: (context) => LocationCubit(),
        ),
        BlocProvider<CartCubit>(
          create: (context) => CartCubit(cartService: CartService()),
        ),
        BlocProvider<RestaurantCubit>(
          create: (context) =>
              RestaurantCubit(restaurantService: RestaurantService()),
        ),
      ],
      child: MaterialApp(
        title: 'Tawsil',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        home: PhoneNumberPage(),
      ),
    );
  }
}
