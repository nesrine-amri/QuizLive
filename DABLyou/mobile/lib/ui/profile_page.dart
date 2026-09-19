import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api.dart';
import '../state/providers.dart';
import 'design_system.dart';
import 'points_history_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = Api(ref.watch(apiClientProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: api.me(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const AppEmptyView(
              icon: Icons.error_outline_rounded,
              title: 'صار مشكل في تحميل الحساب',
              subtitle: 'جرّب من جديد بعد شوية.',
            );
          }
          if (!snap.hasData) return const AppLoadingView(label: 'نحضّروا حسابك...');

          final me = snap.data!;
          final name = '${me['firstName'] ?? ''} ${me['lastName'] ?? ''}'.trim();
          final email = me['email']?.toString() ?? '';
          final pts = (me['totalPoints'] as int?) ?? 0;
          final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFEDE8FB)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isEmpty ? 'مستخدم' : name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(email, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PointsProgressCard(
                totalPoints: pts,
                title: 'نقاطك',
                subtitle: 'واصل على نفس النسق باش تربح بون التخفيض',
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PointsHistoryPage())),
                icon: const Icon(Icons.history_rounded),
                label: const Text('هيستوري النقاط'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (!context.mounted) return;
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('نخرج'),
              ),
            ],
          );
        },
      ),
    );
  }
}

