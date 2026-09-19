import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api.dart';
import '../state/providers.dart';
import 'design_system.dart';

class RewardsPage extends ConsumerWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = Api(ref.watch(apiClientProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('العروض والكوبونات')),
      body: FutureBuilder(
        future: Future.wait([api.me(), api.rewards(), api.myCoupons()]),
        builder: (context, snap) {
          if (snap.hasError) {
            return const AppEmptyView(
              icon: Icons.error_outline_rounded,
              title: 'صار مشكل في التحميل',
              subtitle: 'جرّب من جديد بعد شوية.',
            );
          }
          if (!snap.hasData) return const AppLoadingView(label: 'نحضّروا العروض...');

          final data = snap.data as List;
          final me = Map<String, dynamic>.from(data[0] as Map);
          final rewards = (data[1] as List).cast<dynamic>();
          final coupons = (data[2] as List).cast<dynamic>();
          final total = (me['totalPoints'] as int?) ?? 0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PointsProgressCard(
                totalPoints: total,
                title: 'رصيدك الحالي',
                subtitle: 'لمّ النقاط وبدّلهم بكوبونات تونسية',
              ),
              const SizedBox(height: 18),
              const SectionHeader(title: 'العروض متاعك'),
              const SizedBox(height: 10),
              ...rewards.map((r0) {
                final reward = Map<String, dynamic>.from(r0 as Map);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RewardTile(
                    reward: reward,
                    canRedeem: total >= 1000,
                    onRedeem: () async {
                      final rewardId = reward['id']?.toString() ?? '';
                      try {
                        await api.redeem(rewardId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ربحت بون تخفيض بـ 15%')));
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ما تنجمش تبدّل توا.')));
                      }
                    },
                  ),
                );
              }),
              const SizedBox(height: 8),
              const SectionHeader(title: 'الكوبونات متاعك'),
              const SizedBox(height: 10),
              if (coupons.isEmpty)
                const AppEmptyView(
                  icon: Icons.confirmation_num_outlined,
                  title: 'ما عندك حتى كوبون توا',
                  subtitle: 'جاوب أكثر وبدّل النقاط باش يطلعولك العروض.',
                )
              else
                ...coupons.map((c0) {
                  final coupon = Map<String, dynamic>.from(c0 as Map);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CouponTile(coupon: coupon),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  final Map<String, dynamic> reward;
  final bool canRedeem;
  final VoidCallback onRedeem;

  const _RewardTile({required this.reward, required this.canRedeem, required this.onRedeem});

  @override
  Widget build(BuildContext context) {
    final partner = Map<String, dynamic>.from(reward['partner'] as Map);
    final title = (reward['title'] as String?) ?? '';
    final points = (reward['requiredPoints'] as int?) ?? 1000;
    return AppRewardCard(
      partnerName: partner['name']?.toString() ?? '',
      title: title,
      pointsLabel: '$points نقطة',
      description: 'بون تخفيض 15% من ${partner['name']?.toString() ?? ''}.',
      onPressed: onRedeem,
      enabled: canRedeem,
    );
  }
}

class _CouponTile extends StatelessWidget {
  final Map<String, dynamic> coupon;

  const _CouponTile({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final reward = Map<String, dynamic>.from(coupon['reward'] as Map);
    final partner = Map<String, dynamic>.from(reward['partner'] as Map);
    final code = coupon['code']?.toString() ?? '';
    final status = coupon['status']?.toString() ?? '';
    final expiresAt = coupon['expiresAt']?.toString() ?? '';
    return AppCouponCard(
      partnerName: partner['name']?.toString() ?? '',
      code: code,
      status: status,
      expiresAt: expiresAt.split('T').first,
      rewardTitle: reward['title']?.toString() ?? '',
      onCopy: code.isEmpty
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تنسخ الكود بنجاح')));
              }
            },
    );
  }
}

