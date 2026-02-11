import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared display formatting helpers to avoid duplication across widgets.

/// Formats a [DateTime] for display in the UI (e.g. "5 Feb 2026, 14:30").
/// Uses the provided [locale] for localization, defaults to 'fr'.
String formatDisplayDate(DateTime? date, [String locale = 'fr']) {
  if (date == null) return '';
  return DateFormat('d MMM yyyy, HH:mm', locale).format(date);
}

/// Formats a [DateTime] for display with AM/PM (e.g. "5 Feb 2026 ,02:30 PM").
String formatDisplayDateAmPm(DateTime? date, [String locale = 'fr']) {
  if (date == null) return '';
  return DateFormat('d MMM yyyy ,hh:mm a', locale).format(date);
}

/// Formats a [DateTime] for display using the device locale from [BuildContext].
String formatDisplayDateLocalized(DateTime? date, BuildContext context) {
  if (date == null) return '';
  final locale = Localizations.localeOf(context).languageCode;
  return DateFormat('d MMM yyyy, HH:mm', locale).format(date);
}

/// Formats a [DateTime] as an ISO date string for API calls (e.g. "2026-02-05").
String formatIsoDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Formats a [price] for display with DA currency (e.g. "1,500DA").
String formatPrice(double price) {
  return '${NumberFormat('#,###').format(price)}DA';
}

/// Formats a [DateTime] as a header date with "Aujourd'hui" prefix for today.
String formatHeaderDate(DateTime? date, BuildContext context) {
  if (date == null) return '';
  final locale = Localizations.localeOf(context).languageCode;
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  final prefix = isToday ? 'Aujourd\'hui - ' : '';
  return '$prefix${DateFormat('d MMMM yyyy', locale).format(date)}';
}

/// Formats a [price] for display with DA currency (e.g. "1,500 DA").
String formatPriceSpaced(double price) {
  return '${NumberFormat('#,###').format(price)} DA';
}
