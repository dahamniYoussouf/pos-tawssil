import 'package:flutter/material.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';

class OrderCardShimmer extends StatelessWidget {
  const OrderCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderShimmer(),
            const SizedBox(height: 16),
            _buildItemsListShimmer(),
            const SizedBox(height: 16),
            _buildDeliveryDetailsShimmer(),
            const SizedBox(height: 16),
            _buildTotalPriceShimmer(),
            const SizedBox(height: 16),
            _buildActionButtonsShimmer(),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(borderRadius ?? 4),
      ),
    );
  }

  Widget _buildHeaderShimmer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(width: 150, height: 24),
              const SizedBox(height: 8),
              _buildShimmerBox(width: 120, height: 16),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildShimmerBox(width: 100, height: 16),
            const SizedBox(height: 8),
            _buildShimmerBox(width: 80, height: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsListShimmer() {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _buildShimmerBox(width: 50, height: 50, borderRadius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(width: double.infinity, height: 18),
                    const SizedBox(height: 8),
                    _buildShimmerBox(width: 40, height: 14),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildShimmerBox(width: 60, height: 18),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDeliveryDetailsShimmer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.limeGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < 2 ? 8 : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildShimmerBox(width: 100, height: 14),
                _buildShimmerBox(width: 60, height: 14),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTotalPriceShimmer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildShimmerBox(width: 100, height: 18),
        _buildShimmerBox(width: 80, height: 24),
      ],
    );
  }

  Widget _buildActionButtonsShimmer() {
    return Row(
      children: [
        Expanded(
          child: _buildShimmerBox(width: double.infinity, height: 48, borderRadius: 8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildShimmerBox(width: double.infinity, height: 48, borderRadius: 8),
        ),
      ],
    );
  }
}

