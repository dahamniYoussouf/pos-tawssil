import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:delivery_app/src/core/res/app_theme.dart';
import 'package:delivery_app/src/features/orders/cubit/assigned_order_cubit.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:delivery_app/src/features/orders/pages/order_assigned_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final AssignedOrderCubit? cubit;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    this.cubit,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final GlobalKey<SwipeToConfirmButtonState> _swipeButtonKey =
      GlobalKey<SwipeToConfirmButtonState>();

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)} DA';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final cubit = widget.cubit ?? AssignedOrderCubit();

    // Always refresh the order to ensure we have the latest data
    cubit.fetchOrderById(widget.orderId);

    return BlocProvider<AssignedOrderCubit>.value(
      value: cubit,
      child: BlocListener<AssignedOrderCubit, AssignedOrderState>(
        listener: (context, state) {
          if (state.isActionLoading) {
            _swipeButtonKey.currentState?.reset();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              localizations.clientOrderTitle,
              style: AppTextStyles.gilmerBold.copyWith(
                fontSize: 24,
                color: AppColors.black,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.black,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: BlocBuilder<AssignedOrderCubit, AssignedOrderState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryColor),
                );
              }
              if (state.errorMessage != null && state.order == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.redColor),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<AssignedOrderCubit>()
                              .fetchOrderById(widget.orderId);
                        },
                        child: Text(localizations.retry),
                      ),
                    ],
                  ),
                );
              }
              if (state.order == null) {
                return Center(
                  child: Text(localizations.orderNotFound),
                );
              }
              final order = state.order!;
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map Image Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        MediaRes.mapImage,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Delivery Address
                    _buildSectionHeader(localizations.deliveryAddressHeader),
                    const SizedBox(height: 5),
                    Text(
                      order.restaurantAddress ?? "Baraki, Sidi Moussa",
                      style: AppTextStyles.gilmerMedium.copyWith(
                        fontSize: 16,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Delivery Time
                    _buildSectionHeader(localizations.deliveryTimeHeader),
                    const SizedBox(height: 5),
                    Text(
                      "${order.deliveryTimeMinutes ?? '25-35'} min",
                      style: AppTextStyles.gilmerMedium.copyWith(
                        fontSize: 16,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Order Number
                    _buildSectionHeader(localizations.orderNumberHeader),
                    const SizedBox(height: 5),
                    Text(
                      "#${order.orderNumber}",
                      style: AppTextStyles.gilmerMedium.copyWith(
                        fontSize: 16,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Total
                    _buildSectionHeader(localizations.total),
                    const SizedBox(height: 5),
                    Text(
                      _formatPrice(order.totalPrice),
                      style: AppTextStyles.gilmerMedium.copyWith(
                        fontSize: 16,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Payment Method
                    _buildSectionHeader(localizations.paymentMethodHeader),
                    const SizedBox(height: 5),
                    Text(
                      localizations.cashPayment,
                      style: AppTextStyles.gilmerMedium.copyWith(
                        fontSize: 16,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Order Details
                    _buildSectionHeader(localizations.orderDetailsHeader),
                    const SizedBox(height: 5),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.name} x${item.quantity}',
                                style: AppTextStyles.gilmerMedium.copyWith(
                                  fontSize: 16,
                                  color: AppColors.textMedium,
                                ),
                              ),
                              Text(
                                _formatPrice(item.totalPrice),
                                style: AppTextStyles.gilmerBold.copyWith(
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar:
              _buildStartDeliveryButton(context, localizations),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.gilmerBold.copyWith(
        fontSize: 18,
        color: AppColors.black,
      ),
    );
  }

  Widget _buildStartDeliveryButton(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return BlocBuilder<AssignedOrderCubit, AssignedOrderState>(
      builder: (context, state) {
        final bool isLoading = state.isActionLoading;
        if (state.order == null) {
          return const SizedBox.shrink();
        }
        final OrderModel order = state.order!;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          decoration: const BoxDecoration(
            color: AppColors.white,
          ),
          child: SafeArea(
            child: isLoading
                ? const SizedBox(
                    height: 64,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor),
                      ),
                    ),
                  )
                : SwipeToConfirmButton(
                    key: _swipeButtonKey,
                    label: localizations.startDelivery,
                    onConfirm: () {
                      context
                          .read<AssignedOrderCubit>()
                          .startDelivery(order.id)
                          .whenComplete(() {
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => OrderAssignedPage(
                                orderId: order.id,
                              ),
                            ),
                          );
                        }
                      });
                    },
                  ),
          ),
        );
      },
    );
  }
}

class SwipeToConfirmButton extends StatefulWidget {
  const SwipeToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirm,
  });
  final String label;
  final VoidCallback onConfirm;

  @override
  SwipeToConfirmButtonState createState() => SwipeToConfirmButtonState();
}

class SwipeToConfirmButtonState extends State<SwipeToConfirmButton> {
  double _dragPosition = 0.0;

  void reset() {
    if (!mounted) return;
    setState(() => _dragPosition = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final double buttonHeight = 64.0;
        final double iconSize = 52.0;
        final double padding = 6.0;
        final double maxDragDistance = maxWidth - iconSize - (padding * 2);
        final double threshold = maxDragDistance * 0.85;
        final double clampedPosition =
            _dragPosition.clamp(0.0, maxDragDistance);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            setState(() {
              _dragPosition = (_dragPosition + details.delta.dx)
                  .clamp(0.0, maxDragDistance);
            });
          },
          onHorizontalDragEnd: (_) {
            if (_dragPosition >= threshold) {
              setState(() => _dragPosition = maxDragDistance);
              widget.onConfirm();
            } else {
              setState(() => _dragPosition = 0.0);
            }
          },
          child: Container(
            height: buttonHeight,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Center(
                    child: Text(
                      widget.label,
                      style: AppTextStyles.gilmerBold.copyWith(
                        fontSize: 22,
                        color: AppColors.primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  left: padding + clampedPosition,
                  top: padding,
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_outlined,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
