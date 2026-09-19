import 'package:flutter/material.dart';
import 'mode_page.dart';
import 'rewards_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [ModePage(), RewardsPage(), ProfilePage()];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _idx, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.play_circle_outline_rounded), label: 'نلعب'),
          NavigationDestination(icon: Icon(Icons.card_giftcard_outlined), label: 'العروض'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'حسابي'),
        ],
      ),
    );
  }
}

