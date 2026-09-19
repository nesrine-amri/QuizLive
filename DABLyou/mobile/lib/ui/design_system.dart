import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppColors {
  static const primary = Color(0xFF5B2EFF);
  static const primaryDark = Color(0xFF3F1BCB);
  static const secondary = Color(0xFFFFB800);
  static const accent = Color(0xFF3BC9A6);
  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFEF4444);
  static const background = Color(0xFFFAF6F0);
  static const surface = Colors.white;
  static const surfaceSoft = Color(0xFFF6EDE1);
  static const text = Color(0xFF16151C);
  static const textMuted = Color(0xFF6B7280);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.accent,
    surface: AppColors.surface,
    error: AppColors.error,
  );

  final textTheme = ThemeData.light().textTheme.apply(
        fontFamily: 'Tajawal',
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.text,
    ),
    iconTheme: const IconThemeData(color: AppColors.text),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: Colors.black12,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface.withValues(alpha: 0.92),
      indicatorColor: AppColors.primary.withValues(alpha: 0.14),
      labelTextStyle: WidgetStatePropertyAll(
        const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.text),
      ),
      iconTheme: const WidgetStatePropertyAll(IconThemeData(color: AppColors.textMuted)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.primary, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceSoft,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      labelStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE9E5F5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.text,
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: textTheme.copyWith(
      headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.text),
      headlineMedium: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.text),
      headlineSmall: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
      titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text),
      bodyLarge: const TextStyle(fontSize: 16, height: 1.45, color: AppColors.text),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textMuted),
      labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text),
    ),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class AppLoadingView extends StatelessWidget {
  final String label;
  const AppLoadingView({super.key, this.label = 'نحضّروا في الصفحة...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(strokeWidth: 3.2),
          ),
          const SizedBox(height: 14),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const AppEmptyView({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class PointsProgressCard extends StatelessWidget {
  final int totalPoints;
  final int goal;
  final String title;
  final String subtitle;
  const PointsProgressCard({
    super.key,
    required this.totalPoints,
    this.goal = 1000,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final rest = goal - (totalPoints % goal);
    final progress = (totalPoints % goal) / goal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xE65B2EFF),
            Color(0xCC3F1BCB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92))),
          const SizedBox(height: 8),
          Text('$totalPoints', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, fontSize: 40)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.84))),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
          const SizedBox(height: 10),
          Text('باقيلك $rest نقطة وتربح بون 15%', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class AppChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final bool selected;
  final VoidCallback onTap;
  const AppChoiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.02 : 1,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.24),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                ),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppMediaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final String? logoUrl;
  final String? assetName;
  final int popularity;
  final VoidCallback onTap;
  const AppMediaCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.logoUrl,
    this.assetName,
    required this.popularity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEDE8FB)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Builder(builder: (context) {
                  // Try local asset first if provided, then network logoUrl, then fallback to badge.
                  Widget fallback() => Center(
                        child: Text(
                          badge,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      );

                  if (assetName != null && assetName!.trim().isNotEmpty) {
                    final basePath = 'assets/logos/${assetName!.trim()}';
                    return Image.asset(
                      '$basePath.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => SvgPicture.asset(
                        '$basePath.svg',
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) {
                          if (logoUrl != null && logoUrl!.trim().isNotEmpty) {
                            return Image.network(
                              logoUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => fallback(),
                            );
                          }
                          return fallback();
                        },
                      ),
                    );
                  }

                  if (logoUrl == null || logoUrl!.trim().isEmpty) {
                    return fallback();
                  }

                  return Image.network(
                    logoUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => fallback(),
                  );
                }),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Chip(label: Text('لايف')),
                  const SizedBox(height: 6),
                  Text('$popularity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppRewardCard extends StatelessWidget {
  final String partnerName;
  final String title;
  final String pointsLabel;
  final String description;
  final VoidCallback? onPressed;
  final bool enabled;
  const AppRewardCard({
    super.key,
    required this.partnerName,
    required this.title,
    required this.pointsLabel,
    required this.description,
    required this.onPressed,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE8FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_offer_rounded, color: AppColors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partnerName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Chip(label: Text(pointsLabel)),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: enabled ? onPressed : null,
            child: Text(enabled ? 'بدّل النقاط' : 'ناقصك شوية نقاط'),
          ),
        ],
      ),
    );
  }
}

class AppCouponCard extends StatelessWidget {
  final String partnerName;
  final String code;
  final String status;
  final String expiresAt;
  final String rewardTitle;
  final VoidCallback? onCopy;
  const AppCouponCard({
    super.key,
    required this.partnerName,
    required this.code,
    required this.status,
    required this.expiresAt,
    required this.rewardTitle,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5DCF9)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.confirmation_num_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partnerName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(rewardTitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Chip(label: Text(status)),
            ],
          ),
          const SizedBox(height: 16),
          Text('الكود متاعك', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          SelectableText(
            code,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 12),
          Text('صالحة حتى $expiresAt', style: Theme.of(context).textTheme.bodyMedium),
          if (onCopy != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onCopy, child: const Text('انسخ الكود')),
          ],
        ],
      ),
    );
  }
}

class AppOptionCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool correct;
  final bool incorrect;
  final VoidCallback onTap;
  const AppOptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.correct,
    required this.incorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color border = const Color(0xFFE8E4F3);
    Color background = AppColors.surface;
    Color textColor = AppColors.text;
    if (correct) {
      border = AppColors.success;
      background = AppColors.success.withValues(alpha: 0.09);
      textColor = AppColors.success;
    } else if (incorrect) {
      border = AppColors.error;
      background = AppColors.error.withValues(alpha: 0.08);
      textColor = AppColors.error;
    } else if (selected) {
      border = AppColors.primary;
      background = AppColors.primary.withValues(alpha: 0.08);
      textColor = AppColors.primaryDark;
    }

    final initial = label.trim().isEmpty ? '?' : String.fromCharCode(label.runes.first);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: selected || correct || incorrect ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected || correct || incorrect ? textColor.withValues(alpha: 0.12) : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(initial, style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: textColor),
                  ),
                ),
                Icon(correct ? Icons.check_circle_rounded : incorrect ? Icons.cancel_rounded : Icons.chevron_left_rounded, color: textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppTimerRing extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  const AppTimerRing({super.key, required this.remainingSeconds, this.totalSeconds = 15});

  @override
  Widget build(BuildContext context) {
    final progress = (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: const Color(0xFFE9E5F5),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(toArabicNumerals('$remainingSeconds'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              Text('ث', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// Converts Western digits (0-9) to Arabic-Indic numerals (٠-٩)
String toArabicNumerals(String text) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  String result = text;
  for (int i = 0; i < 10; i++) {
    result = result.replaceAll('$i', arabicDigits[i]);
  }
  return result;
}

/// Converts month number to Arabic month name
String getArabicMonthName(int month) {
  const monthNames = [
    'جانفي',    // January
    'فيفري',    // February
    'مارس',     // March
    'أفريل',    // April
    'ماي',      // May
    'جوان',     // June
    'جويلية',   // July
    'أوت',      // August
    'سبتمبر',   // September
    'أكتوبر',   // October
    'نوفمبر',   // November
    'ديسمبر',   // December
  ];
  return (month >= 1 && month <= 12) ? monthNames[month - 1] : '';
}

/// Formats date as "١٥ جانفي ٢٠٠٥" (day in Arabic numerals, month in Arabic, year in Arabic numerals)
String formatDateInArabic(DateTime date) {
  final day = toArabicNumerals(date.day.toString().padLeft(2, '0'));
  final month = getArabicMonthName(date.month);
  final year = toArabicNumerals(date.year.toString());
  return '$day $month $year';
}

/// Formats date as "15 جانفي 2005" but with Latin digits for day and year
String formatDateWithLatinDigits(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = getArabicMonthName(date.month);
  final year = date.year.toString();
  return '$day $month $year';
}