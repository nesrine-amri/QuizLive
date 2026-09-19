import 'package:flutter/material.dart';
import 'media_list_page.dart';
import 'design_system.dart';

class ModePage extends StatelessWidget {
  const ModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('شنوة تحب تتابع؟', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('اختار تلفزة ولا راديو وابدأ الجيم لايف.', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 1,
              mainAxisSpacing: 14,
              childAspectRatio: 1.75,
              children: [
                AppChoiceCard(
                  title: 'تلفزة',
                  subtitle: 'تفرّج وجاوب على أسئلة لايف',
                  icon: Icons.tv_rounded,
                  gradient: const [Color(0xFF5B2EFF), Color(0xFF8E5BFF)],
                  selected: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MediaListPage(type: 'TV')),
                  ),
                ),
                AppChoiceCard(
                  title: 'راديو',
                  subtitle: 'اسمع الراديو واربح نقاط',
                  icon: Icons.radio_rounded,
                  gradient: const [Color(0xFF0EA5E9), Color(0xFF3BC9A6)],
                  selected: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MediaListPage(type: 'RADIO')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

