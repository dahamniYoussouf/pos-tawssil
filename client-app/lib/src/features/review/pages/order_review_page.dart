import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/res/color_app.dart';
import '../../../core/utils/dependency_injection.dart';
import '../../home/pages/home_page.dart';
import '../cubit/review_cubit.dart';
import '../cubit/review_state.dart';

class OrderReviewPage extends StatefulWidget {
  final String orderId;

  const OrderReviewPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends State<OrderReviewPage> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => locator<ReviewCubit>(),
      child: BlocConsumer<ReviewCubit, ReviewState>(
        listener: (context, state) {
          if (state is ReviewSuccess) {
            // Navigate to home page after successful review
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          } else if (state is ReviewError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ColorApp.redColor,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ReviewLoading;
          final l10n = AppLocalizations.of(context)!;

          return Scaffold(
            backgroundColor: ColorApp.white,
            appBar: AppBar(
              backgroundColor: ColorApp.white,
              elevation: 0,
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                      color: ColorApp.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ColorApp.greyMedium.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ]),
                  child:
                      Icon(Icons.arrow_back, color: ColorApp.black, size: 20),
                ),
              ),
              centerTitle: true,
              title: Text(
                l10n.orderRating,
                style: const TextStyle(
                  color: ColorApp.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    // Delivery evaluation subtitle
                    Text(
                      l10n.deliveryEvaluation,
                      style: const TextStyle(
                        color: ColorApp.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Delivery truck icon
                    Image.asset(
                      MediaRes.orderReviewImage,
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 32),
                    // Star rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Image.asset(
                              index < _rating
                                  ? MediaRes.starImage
                                  : MediaRes.starBorderImage,
                              width: 55,
                              height: 55,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 40),
                    // Review text field
                    Container(
                      decoration: BoxDecoration(
                        color: ColorApp.backgroundGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _reviewController,
                        maxLines: 6,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          hintText: l10n.typeYourReview,
                          hintStyle: TextStyle(
                            color: ColorApp.greyMedium,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: const TextStyle(
                          color: ColorApp.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    // Skip order review, go to home
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const HomePage(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                            child: Text(
                              l10n.skip,
                              style: const TextStyle(
                                color: ColorApp.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: isLoading || _rating == 0
                                ? null
                                : () {
                                    context
                                        .read<ReviewCubit>()
                                        .submitOrderReview(
                                          orderId: widget.orderId,
                                          rating: _rating,
                                          comment:
                                              _reviewController.text.isNotEmpty
                                                  ? _reviewController.text
                                                  : null,
                                        );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorApp.primary,
                              foregroundColor: ColorApp.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: ColorApp.greyLight,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          ColorApp.white),
                                    ),
                                  )
                                : Text(
                                    l10n.submit,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
