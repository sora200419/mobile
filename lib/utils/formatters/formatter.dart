// lib\utils\formatters\formatter.dart
import 'package:intl/intl.dart';

class FFormatter {
  /// Formats a DateTime object into a string (e.g., MM/dd/yyyy).
  /// Customize the date format as needed.
  static String formatDate(DateTime date) {
    return DateFormat.yMd().format(date);
  }

  /// Formats a numeric amount into a currency string (e.g., $1,234.56).
  /// Customize the locale and currency symbol as needed.
  static String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
  }

  /// Formats a phone number assuming a 10-digit US format, e.g.:
  ///   1234567899 -> (123) 456-7899
  /// If 11 digits, interprets the first digit as a country code, e.g.:
  ///   11234567899 -> 1 (123) 456-7899
  /// Returns the original string if it doesn't match these assumptions.
  static String formatPhoneNumber(String phoneNumber) {
    // Assuming a 10-digit US phone number format: (123) 456-7899
    if (phoneNumber.length == 10) {
      return '(${phoneNumber.substring(0, 3)}) '
          '${phoneNumber.substring(3, 6)}-'
          '${phoneNumber.substring(6)}';
    }
    // If there's an 11-digit number, treat the first digit as country code
    else if (phoneNumber.length == 11) {
      return '${phoneNumber.substring(0, 1)} '
          '(${phoneNumber.substring(1, 4)}) '
          '${phoneNumber.substring(4, 7)}-'
          '${phoneNumber.substring(7)}';
    } else {
      // Return as-is or handle more complex logic if needed
      return phoneNumber;
    }
  }

  /// Attempts a simplistic "international" phone format by:
  ///  1) Removing all non‐digit characters.
  ///  2) Checking if the number starts with '1', then prefixing with +1.
  ///  3) Breaking remaining digits into groups of up to 3, separated by spaces.
  /// Note: This is just an example and not fully tested or standardized.
  static String internationalFormatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    var digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Extract a country code if it starts with '1'
    String countryCode = '';
    if (digitsOnly.startsWith('1')) {
      countryCode = '+1 ';
      digitsOnly = digitsOnly.substring(1);
    }

    // Build the formatted number
    StringBuffer formattedNumber = StringBuffer(countryCode);

    // Loop until all digits are processed, grouping them by up to 3 digits
    while (digitsOnly.isNotEmpty) {
      // Decide how many digits to take in this chunk
      int groupLength = (digitsOnly.length >= 3) ? 3 : digitsOnly.length;

      var group = digitsOnly.substring(0, groupLength);
      digitsOnly = digitsOnly.substring(groupLength);
      formattedNumber.write(group);

      if (digitsOnly.isNotEmpty) {
        formattedNumber.write(' ');
      }
    }

    return formattedNumber.toString();
  }
}
