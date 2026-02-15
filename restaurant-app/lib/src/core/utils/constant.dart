import 'package:restaurant_app/l10n/app_localizations.dart';

const int dioConnectTimeout = 15000;
const int dioReceiveTimeout = 30000;
const int dioSendTimeout = 60000;

const List<String> kDayKeys = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

Map<String, String> getDayLabels(AppLocalizations l10n) => {
      'monday': l10n.monday,
      'tuesday': l10n.tuesday,
      'wednesday': l10n.wednesday,
      'thursday': l10n.thursday,
      'friday': l10n.friday,
      'saturday': l10n.saturday,
      'sunday': l10n.sunday,
    };
