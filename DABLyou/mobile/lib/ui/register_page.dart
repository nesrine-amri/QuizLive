import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api.dart';
import '../state/providers.dart';
import 'design_system.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

// Major Tunisian cities (Arabic) — used for advertiser geo-analytics
const _tunisianCities = [
  'تونس', 'صفاقس', 'سوسة', 'القيروان', 'بنزرت',
  'قابس', 'أريانة', 'نابل', 'منوبة', 'المهدية',
  'سيدي بوزيد', 'الكاف', 'زغوان', 'جندوبة', 'باجة',
  'سليانة', 'توزر', 'قبلي', 'تطاوين', 'مدنين', 'قفصة',
];

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'MALE';
  String? _city;          // optional — for advertiser analytics
  bool _loading = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        var selectedYear = initialDate.year;
        var selectedMonth = initialDate.month;
        var selectedDay = initialDate.day;

        int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final maxDay = daysInMonth(selectedYear, selectedMonth);
            if (selectedDay > maxDay) {
              selectedDay = maxDay;
            }

            final years = List<int>.generate(91, (index) => now.year - 10 - index);
            final days = List<int>.generate(maxDay, (index) => index + 1);

            return AlertDialog(
              title: const Text('اختار تاريخ الميلاد'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(builder: (context) {
                      final d = DateTime(selectedYear, selectedMonth, selectedDay);
                      final dayStr = d.day.toString().padLeft(2, '0');
                      final monthStr = getArabicMonthName(d.month);
                      final yearStr = d.year.toString();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(dayStr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                          Directionality(textDirection: TextDirection.rtl, child: Text(monthStr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                          const SizedBox(width: 8),
                          Text(yearStr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedDay,
                            decoration: const InputDecoration(labelText: 'اليوم'),
                            items: days
                                .map(
                                  (day) => DropdownMenuItem(
                                    value: day,
                                    child: Text(day.toString()),
                                  ),
                                )
                                .toList(),
                            selectedItemBuilder: (context) => days.map((day) => Text(day.toString())).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setStateDialog(() => selectedDay = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedMonth,
                            decoration: const InputDecoration(labelText: 'الشهر'),
                            items: List.generate(
                              12,
                              (index) {
                                final month = index + 1;
                                return DropdownMenuItem(
                                  value: month,
                                  child: Text(getArabicMonthName(month)),
                                );
                              },
                            ),
                            selectedItemBuilder: (context) => List.generate(12, (index) => Text(getArabicMonthName(index + 1))),
                            onChanged: (value) {
                              if (value == null) return;
                              setStateDialog(() {
                                selectedMonth = value;
                                final maxDayForMonth = daysInMonth(selectedYear, selectedMonth);
                                if (selectedDay > maxDayForMonth) selectedDay = maxDayForMonth;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedYear,
                            decoration: const InputDecoration(labelText: 'السنة'),
                            items: years
                                .map(
                                  (year) => DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  ),
                                )
                                .toList(),
                            selectedItemBuilder: (context) => years.map((year) => Text(year.toString())).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setStateDialog(() {
                                selectedYear = value;
                                final maxDayForYear = daysInMonth(selectedYear, selectedMonth);
                                if (selectedDay > maxDayForYear) selectedDay = maxDayForYear;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(DateTime(selectedYear, selectedMonth, selectedDay));
                  },
                  child: const Text('تأكيد'),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختار تاريخ الميلاد')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = Api(ref.read(apiClientProvider));
      final birthDate = _birthDate!.toIso8601String().split('T').first;
      final res = await api.register(
        firstName: _firstName.text,
        lastName: _lastName.text,
        email: _email.text,
        password: _password.text,
        gender: _gender,
        birthDate: birthDate,
        city: _city,
      );
      final token = (res['accessToken'] as String?) ?? '';
      await ref.read(authControllerProvider.notifier).setToken(token);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      String message = 'ما نجمناش نعملو حساب. جرّب مرة أخرى.';
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        final serverMsg =
            data is Map ? (data['message']?.toString() ?? data['error']?.toString() ?? '') : (data?.toString() ?? '');
        final dioMsg = (e.message ?? '').trim();
        final details = [
          if (status != null) 'HTTP $status',
          if (serverMsg.trim().isNotEmpty) serverMsg.trim(),
          if (status == null && serverMsg.trim().isEmpty && dioMsg.isNotEmpty) dioMsg,
        ].join(' - ');
        if (details.isNotEmpty) message = details;
      } else {
        final raw = e.toString().trim();
        if (raw.isNotEmpty) message = raw;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نعمل حساب')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF6F1FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFEDE8FB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.person_add_alt_rounded, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text('نفتحو حساب جديد', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('خمس دقايق وتولي جاهز باش تلعب وتربح.', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _firstName,
                    decoration: const InputDecoration(labelText: 'الإسم', prefixIcon: Icon(Icons.badge_outlined)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب الإسم' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastName,
                    decoration: const InputDecoration(labelText: 'اللقب', prefixIcon: Icon(Icons.badge_rounded)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب اللقب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'الإيميل', prefixIcon: Icon(Icons.mail_outline_rounded)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'اكتب إيميل صحيح' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'كلمة السر', prefixIcon: Icon(Icons.lock_outline_rounded)),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 8) ? 'على الأقل 8 حروف' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'الجنس', prefixIcon: Icon(Icons.wc_rounded)),
                    items: const [
                      DropdownMenuItem(value: 'MALE', child: Text('راجل')),
                      DropdownMenuItem(value: 'FEMALE', child: Text('مرأة')),
                      DropdownMenuItem(value: 'OTHER', child: Text('آخر')),
                    ],
                    onChanged: (v) => setState(() => _gender = v ?? 'MALE'),
                  ),
                  const SizedBox(height: 12),
                  // City — optional, used for advertiser geo-analytics
                  DropdownButtonFormField<String>(
                    value: _city,
                    decoration: const InputDecoration(
                      labelText: 'المدينة (اختياري)',
                      prefixIcon: Icon(Icons.location_city_rounded),
                      hintText: 'اختار مدينتك',
                    ),
                    items: _tunisianCities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _city = v),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickBirthDate,
                    icon: const Icon(Icons.cake_outlined),
                    label: Directionality(
                      textDirection: TextDirection.ltr,
                      child: _birthDate == null
                          ? const Text('اختار تاريخ الميلاد')
                          : Builder(builder: (context) {
                              final d = _birthDate!;
                              final dayStr = d.day.toString().padLeft(2, '0');
                              final monthStr = getArabicMonthName(d.month);
                              final yearStr = d.year.toString();
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(dayStr),
                                  const SizedBox(width: 6),
                                  Directionality(textDirection: TextDirection.rtl, child: Text(monthStr)),
                                  const SizedBox(width: 6),
                                  Text(yearStr),
                                ],
                              );
                            }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? '...' : 'نعمل حساب'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

