import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_state.dart';
import 'package:restaurant_app/src/features/restaurant/models/restaurant_model.dart';

class RestaurantStatusBadge extends StatelessWidget {
  const RestaurantStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<RestaurantCubit, RestaurantState>(
      builder: (context, state) {
        if (state is RestaurantLoaded) {
          final status =
              state.restaurant.status?.toLowerCase() ?? RestaurantStatus.open;

          Color color;
          String label;

          switch (status) {
            case RestaurantStatus.open:
              color = const Color(0xFF22C55E); // Green
              label = localizations.statusOpen;
              break;
            case RestaurantStatus.closed:
              color = AppColors.red;
              label = localizations.statusClosed;
              break;
            case RestaurantStatus.vacation:
              color = const Color(0xFF6366F1); // Indigo
              label = localizations.statusVacation;
              break;
            case RestaurantStatus.saturated:
              color = const Color(0xFFEA580C); // Dark Orange
              label = localizations.statusSaturated;
              break;
            case RestaurantStatus.other:
              color = AppColors.textGrey;
              label = localizations.statusOther;
              break;
            default:
              color = AppColors.red;
              label = localizations.statusClosed;
          }

          return GestureDetector(
            onTap: () => _showStatusBottomSheet(context, status),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.greyLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showStatusBottomSheet(BuildContext context, String currentStatus) {
    final localizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.closeRestaurantTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 24),

              // Options
              if (currentStatus != RestaurantStatus.open)
                _buildStatusOption(
                  context: context,
                  icon: Icons.check_circle,
                  color: const Color(0xFF22C55E),
                  title: localizations.statusOpen,
                  subtitle: localizations.statusOpenSubtitle,
                  statusValue: RestaurantStatus.open,
                ),

              const SizedBox(height: 12),

              _buildStatusOption(
                context: context,
                icon: Icons.cancel,
                color: AppColors.red,
                title: localizations.statusClosed,
                subtitle: localizations.statusClosedSubtitle,
                statusValue: RestaurantStatus.closed,
              ),

              const SizedBox(height: 12),

              _buildStatusOption(
                context: context,
                icon: Icons.beach_access,
                color: const Color(0xFF6366F1),
                title: localizations.statusVacation,
                subtitle: localizations.statusVacationSubtitle,
                statusValue: RestaurantStatus.vacation,
              ),

              const SizedBox(height: 12),

              _buildStatusOption(
                context: context,
                icon: Icons.error_outline,
                color: const Color(0xFFEA580C),
                title: localizations.statusSaturated,
                subtitle: localizations.statusSaturatedSubtitle,
                statusValue: RestaurantStatus.saturated,
              ),

              const SizedBox(height: 12),

              _buildStatusOption(
                context: context,
                icon: Icons.more_horiz,
                color: AppColors.textGrey,
                title: localizations.statusOther,
                subtitle: localizations.statusOtherSubtitle,
                statusValue: RestaurantStatus.other,
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String statusValue,
  }) {
    return InkWell(
      onTap: () async {
        if (statusValue == RestaurantStatus.other) {
          Navigator.pop(context); // Close bottom sheet
          final String? note = await _showNoteDialog(context);
          if (note != null && note.isNotEmpty) {
            if (context.mounted) {
              context
                  .read<RestaurantCubit>()
                  .updateStatus(statusValue, note: note);
            }
          }
        } else {
          context.read<RestaurantCubit>().updateStatus(statusValue);
          Navigator.pop(context);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLightGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showNoteDialog(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.statusOther),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: localizations.availabilityNoteHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.update),
          ),
        ],
      ),
    );
  }
}
