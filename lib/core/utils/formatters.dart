import 'package:intl/intl.dart';

/// Formatting utilities for the application
/// All formatters use French locale per constitution requirements
class Formatters {
  Formatters._();

  // Lazy-initialized formatters - use patterns without locale to avoid initialization issues
  static DateFormat? _dateFormat;
  static DateFormat? _dateTimeFormat;
  static DateFormat? _fullDateFormat;
  static DateFormat? _timeFormat;
  static DateFormat? _monthYearFormat;

  /// Date format: DD/MM/YYYY
  static DateFormat get dateFormat => _dateFormat ??= DateFormat('dd/MM/yyyy');

  /// Date and time format: DD/MM/YYYY HH:mm
  static DateFormat get dateTimeFormat => _dateTimeFormat ??= DateFormat('dd/MM/yyyy HH:mm');

  /// Full date format: Day DD Month YYYY (simplified without locale-specific day names)
  static DateFormat get fullDateFormat => _fullDateFormat ??= DateFormat('dd/MM/yyyy');

  /// Time format: HH:mm
  static DateFormat get timeFormat => _timeFormat ??= DateFormat('HH:mm');

  /// Month and year format: Month YYYY (simplified)
  static DateFormat get monthYearFormat => _monthYearFormat ??= DateFormat('MM/yyyy');

  /// Format date as DD/MM/YYYY
  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }

  /// Format date and time as DD/MM/YYYY HH:mm
  static String formatDateTime(DateTime date) {
    return dateTimeFormat.format(date);
  }

  /// Format full date as Day DD Month YYYY
  static String formatFullDate(DateTime date) {
    return fullDateFormat.format(date);
  }

  /// Format time as HH:mm
  static String formatTime(DateTime date) {
    return timeFormat.format(date);
  }

  /// Format month and year as Month YYYY
  static String formatMonthYear(DateTime date) {
    return monthYearFormat.format(date);
  }

  /// Format relative time (e.g., "il y a 2 jours")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return "A l'instant";
        }
        return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
      }
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }

  /// Format currency in CFA Franc
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format number with French thousands separator
  static String formatNumber(int number) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return formatter.format(number);
  }
}
