import 'package:flutter/material.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/core/utils/constant.dart';

class EditOpeningHoursSheet extends StatefulWidget {
  final Map<String, dynamic> initialHours;
  final void Function(Map<String, dynamic> updatedHours) onSave;

  const EditOpeningHoursSheet({
    super.key,
    required this.initialHours,
    required this.onSave,
  });

  /// Show the sheet as a modal bottom sheet.
  static void show(
    BuildContext context, {
    required Map<String, dynamic> initialHours,
    required void Function(Map<String, dynamic> updatedHours) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditOpeningHoursSheet(
        initialHours: initialHours,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditOpeningHoursSheet> createState() => _EditOpeningHoursSheetState();
}

class _EditOpeningHoursSheetState extends State<EditOpeningHoursSheet> {
  late final Map<String, dynamic> _currentHours;

  @override
  void initState() {
    super.initState();
    _currentHours = Map<String, dynamic>.from(widget.initialHours);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayLabels = getDayLabels(l10n);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.openingHours,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: kDayKeys.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final key = kDayKeys[index];
                final label = dayLabels[key] ?? key;
                return _buildDayRow(key, label, l10n);
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              widget.onSave(_currentHours);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(l10n.saveChanges),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDayRow(String key, String label, AppLocalizations l10n) {
    final value = _currentHours[key] ?? _currentHours[key.substring(0, 3)];

    String openTime = "09:00";
    String closeTime = "18:00";
    bool isClosed = false;

    if (value != null) {
      if (value is String) {
        isClosed = value.toLowerCase().contains('fermé') ||
            value.toLowerCase().contains('closed') ||
            value.toLowerCase() == l10n.closedStatus.toLowerCase();
        if (!isClosed) {
          final parts = value.split(' - ');
          if (parts.length == 2) {
            openTime = parts[0];
            closeTime = parts[1];
          }
        }
      } else if (value is Map) {
        final rawIsClosed = value['is_closed'] ?? value['closed'];
        if (rawIsClosed is bool) {
          isClosed = rawIsClosed;
        } else if (rawIsClosed is int) {
          isClosed = rawIsClosed != 0;
        } else if (rawIsClosed is String) {
          isClosed = rawIsClosed.toLowerCase() == 'true' || rawIsClosed == '1';
        }

        openTime = (value['open'] ?? value['start'] ?? "09:00").toString();
        closeTime = (value['close'] ?? value['end'] ?? "18:00").toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Text(l10n.closedStatus),
                  Switch(
                    value: isClosed,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        if (val) {
                          _currentHours[key] = l10n.closedStatus;
                        } else {
                          _currentHours[key] = "$openTime - $closeTime";
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          if (!isClosed)
            Row(
              children: [
                Expanded(
                    child: _buildTimePicker(openTime, (newOpen) {
                  setState(() {
                    _currentHours[key] = "$newOpen - $closeTime";
                  });
                })),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("-"),
                ),
                Expanded(
                    child: _buildTimePicker(closeTime, (newClose) {
                  setState(() {
                    _currentHours[key] = "$openTime - $newClose";
                  });
                })),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String time, ValueChanged<String> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(time.split(':')[0]),
            minute: int.parse(time.split(':')[1]),
          ),
        );
        if (picked != null) {
          final formatted =
              "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
          onChanged(formatted);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time),
            const Icon(Icons.access_time,
                size: 18, color: AppColors.textLightGrey),
          ],
        ),
      ),
    );
  }
}
