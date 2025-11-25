import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:delivery_app/src/features/orders/cubit/assigned_order_cubit.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
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
  final GlobalKey<SwipeToConfirmButtonState> _swipeButtonKey = GlobalKey<SwipeToConfirmButtonState>();

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
            title: _buildHeader(localizations),
            elevation: 0,
            centerTitle: true,
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
                  child: CircularProgressIndicator(),
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
                          context.read<AssignedOrderCubit>().fetchOrderById(widget.orderId);
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildRestaurantCard(context, order, localizations),
                    const SizedBox(height: 16),
                    _buildClientSection(order, localizations),
                    const SizedBox(height: 16),
                    _buildOrderDetailsCard(context, order, localizations),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: _buildStartDeliveryButton(context, localizations),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Text(
      localizations.clientOrderTitle,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
    );
  }

  Widget _buildRestaurantCard(
    BuildContext context,
    OrderModel order,
    AppLocalizations localizations,
  ) {
    final String restaurantName = order.restaurantName ?? localizations.restaurant;
    final String restaurantAddress = order.restaurantAddress ?? '';
    final double totalPrice = order.totalPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyVeryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurantName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: AppColors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  restaurantAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    MediaRes.cashIcon,
                    height: 18,
                    width: 18,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    localizations.total,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              Text(
                _formatPrice(totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection(OrderModel order, AppLocalizations localizations) {
    final String clientName = order.client?.name ?? localizations.clientLabel;
    return Text(
      '${localizations.clientLabel} : $clientName',
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.black,
      ),
    );
  }

  Widget _buildOrderDetailsCard(
    BuildContext context,
    OrderModel order,
    AppLocalizations localizations,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyVeryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${localizations.orderNumberLabel}:',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryColor,
                ),
              ),
              Text(
                '#${order.orderNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryColor, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  Text(
                    _formatPrice(item.totalPrice),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
          ),
          child: SafeArea(
            child: isLoading
                ? const SizedBox(
                    height: 56,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.limeGreen),
                      ),
                    ),
                  )
                : SwipeToConfirmButton(
                    key: _swipeButtonKey,
                    label: localizations.startDelivery,
                    onConfirm: () {
                      context.read<AssignedOrderCubit>().startDelivery(order.id).whenComplete(() {
                        if (context.mounted) {
                          Navigator.of(context).pop();
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
        final double buttonHeight = 56.0;
        final double iconSize = 44.0;
        final double padding = 4.0;
        final double maxDragDistance = maxWidth - iconSize - (padding * 2);
        final double threshold = maxDragDistance * 0.85;
        final double clampedPosition = _dragPosition.clamp(0.0, maxDragDistance);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            setState(() {
              _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDragDistance);
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.limeGreen.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: Center(
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.limeGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  left: padding + clampedPosition,
                  top: padding,
                  child: GestureDetector(
                    onTap: () {
                      if (_dragPosition < threshold) {
                        setState(() => _dragPosition = maxDragDistance);
                        Future<void>.delayed(const Duration(milliseconds: 300), () {
                          if (!mounted) return;
                          widget.onConfirm();
                        });
                      }
                    },
                    child: Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_outlined,
                        color: AppColors.white,
                        size: 24,
                      ),
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
