import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/orders/zone_orders/presentation/cubit/zone_orders_cubit.dart';
import 'package:delivery_app/src/features/orders/zone_orders/presentation/cubit/zone_orders_state.dart';
import 'package:delivery_app/src/features/orders/zone_orders/presentation/widgets/zone_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ZoneOrdersPage extends StatelessWidget {
  const ZoneOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ZoneOrdersCubit>(
      create: (_) => locator<ZoneOrdersCubit>()..loadZones(),
      child: const _ZoneOrdersView(),
    );
  }
}

class _ZoneOrdersView extends StatefulWidget {
  const _ZoneOrdersView();

  @override
  State<_ZoneOrdersView> createState() => _ZoneOrdersViewState();
}

class _ZoneOrdersViewState extends State<_ZoneOrdersView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF123A2B),
              Color(0xFF4F5E5A),
              Color(0xFF77807D),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: -120,
              left: 0,
              right: 0,
              child: _RadarRings(),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _RoundIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        Image.asset(
                          MediaRes.logo,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                        const Spacer(),
                        const SizedBox(width: 42),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SearchInput(
                      controller: _searchController,
                      onChanged: (value) {
                        context.read<ZoneOrdersCubit>().loadZones(query: value);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 8,
                          color: Color(0xFF67F75B),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ZONES ACTIVES',
                          style: TextStyle(
                            color: Color(0xFF67F75B),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        _RoundIconButton(
                          icon: Icons.refresh_rounded,
                          onTap: () {
                            context.read<ZoneOrdersCubit>().loadZones(
                                  query: _searchController.text,
                                );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BlocBuilder<ZoneOrdersCubit, ZoneOrdersState>(
                        builder: (context, state) {
                          if (state is ZoneOrdersLoading &&
                              state.zones.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF67F75B),
                              ),
                            );
                          }

                          if (state is ZoneOrdersError && state.zones.isEmpty) {
                            return Center(
                              child: Text(
                                state.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }

                          if (state.zones.isEmpty) {
                            return const Center(
                              child: Text(
                                'Aucune zone trouvee',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 180),
                            itemCount: state.zones.length,
                            itemBuilder: (context, index) {
                              final zone = state.zones[index];
                              return ZoneOrderCard(
                                zone: zone,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Zone selectionnee: ${zone.name}'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchInput({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Rechercher une zone...',
          hintStyle: TextStyle(color: Color(0xB3E5E7EB), fontSize: 18),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0x99E5E7EB)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 17),
        ),
      ),
    );
  }
}

class _RadarRings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 210,
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _ring(210, 0.18),
            _ring(160, 0.22),
            _ring(110, 0.3),
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF67F75B),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xAA67F75B),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF67F75B).withValues(alpha: opacity),
          width: 1.4,
        ),
      ),
    );
  }
}
