import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api.dart';
import '../state/providers.dart';
import 'session_page.dart';
import 'design_system.dart';

class MediaListPage extends ConsumerStatefulWidget {
  final String type; // TV or RADIO
  const MediaListPage({super.key, required this.type});

  @override
  ConsumerState<MediaListPage> createState() => _MediaListPageState();
}

class _MediaListPageState extends ConsumerState<MediaListPage> {
  late final Future<List<dynamic>> _future;
  final _search = TextEditingController();

  static const _tvOrder = [
    'wataniya1_tv',
    'wataniya2_tv',
    'elhiwar_tv',
    'nessma_tv',
    'attessia_tv',
  ];

  static const _radioOrder = [
    'mosaique_fm',
    'ifm',
    'express_fm',
    'diwan_fm',
    'shems_fm',
  ];

  @override
  void initState() {
    super.initState();
    _future = Api(ref.read(apiClientProvider)).media(type: widget.type);
  }

  // Fallback logo sources (Clearbit) for known media IDs
  static const Map<String, String> _logoFallback = {
    'wataniya1_tv': 'https://logo.clearbit.com/elwatania1.com',
    'wataniya2_tv': 'https://logo.clearbit.com/elwatania2.com',
    'elhiwar_tv': 'https://logo.clearbit.com/elhiwarettounsi.com',
    'nessma_tv': 'https://logo.clearbit.com/nessma.tv',
    'attessia_tv': 'https://logo.clearbit.com/attessia.tv',
    'mosaique_fm': 'https://logo.clearbit.com/mosaiquefm.net',
    'ifm': 'https://logo.clearbit.com/ifm.tn',
    'express_fm': 'https://logo.clearbit.com/radioexpressfm.com',
    'diwan_fm': 'https://logo.clearbit.com/diwanfm.net',
    'shems_fm': 'https://logo.clearbit.com/shemsfm.net',
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = Api(ref.watch(apiClientProvider));
    final title = widget.type == 'TV' ? 'اختار القناة' : 'اختار الراديو';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return AppEmptyView(
              icon: Icons.error_outline_rounded,
              title: 'صار مشكل في التحميل',
              subtitle: 'جرّب من جديد بعد شوية.',
            );
          }
          if (!snap.hasData) {
            return const AppLoadingView(label: 'نحضّروا في القايمة...');
          }
          final list = snap.data!;
          final query = _search.text.trim().toLowerCase();
          final byId = <String, Map<String, dynamic>>{
            for (final item in list) (Map<String, dynamic>.from(item as Map))['id'] as String: Map<String, dynamic>.from(item as Map),
          };
          final preferredIds = widget.type == 'TV' ? _tvOrder : _radioOrder;
          final filtered = preferredIds
              .map((id) => byId[id])
              .whereType<Map<String, dynamic>>()
              .where((m) {
                final name = (m['name'] as String?) ?? '';
                return query.isEmpty || name.toLowerCase().contains(query);
              })
              .toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF5F1FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFEDE8FB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                      widget.type == 'TV' ? 'اختار القناة اللي تتفرج فيها' : 'اختار الراديو اللي تسمع فيه',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'قلّب على قناة ولا راديو',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (filtered.isEmpty)
                const AppEmptyView(
                  icon: Icons.tv_off_rounded,
                  title: 'ما لقيناش نتائج',
                  subtitle: 'بدّل كلمة البحث ولا جرّب نوع آخر.',
                )
              else
                ...filtered.map((item) {
                  final m = Map<String, dynamic>.from(item as Map);
                  final id = (m['id'] as String?) ?? '';
                  final name = (m['name'] as String?) ?? '';
                  final pop = (m['popularity'] as int?) ?? 0;
                  final rawLogo = (m['logoUrl'] as String?) ?? '';
                  final logoUrl = rawLogo.isNotEmpty ? rawLogo : (_logoFallback[id] ?? '');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppMediaCard(
                      title: name,
                      subtitle: widget.type == 'TV' ? 'تفرّج و جاوب لايف' : 'اسمع و جاوب لايف',
                      badge: name.isEmpty ? '?' : String.fromCharCode(name.runes.first),
                        logoUrl: logoUrl,
                        assetName: id,
                      popularity: pop,
                      onTap: () async {
                        await api.selectMedia(id);
                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SessionPage(mediaId: id, mediaName: name, mediaType: widget.type),
                          ),
                        );
                      },
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

