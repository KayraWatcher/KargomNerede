import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  double get statusBarHeight => mediaQuery.padding.top;
  double get bottomPadding => mediaQuery.padding.bottom;
  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isKeyboardOpen => mediaQuery.viewInsets.bottom > 0;
  NavigatorState get navigator => Navigator.of(this);
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);
  FocusScopeNode get focusScope => FocusScope.of(this);
}

extension StringExtensions on String {
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  
  String get titleCase => split(' ').map((word) => word.capitalize).join(' ');
  
  String get maskTrackingNumber {
    if (length <= 8) return this;
    final visible = length - 8;
    return '${substring(0, visible)}${'*' * 8}';
  }

  String formatTurkishPhone() {
    final digits = replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+90 (${digits.substring(0, 3)}) ${digits.substring(3, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
    }
    if (digits.length == 11 && digits.startsWith('0')) {
      return '+90 (${digits.substring(1, 4)}) ${digits.substring(4, 7)} ${digits.substring(7, 9)} ${digits.substring(9)}';
    }
    return this;
  }

  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  
  bool get isValidTurkishPhone => RegExp(r'^(\+90|0)?5\d{9}$').hasMatch(replaceAll(RegExp(r'\s|\(|\)'), ''));

  String truncate({int maxLength = 50, String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  String removeTurkishChars() => replaceAllMapped(
    RegExp(r'[çğıöşüÇĞIİÖŞÜ]'),
    (match) => const {
      'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
      'Ç': 'C', 'Ğ': 'G', 'I': 'I', 'İ': 'I', 'Ö': 'O', 'Ş': 'S', 'Ü': 'U',
    }[match.group(0)]!,
  );

  String normalizeForSearch() {
    return removeTurkishChars().toLowerCase().trim();
  }
}

extension DateTimeExtensions on DateTime {
  String formatTurkish({bool withTime = false}) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final day = this.day;
    final month = months[this.month - 1];
    final year = this.year;
    final dateStr = '$day $month $year';
    if (withTime) {
      final hour = this.hour.toString().padLeft(2, '0');
      final minute = this.minute.toString().padLeft(2, '0');
      return '$dateStr $hour:$minute';
    }
    return dateStr;
  }

  String formatRelative() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 7) {
      return formatTurkish();
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }
}

extension IterableExtensions<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}

extension MapExtensions<K, V> on Map<K, V> {
  V? getOrDefault(K key, V defaultValue) => this[key] ?? defaultValue;
}

extension ColorExtensions on Color {
  Color withAlphaInt(int alpha) => withValues(alpha: alpha / 255);
  
  Color lighten(double amount) => Color.lerp(this, Colors.white, amount)!;
  
  Color darken(double amount) => Color.lerp(this, Colors.black, amount)!;
}

extension NumExtensions on num {
  double get toDoubleSafe => toDouble();
  int get toIntSafe => toInt();
  
  String formatCompact() {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toString();
  }
}

extension WidgetExtensions on Widget {
  Widget paddingAll(double value) => Padding(padding: EdgeInsets.all(value), child: this);
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) => 
      Padding(padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical), child: this);
  Widget paddingOnly({double left = 0, double top = 0, double right = 0, double bottom = 0}) => 
      Padding(padding: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom), child: this);
  Widget centered() => Center(child: this);
  Widget expanded({int flex = 1}) => Expanded(flex: flex, child: this);
  Widget flexible({int flex = 1, FlexFit fit = FlexFit.loose}) => Flexible(flex: flex, fit: fit, child: this);
  Widget withOpacity(double opacity) => Opacity(opacity: opacity, child: this);
  Widget visible(bool visible) => Visibility(visible: visible, child: this);
  Widget clipped(Rect clipRect, {Clip clipBehavior = Clip.hardEdge}) => ClipRect(clipper: _RectClipper(clipRect), clipBehavior: clipBehavior, child: this);
}

class _RectClipper extends CustomClipper<Rect> {
  final Rect rect;
  _RectClipper(this.rect);
  @override
  Rect getClip(Size size) => rect;
  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => oldClipper is _RectClipper && oldClipper.rect != rect;
}