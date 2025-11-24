import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/features/orders/cubit/assigned_order_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CancelOrderPage extends StatefulWidget {
  final String orderId;

  const CancelOrderPage({
    super.key,
    required this.orderId,
  });

  @override
  State<CancelOrderPage> createState() => _CancelOrderPageState();
}

class _CancelOrderPageState extends State<CancelOrderPage> {
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssignedOrderCubit>(
      create: (context) => AssignedOrderCubit(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocListener<AssignedOrderCubit, AssignedOrderState>(
          listener: (context, state) {
            if (state.errorMessage != null && !state.isActionLoading) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.redColor,
                ),
              );
            } else if (!state.isActionLoading && _selectedReason != null) {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCancelReasonCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelReasonCard(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final List<String> cancelReasons = [
      localizations.cancelReasonDriverLate,
      localizations.cancelReasonClientCanceled,
      localizations.cancelReasonTechnicalIssue,
      localizations.cancelReasonOther,
    ];
    return BlocBuilder<AssignedOrderCubit, AssignedOrderState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(
              color: AppColors.limeGreen,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.cancelOrderQuestion,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 24),
              ...cancelReasons.map((reason) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedReason = reason;
                      });
                    },
                    child: Row(
                      children: [
                        Radio<String>(
                          value: reason,
                          groupValue: _selectedReason,
                          onChanged: (value) {
                            setState(() {
                              _selectedReason = value;
                            });
                          },
                          activeColor: AppColors.limeGreen,
                        ),
                        Expanded(
                          child: Text(
                            reason,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (_selectedReason != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isActionLoading
                        ? null
                        : () {
                            context.read<AssignedOrderCubit>().driverCancelOrder(
                                  widget.orderId,
                                  reason: _selectedReason,
                                );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: state.isActionLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                          )
                        : Text(
                            localizations.confirm,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
