import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api.dart';
import '../state/providers.dart';
import 'design_system.dart';

class PointsHistoryPage extends ConsumerWidget {
  const PointsHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = Api(ref.watch(apiClientProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('هيستوري النقاط')),
      body: FutureBuilder<List<dynamic>>(
        future: api.pointsHistory(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const AppEmptyView(
              icon: Icons.error_outline_rounded,
              title: 'صار مشكل في تحميل الهيستوري',
              subtitle: 'جرّب من جديد بعد شوية.',
            );
          }
          if (!snap.hasData) return const AppLoadingView(label: 'نحضّروا الهيستوري...');

          final items = snap.data!;
          if (items.isEmpty) {
            return const AppEmptyView(
              icon: Icons.timeline_rounded,
              title: 'ما فماش هيستوري توا',
              subtitle: 'كي تبدأ تجاوب، يبانلك التاريخ هنا.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(title: 'النقاط متاعك عبر الوقت'),
              const SizedBox(height: 10),
              ...items.map((item) {
                final e = Map<String, dynamic>.from(item as Map);
                final delta = (e['delta'] as int?) ?? 0;
                final reason = e['reason']?.toString() ?? '';
                final createdAt = e['createdAt']?.toString() ?? '';
                final positive = delta >= 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFEDE8FB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: positive ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            positive ? Icons.add_rounded : Icons.remove_rounded,
                            color: positive ? AppColors.success : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                positive ? '+$delta' : '$delta',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: positive ? AppColors.success : AppColors.error,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(reason, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(toArabicNumerals(createdAt.split('T').first), style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

